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
$max_steps   = 25
#  - Maximale Schrittlänge
$delta       = 0.5
$delta2      = 2*$delta
#  - Anzahl von Schritten während MC
## Parameter
#  - Maximale Anzahl an Partikeln
## System
#  - Boxlänge
#    - Halbe Boxlänge
$box         = 42.24884
$hbox        = 0.5*$box
#  - Temperatur
#    - beta
$temperatur  = 80.0
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
def lj distance2
	# Überprüfe ob überhaupt gerechnet wird
	if distance2 < $cut_off_radius2 then
		sigdis2 = $sigma2/distance2
		sigdis6 = sigdis2*sigdis2*sigdis2
		#     E = 4ε·((σ/r)¹²–(σ/r)⁶)
		energy  = $epsilon4*(sigdis6*sigdis6-sigdis6)
	else
		energy  = 0.0
	end
	return energy
end
#-------------------------------------------------------------------#
class Float 
	def adjust
		# Warum ist adjust nötig?
		#  |-box = 5-|
		# -|-+-+-+-+-|-+-+-+-+-|-+-+-+-+-|-
		#  | o     * | o     * | o     * | 
		# -|-+-+-+-+-|-+-+-+-+-|-+-+-+-+-|-
		#    |--3--|-2-| mit 3 + 2 = box
		# da 3 > box/2  => box - 3 = 2
		self > $hbox ? $box - self : self
	end
end
#-------------------------------------------------------------------#
def calculate configuration
	# Berechnung der Systemenergie
	energy = 0.0
	# Alle Koordinaten sind in nur einem Array gespeichert
	# Der Array wird dupliziert
	temp  = configuration.dup
	# Die Koordinaten werden vom Array genommen,
	# um Doppeltzählung und Kreuzterme zu vermeiden
	until temp.empty?
		# .pop nimmt Koordinaten von oben, also z,y,x
		z,y,x = temp.pop,temp.pop,temp.pop
		# Und die Energie zu den restlichen Teilchen ausgerechenet
		dx,dy,dz=0,0,0
		# Laufvariable zur Unterscheidung der Koordinaten
		temp_runs=0
		# .each nimmt Koordinaten von unten, also x,y,z
		temp.each do |coordinate|
			# Erhöhen er Laufvariabel da Koordinaten in einem Array
			temp_runs += 1
			# und Fallunterscheidung
			# TODO: macht es das Programm schneller oder langsamer?
			if temp_runs%3==1
				dx = (x - coordinate).abs.adjust
			elsif temp_runs%3==2
			    dy = (y - coordinate).abs.adjust
			else        
				dz = (z - coordinate).abs.adjust
				# direkte Berechnung des Abstandsquadrats
				distance2 = (dx*dx + dy*dy + dz*dz)
				# Hinzufügen der Energie zur Systemenergie
				energy += lj distance2
			end
		end
	end
	return energy
end
#-------------------------------------------------------------------#
=begin
def mcstep configuration
	configuration[rand(configuration.length)] += $delta*2*((rand)-0.5)
	return configuration
end
=end
# der Monte Carlo wie zuvor verändert die Koordinaten
class Array
	# deshalb jetzt als Methode in Array
	def mcstep!
		# Achtung! Die Anzahl der Koordinaten wird beim Start
		# festgelegt, spart den Aufruf von .length bei jedem mcstep
		temp = rand $coordinates
		self[temp] += $delta2*((rand)-0.5)
		case
			when self[temp] >= $box then self[temp] -= $box
			when self[temp] <  0    then self[temp] += $box
			else
		end
		return self
	end
end
#-------------------------------------------------------------------#
#! Berechnen der Gesamtenergie des Systems
#! Beginn der MCs
#  ! Einstellen ob vor oder im GGW
#  ! Kann nach der Rechnung durchgeführt werden
#  Durchführen der Wiederholungen
results = Array.new
runs = 0
total_energy=0
energy_old = calculate old
while runs < $max_runs
	runs += 1
	# Durchführen der Schritte, TODO: ist .dup nötig?
	new,steps = old.dup,0
	# Verschieben eines Partikels 
	steps += 1 and new.mcstep! while steps < $max_steps
	energy_new = calculate new
	# Bestimmen ob die neue Konfiguration angenommen wird
	old,energy_old = new,energy_new if Math::exp(-$beta*(energy_new-energy_old)) > rand
	# Hinzufügen der neuen bzw. alten Konfiguration zu den Ergebnissen
	# die Rechnung erfolgt dann nach belieben später
	results << old
	# Berechnen der Gesamtenergie
	total_energy += energy_old/$max_runs
end
#-------------------------------------------------------------------#
#! Ausgabe einer „Trajektorie“
trj = File.open(name + '.trj','w+')
count = 0
temp = results.dup
p temp.length
temp.each do |c| p c[0] if c.empty? end
for j in 0...(temp.length) do
	#p configuration if configuration.empty?
	c = temp[j].dup
	count += 1 unless c.empty?
	p c if c.empty?
	#p "!" if configuration.empty?
	trj << $particle.to_s + "\n"
	trj << "Coordinates from montecarlo-lj.rb\n"
	until  c.empty?
		trj << "Ar%10.5f%10.5f%10.5f\n" % c.shift(3) 
	end
	#print configuration, "!\n"
end
p count
trj.close
#-------------------------------------------------------------------#
#! Ausgabe der Endkonfiguration (zerstört Endkonfiguration)
#  ist das überhaupt interessant? → Startkonfiguration für neuen MC
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
