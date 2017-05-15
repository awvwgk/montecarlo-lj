#-------------------------------------------------------------------#
=begin
def mcstep configuration
	configuration[rand(configuration.length)] += $delta*2*((rand)-0.5)
	return configuration
end
=end
# der Monte Carlo wie zuvor verändert die Koordinaten
# TODO Scalieren für NPT-Ensemble mit .map!
class Array
	# deshalb jetzt als Methode in Array
	def mcstep!
		# Achtung! Die Anzahl der Koordinaten wird beim Start
		# festgelegt, spart den Aufruf von .length bei jedem mcstep
		temp = rand $parameter[:coordinates]
		self[temp] += $parameter[:delta2]*((rand)-0.5)
		case
			when self[temp] >= $parameter[:box] then self[temp] -= $parameter[:box]
			when self[temp] <  0    then self[temp] += $parameter[:box]
			else
		end
		return self
	end
end
#-------------------------------------------------------------------#
