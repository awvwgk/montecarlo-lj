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
