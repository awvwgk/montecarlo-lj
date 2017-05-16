class Parameter < Hash
	def initialize name
		input = File.readlines name + '.inp'
		input.reject! { |line| line.match /^\#.*/ }.each do |line|
			line.match /\s*\=\s*/
			self[$`.downcase.intern] = $'.chomp.to_f
		end
	end
	def read_config name
		config = []
		input = File.readlines name + '.xyz'
		self[:particle] = input[0].chomp.to_i
		input.slice(2...(input.length)).each do |line|
			config << line.split(%r{\s+}).slice(1..3)
		end
		return config.flatten.map { |coordinate| coordinate.to_f }
		#config.transpose ###splits coordinates in x, y, z
	end
	def complete
		self[:delta2]          = 2*self[:delta]
		self[:hbox]            = 0.5*self[:box]
		self[:beta]            = 1.0/self[:temperatur]
		self[:epsilon4]        = 4.0*self[:epsilon]
		self[:sigma2]          = self[:sigma]*self[:sigma]
		self[:cut_off_radius]  = self[:hbox]
		self[:cut_off_radius2] = self[:cut_off_radius]*self[:cut_off_radius]
		self[:coordinates]     = 3*self[:particle]
	end
end
