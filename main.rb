#!/bin/ruby
#-------------------------------------------------------------------#
require 'opt-parser'
options = Hash.new
OptionParser.new do |option|
	option.banner = 'Benutzung: ruby main.rb input-file'
	option.on_tail '-h','--help','Zeige diese  Nachricht' do
		puts option
		exit
	end
end.parse!
#-------------------------------------------------------------------#
#data = Array.new
#File.readlines(ARGV[0]).each { |line| data << line.chomp }
#TODO
#-------------------------------------------------------------------#
#! Einlesen der wichtigen Daten
#  - MCs für Einstellung des Gleichgewichts
#  - MCs im equilibrierten System
$max_runs    = 1000
#  - Anzahl von MCs zwischen der Datenaufnahme
$max_steps   = 10
#  - Maximale Schrittlänge
$delta       = 0.01
$delta2      = 2*$delta
#  - Anzahl von Schritten während MC
## Parameter
#  - Maximale Anzahl an Partikeln
$particle    = 10
$coordinates = 3*$particle
## System
#  - Boxlänge
#    - Halbe Boxlänge
$box         = 
$hbox        = 0.5*$box
#  - Temperatur
#    - beta
$temperatur  =
$beta        = 1.0/$temperatur
## Potential (hier LJ)
#  - epsilon
$epsilon     = 111.7#K für Argon
$epsilon4    = 4*$epsilon
#  - sigma
$sigma       = 3.487#Å für Argon
$sigma2      = $sigma**2
#  - cut-off radius
$cut_off_radius
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
	energy = 0
	# Die Koordinaten sind in einem Array gespeichert
	# Der Array wird dupliziert
	temp  = configuration.dub
	# Die Koordinaten werden vom Array genommen,
	# um Doppeltzählung und Kreuzterme zu vermeiden
	until temp.empty?
		# .pop nimmt Koordinaten von oben, also z,y,x
		z,y,x = temp.pop,temp.pop,temp.pop
		# Und die Energie zu den restlichen Teilchen ausgerechenet
		dx2,dy2,dz2=0,0,0
		# Laufvariable zur Unterscheidung der Koordinaten
		temp_runs=0
		# .each nimmt Koordinaten von unten, also x,y,z
		temp.each do |coordinate|
			# Erhöhen er Laufvariabel da Koordinaten in einem Array
			temp_runs += 1
			# und Fallunterscheidung
			# TODO: macht es das Programm schneller oder langsamer?
			case temp_runs%3
				when 1 then dx = (x - coordinate).abs.adjust
			    when 2 then dy = (y - coordinate).abs.adjust
				else
					dz = (z - coordinate).abs.adjust
					# direkte Berechnung des Abstandsquadrats
					distance2 = dx*dx + dy*dy + dz*dz
					# Hinzufügen der Energie zur Systemenergie
					energy += lj distance2
				end
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
energy_old = calculate old
while runs <= $max_runs
	runs += 1
	# Durchführen der Schritte, TODO: ist .dup nötig?
	new,steps = old.dup,0
	# Verschieben eines Partikels 
	steps += 1 and new.mcstep! while steps <= $max_steps
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
results.dup.each do |configuration|
	trj << configuration.length.to_s + "\n"
	trj << "Coordinates from montecarlo-lj.rb\n"
	until  configuration.empty?
		trj << "Ar%10.5f%10.5f%10.5f\n" % configuration.shift(3) 
	end
end
trj.close
#-------------------------------------------------------------------#
#! Ausgabe der Endkonfiguration (zerstört Endkonfiguration)
#  ist das überhaupt interessant?
xyz = File.open(name + '.xyz','w+')
xyz << old.length.to_s + "\n"
xyz << "Coordinates from montecarlo-lj.rb\n"
until  old.empty?
	xyz << "Ar%10.5f%10.5f%10.5f\n" % old.shift(3) 
end
xyz.close
#-------------------------------------------------------------------#
