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
