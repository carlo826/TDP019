#!/usr/bin/env ruby

##############################################################################
#
# This part defines the language classes
#
##############################################################################

# Global Variables
@@scope = 0
@@global_var = [{}]




class Blocks
	def initialize(blocks, block)
		@block = block
		@blocks = blocks
	end
	def eval()
		puts "Blocks eval"
		return_val = @block.eval
		if @block.class != Block
			@blocks.eval
		else
			return return_val
		end
		return_val = @block.eval
	end
end

class Block
	def initialize(expr)
		@expr = expr
	end

	def eval()
		return @expr.eval
	end
end

class DeclareVar
	def initialize(datatype, varName, expression=nil)
		p expression
		puts "class: #{expression.class}"
		@datatype = datatype
		@varName = varName
		@expression = expression
		puts "delccc"


	end
	def eval()
		p "välkommen till decl+"
		if @expression.class == String && @@global_var[@@scope].include?(@expression)
			p "striiing"
			expr = @@global_var[@@scope][@expression][1]
			p expr
			@@global_var[@@scope][@varName] = [@datatype, expr]
		end
		if (@datatype == 'string' && @expression.class != String_node)
			puts "Invalid String value"
			return
		end
		if (@datatype == 'float' && @expression.class != Float_node)
			puts "Invalid Floatat value"
			return
		end		
		if (@datatype == 'int' && @expression.class != Integer_node)
			puts "Invalid Integer value, value is #{@expression.class}"
			# puts "Invalid Integer value, value"
			return
		end
		if (@datatype == 'bool' && @expression.class != Bool_node)
			puts "Invalid bool value"
			return
		end		
		if (@datatype == 'char' && @expression.class != Char_node)
			puts "Invalid char value"
			return
		
		elsif (@datatype == 'char' && @expression.class == Char_node && @expression.length() > 1)
			puts "Invalid char length"
			return
		end

		if (@expression != nil)
			@@global_var[@@scope][@varName] = [@datatype, @expression.eval()]

		else
			p "skapar variabel"
			@@global_var[@@scope][@varName] = [@datatype, @expression]
		end
		# end
		# return @expression.eval()

		# else
		# 	if @expression.class == Bool_node

		# 		if (@expression.a != true || false)
		# 			a = @@global_var[@@scope][@expression.a][1]
		# 		end

		# 		if (@expression.b != true || false)
		# 			b = @@global_var[@@scope][@expression.b][1]
		# 		end
		# 		@@global_var[@@scope][@varName] = [@datatype, eval(a, @expression.operator, b)]


	end
end

class ReaVar
	def initialize(varName, expression)
		p "initieras reavar"
		@varName = varName
		@expression = expression
	end

	def eval()
		p "reavar eval"
		for scope in @@global_var #.reverse()?
			if scope[@varName]
				scope[@varName][1] = @expression.eval()
				return scope[@varName][1]
			end
		end
    	puts "Variabel Error: No variable found with name #{@id}!"
    	return nil 
	end
end


class Aritm_node
	attr_accessor :a, :operator, :b

	def initialize(a, operator ,b)
		@a = a
		@operator = operator
		@b = b
	end

	def eval()
		instance_eval("#{@a.eval} #{@operator} #{@b.eval}")
	end
end 



class Float_node
	def initialize(value)
		@value = value
	end
	def eval()
		return @value
	end
end

class Integer_node
	def initialize(value)
		@value = value
	end
	def eval()
		return @value
	end
end

class String_node
	def initialize(value)

		@value = value.tr('"','')
	end
	def eval()
		return @value
	end
end

class Char_node
	def initialize(value)
		# if (value.length() > 1 )
		# 	p "FEL"
		# else
		@value = value.tr("'",'')
		# end
	
	end
	def eval()
		return @value
	end

	def length()
		return @value.length()
	end
end

# class Bool_node
# 	def initialize(a, operator, b)

# 		@value = value
# 	end
# 	def eval()
# 		return @value
# 	end
# end


class Bool_node
	attr_accessor :a, :operator, :b

	def initialize(a, operator ,b)
		@a = a
		@operator = operator
		@b = b
	end

	def eval()
		instance_eval("#{@a.eval} #{@operator} #{@b.eval}")	
	end
end 