#-------------------------------------------------------------------#
def calculate configuration
	# Berechnung der Systemenergie
	energy = 0.0
	# Alle Koordinaten sind in nur einem Array gespeichert
	# Der Array wird dupliziert
	temp  = configuration.dup
	# Die Koordinaten werden vom Array genommen,
	# um Doppeltzählung und Kreuzterme zu vermeiden
	until temp.empty?
		# .pop nimmt Koordinaten von oben, also z,y,x
		z,y,x = temp.pop,temp.pop,temp.pop
		# Und die Energie zu den restlichen Teilchen ausgerechenet
		dx,dy,dz=0,0,0
		# Laufvariable zur Unterscheidung der Koordinaten
		temp_runs=0
		# .each nimmt Koordinaten von unten, also x,y,z
		temp.each do |coordinate|
			# Erhöhen er Laufvariabel da Koordinaten in einem Array
			temp_runs += 1
			# und Fallunterscheidung
			# TODO: macht es das Programm schneller oder langsamer?
			if temp_runs%3==1
				dx = (x - coordinate).abs.adjust
			elsif temp_runs%3==2
			    dy = (y - coordinate).abs.adjust
			else        
				dz = (z - coordinate).abs.adjust
				# direkte Berechnung des Abstandsquadrats
				distance2 = (dx*dx + dy*dy + dz*dz)
				# Hinzufügen der Energie zur Systemenergie
				energy += lj distance2
			end
		end
	end
	return energy
end
#-------------------------------------------------------------------#
