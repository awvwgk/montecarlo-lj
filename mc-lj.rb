#-------------------------------------------------------------------#
def lj distance2
	# TODO Überprüfe ob überhaupt gerechnet wird
	# Tail correction und cut off radius nicht implementiert
	#if distance2 < $parameter[:cut_off_radius2] then
		sigdis2 = $parameter[:sigma2]/distance2
		sigdis6 = sigdis2*sigdis2*sigdis2
		#     E = 4ε·((σ/r)¹²–(σ/r)⁶)
		energy  = $parameter[:epsilon4]*(sigdis6*sigdis6-sigdis6)
	#else
	#	energy  = 0.0
	#end
	return energy
end
#-------------------------------------------------------------------#
