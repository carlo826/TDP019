#!/usr/bin/env ruby
require './TTTClasses.rb'
require './TTTBasic.rb'
require './parser.rb'
#Made in ruby version 1.8.7
class TTT 
	#exit funktion
   	def done(str)
    	["/QUIT","/EXIT",""].include?(str.chomp)
  	end
  	def sats(str)
  		return_value = false
  		if (str != "\n" and str != nil)
  			if str =~ /^FOR|^WHILE|^IF|^EACH|^FUNCTION/
  				return_value = true
  			end
  		end
  		return return_value
  	end
  	def endsats(str)
  		return_value = false
  		if (str != "\n" and str != nil)
  			if str =~ /\/FOR|\/WHILE|\/IF|\/EACH|\/FUNCTION/
  				return_value = true
  			end
  		end
  		return return_value
  	end

	def loadfile(str)
		return_value = false
		if (str != "\n" and str != nil)
		  	litterals = str.split()
		  	for litteral in litterals do
		  		if ["INCLUDE"].include?(litteral.strip.chomp)
		  			return_value = true
				end
			end
		end
		return return_value
	end
  	#huvud loopen
  	def program
    	print ">> "
    	str = gets
    	satsstring = ""
   		if done(str)
     		puts "Terminating progress"
		elsif loadfile(str)
			str = str.gsub(/INCLUDE/,"").strip.chomp
			out = ""
			if File.exist? str
				File.open(str, 'r') do |f|
			  	str = f.readlines	
			  	out = str.join
				end
				"#{@TTTParser.parse out}"
			else
				puts ">> no file found"
			end
			program
   		elsif sats(str)
   			endcount = 0
   			run = true
   			while (run == true)
   				literals = str.split
   				for literal in 0..literals.length do
					if sats(litterals[litteral])
						endcount +=1
					end
   					if endsats(literals[literal])
   						endcount -=1
   					end
   				end
   				satsstring += str
   				if (endcount == 0)
   					run = false
   					break
   				end
				if endcount > 0
					print ".. "
   				else
					print ">> "
				end
   				str = gets
   			end
   			puts "#{@TTTParser.parse satsstring}"
   			program
   		else
   			puts "#{@TTTParser.parse str}"     
     		program
  		end
	end
end	
TTT.new.program