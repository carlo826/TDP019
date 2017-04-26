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
		@datatype = datatype
		@varName = varName
		@expression = expression

	end
	def eval()
		p "välkommen till decl+"
		if (@expression != nil)
			@@global_var[@@scope][@varName] = [@datatype, @expression.eval()]
		else
			@@global_var[@@scope][@varName] = [@datatype, @expression]
		end
		# return @expression.eval()

	end
end

class ReaVar
	def initialize(varName, expression)
		p "initieras reavar"
		@varName = varName
		@expression = expression
	end

	def eval()
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

		@value = value.tr("'",'')
	end
	def eval()
		return @value
	end
end


class Comparison
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