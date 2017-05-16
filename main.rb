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
require_relative 'mc-readdata'
require_relative 'mc-adjust'
require_relative 'mc-calculate'
require_relative 'mc-lj'
require_relative 'mc-step'
require_relative 'mc-output'
#-------------------------------------------------------------------#
name = ARGV[0].to_s.chomp '.inp'
$parameter = Parameter.new name
old = Hash.new
old[:x],old[:y],old[:z] = $parameter.read_config name
$parameter.complete
#-------------------------------------------------------------------#
# TODO Einstellen ob vor oder im GGW
$trj,$dat = File.open(name + '.trj','w+'),File.open(name + '.dat','w+')
$results,$energy_results = Array.new,Array.new
$runs = 0
energy_old = calculate old
$trj.write_config old, energy_old
$dat.save energy_old
#-------------------------------------------------------------------#
# Start of the real Monte Carlo
while $runs < $parameter[:max_runs]
	acc = false
	$runs += 1
	# Durchführen der Schritte, TODO: ist .dup nötig?
	new,steps = old.dup,0
	# Verschieben eines Partikels 
	steps += 1 and new.mcstep! while steps < $parameter[:max_steps]
	energy_new = calculate new
	# Bestimmen ob die neue Konfiguration angenommen wird
	diff = Math::exp(-$parameter[:beta]*(energy_new-energy_old))
	old,energy_old,acc = new,energy_new,true if diff > rand
	verbose energy_old, diff, acc
	# Hinzufügen der neuen bzw. alten Konfiguration zu den Ergebnissen
	# die Rechnung erfolgt dann nach belieben später
	sample old, energy_old
	$trj.write_config old, energy_old
	$dat.save energy_old
	# Berechnen der Gesamtenergie
end
puts "\n"
#-------------------------------------------------------------------#
$trj.close
$dat.close
#-------------------------------------------------------------------#
xyz = File.open(name + '.final' + '.xyz','w+')
xyz.write_config old, energy_old
xyz.close
#-------------------------------------------------------------------#
total_energy = 0
$energy_results.each do |energy|
	total_energy += energy/$parameter[:max_runs]
end
puts total_energy
#-------------------------------------------------------------------#
