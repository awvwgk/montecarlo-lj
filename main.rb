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
name = ARGV[0].to_s.chomp '.inp'
input = File.readlines(name + '.inp')
# get rid of the comments
input.reject! { |line| line.match /^\#.*/ }
# get rid of the newlines
input.map!    { |line| line.chomp }
# initialize a hash for all parameters
$parameter = Hash.new
# get the parameters
input.each do |line|
	line.match /\s*\=\s*/
	# and store them in the hash
	$parameter[$`.intern] = $'.to_f
end
p $parameter
# now get the name of the files
$parameter[:delta2]      = 2*$parameter[:delta]
$parameter[:hbox]        = 0.5*$parameter[:box]
$parameter[:beta]        = 1.0/$parameter[:temperatur]
$parameter[:epsilon4]    = 4.0*$parameter[:epsilon]
$parameter[:sigma2]      = $parameter[:sigma]*$parameter[:sigma]
$parameter[:cut_off_radius] = $parameter[:hbox]
$parameter[:cut_off_radius2] = $parameter[:cut_off_radius]*$parameter[:cut_off_radius]
#-------------------------------------------------------------------#
input,old = File.readlines(name + '.xyz'),Array.new
$parameter[:particle]    = input[0].to_i
$parameter[:coordinates] = 3*$parameter[:particle]
input.slice(2..(input.length-1)).each do |line|
	old << line.split(%r{\s+}).slice(1..3)
end
old.flatten!.map! { |coordinate| coordinate.to_f }
#-------------------------------------------------------------------#
def sample configuration, energy
	$results << configuration
	$energy_results << energy
end
#-------------------------------------------------------------------#
def save configuration, energy
	$dat << "%5i\t%.10f\n" % [$runs,energy]
	configuration = configuration.dup
	$trj << $parameter[:particle].to_s + "\n"
	$trj << "Coordinates from montecarlo-lj.rb E %.10f\n" % energy
	until  configuration.empty?
		$trj << "Ar%10.5f%10.5f%10.5f\n" % configuration.shift(3) 
	end
end
#-------------------------------------------------------------------#
def verbose energy, p, acc
	printf "\naktuelle Energie = %5.5f | ", energy
	printf acc ? "angenommen " : "abgelehnt  "
	printf "mit p = %2.2f%", p*100 if p < 1
end
#-------------------------------------------------------------------#
# TODO Einstellen ob vor oder im GGW
$trj,$dat = File.open(name + '.trj','w+'),File.open(name + '.dat','w+')
$results,$energy_results = Array.new,Array.new
$runs = 0
energy_old = calculate old
save old, energy_old
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
	save   old, energy_old
	# Berechnen der Gesamtenergie
end
puts "\n"
#-------------------------------------------------------------------#
#! Ausgabe einer „Trajektorie“
=begin
temp = results.dup
for j in 0...(temp.length) do
	c = temp[j].dup
	trj << $parameter[:particle].to_s + "\n"
	trj << "Coordinates from montecarlo-lj.rb E %.10f\n" % energy_results[j]
	until  c.empty?
		trj << "Ar%10.5f%10.5f%10.5f\n" % c.shift(3) 
	end
end
=end
$trj.close
#-------------------------------------------------------------------#
#! Ausgabe der Endkonfiguration (zerstört Endkonfiguration)
#  ist das überhaupt interessant? → Startkonfiguration für neuen MC
total_energy = 0
$energy_results.each do |energy|
	total_energy += energy/$parameter[:max_runs]
end
$dat.close
puts total_energy
#-------------------------------------------------------------------#
xyz = File.open(name + '.final' + '.xyz','w+')
xyz << $parameter[:particle].to_s + "\n"
xyz << "Coordinates from montecarlo-lj.rb E %.10f\n" % $energy_results.last
until  old.empty?
	xyz << "Ar%10.5f%10.5f%10.5f\n" % old.shift(3) 
end
xyz.close
#-------------------------------------------------------------------#
