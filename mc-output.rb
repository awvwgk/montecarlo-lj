#-------------------------------------------------------------------#
def sample configuration, energy
	$results << configuration
	$energy_results << energy
end
#-------------------------------------------------------------------#
class File
	def write_config config, energy
		self << $parameter[:particle].to_s + "\n"
		temp = [config[:x],config[:y],config[:z]].transpose
		self << "Coordinates from montecarlo-lj.rb E %.10f\n" % energy
		for i in 0...$parameter[:particle] do
		self << "Ar%10.5f%10.5f%10.5f\n" % temp[i]
		end
	end
	def save energy
		self << "%5i\t%.10f\n" % [$runs,energy]
	end
end
#-------------------------------------------------------------------#
def verbose energy, p, acc
	printf "\naktuelle Energie = %5.5f | ", energy
	printf acc ? "angenommen " : "abgelehnt  "
	printf "mit p = %2.2f%", p*100 if p < 1
end
#-------------------------------------------------------------------#
