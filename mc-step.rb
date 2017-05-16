#-------------------------------------------------------------------#
class Array
	def adjust! index
		case
			when self[index] >= $parameter[:box] then self[index] -= $parameter[:box]
			when self[index] < 0 then self[index] += $parameter[:box]
		end
		return self
	end
end
#-------------------------------------------------------------------#
class Hash
	def mcstep!
		temp = rand $parameter[:particle]
		self.each do |axis, coordinates|
			self[axis][temp] += $parameter[:delta2]*((rand)-0.5)
			self[axis].adjust! temp
		end
		return self
	end
end
#-------------------------------------------------------------------#
