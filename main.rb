#!/bin/ruby
#-------------------------------------------------------------------#
require 'optparse'
options = Hash.new
OptionParser.new do |option|
	option.banner = 'Benutzung: ruby main.rb input-file'
	option.on_tail '-h','--help','Zeige diese  Nachricht' do
		puts option
		exit
	end
end.parse!
#-------------------------------------------------------------------#
#require_relative 'mc-readdata'
require_relative 'mc-adjust'
require_relative 'mc-calculate'
require_relative 'mc-lj'
require_relative 'mc-step'
#-------------------------------------------------------------------#
name = ARGV[0].chomp
#-------------------------------------------------------------------#
input,data,old = File.readlines(name+'.xyz'),Array.new,Array.new
$particle      = input[0].to_i
$coordinates   = 3*$particle
input.slice(2..(input.length-1)).each do |line|
	data << line.split(%r{\s+}).slice(1..3)
end
data.flatten.each { |coordinate| old << coordinate.to_f }
#-------------------------------------------------------------------#
#! Einlesen der wichtigen Daten
#  - MCs für Einstellung des Gleichgewichts
#  - MCs im equilibrierten System
$max_runs    = 1000
#  - Anzahl von MCs zwischen der Datenaufnahme
$max_steps   = 20
#  - Maximale Schrittlänge
$delta       = 1
$delta2      = 2*$delta
#  - Anzahl von Schritten während MC
## Parameter
#  - Maximale Anzahl an Partikeln
## System
#  - Boxlänge
#    - Halbe Boxlänge
$box         = 84.49767
$hbox        = 0.5*$box
#  - Temperatur
#    - beta
$temperatur  = 90.0
$beta        = 1.0/$temperatur
## Potential (hier LJ)
#  - epsilon
$epsilon     = 111.7#K für Argon
$epsilon4    = 4.0*$epsilon
#  - sigma
$sigma       = 3.487#Å für Argon
$sigma2      = $sigma*$sigma
#  - cut-off radius
$cut_off_radius = $hbox
$cut_off_radius2 = $cut_off_radius*$cut_off_radius
#-------------------------------------------------------------------#
## Konfiguration
#  - Anzahl der Partikel
#  - Position der Partikel
#-------------------------------------------------------------------#
#! Berechnen der Gesamtenergie des Systems
#! Beginn der MCs
#  ! Einstellen ob vor oder im GGW
#  ! Kann nach der Rechnung durchgeführt werden
#  Durchführen der Wiederholungen
results = Array.new
runs = 0
energy_results = Array.new
energy_old = calculate old
while runs < $max_runs
	acc = false
	runs += 1
	# Durchführen der Schritte, TODO: ist .dup nötig?
	new,steps = old.dup,0
	# Verschieben eines Partikels 
	steps += 1 and new.mcstep! while steps < $max_steps
	energy_new = calculate new
	# Bestimmen ob die neue Konfiguration angenommen wird
	diff = Math::exp(-$beta*(energy_new-energy_old))
	old,energy_old,acc = new,energy_new,true if diff > rand
	printf "\naktuelle Energie = %5.5f | ", energy_old
	printf acc ? "angenommen " : "abgelehnt  "
	printf "mit p = %2.2f%", diff*100 if diff < 1
	# Hinzufügen der neuen bzw. alten Konfiguration zu den Ergebnissen
	# die Rechnung erfolgt dann nach belieben später
	results << old
	# Berechnen der Gesamtenergie
	energy_results << energy_old #/$max_runs 
end
puts "\n"
#-------------------------------------------------------------------#
#! Ausgabe einer „Trajektorie“
trj = File.open(name + '.trj','w+')
temp = results.dup
for j in 0...(temp.length) do
	c = temp[j].dup
	trj << $particle.to_s + "\n"
	trj << "Coordinates from montecarlo-lj.rb\n"
	until  c.empty?
		trj << "Ar%10.5f%10.5f%10.5f\n" % c.shift(3) 
	end
	#print configuration, "!\n"
end
trj.close
#-------------------------------------------------------------------#
#! Ausgabe der Endkonfiguration (zerstört Endkonfiguration)
#  ist das überhaupt interessant? → Startkonfiguration für neuen MC
total_energy = 0
energy_results.each do |energy|
	total_energy += energy/$max_runs
end
puts total_energy
=begin
xyz = File.open(name + '.xyz','w+')
xyz << old.length.to_s + "\n"
xyz << "Coordinates from montecarlo-lj.rb\n"
until  old.empty?
	xyz << "Ar%10.5f%10.5f%10.5f\n" % old.shift(3) 
end
xyz.close
=end
#-------------------------------------------------------------------#
