class Array
	def displacement i, j
		(self[i] - self[j]).abs.adjust
	end
end
#-------------------------------------------------------------------#
def calculate config
	# Berechnung der Systemenergie
	energy = 0.0
	for i in 0...$parameter[:particle] do
		for j in (i+1)...$parameter[:particle] do
			dx = config[:x].displacement i, j
			dy = config[:y].displacement i, j
			dz = config[:z].displacement i, j
			distance2 = (dx*dx + dy*dy + dz*dz)
			energy += lj distance2
		end
	end
	return energy
end
#-------------------------------------------------------------------#
