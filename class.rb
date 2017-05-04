#!/usr/bin/env ruby

##############################################################################
#
# This part defines the language classes
#
##############################################################################

# Global Variables
@@scope = 0
@@global_var = [{}]
@@debug = true;

def incr_scope
	@@global_var << {} #index symbolizes scope
	@@scope += 1
	puts "Incrementing scope with 1 \n Scope count: #{@@scope}" if @@debug
end

def decr_scope
	@@global_var.pop
	@@scope -= 1
	puts "Decrementing scope with -1 \n Scope count: #{@@scope}"
	if @@scope < 0
		raise("You cannot close base scope!")
	end
end




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

        if @expression.class == Find_Variable
            @@global_var[@@scope][@varName.get_name()] = [@datatype, @@global_var[@@scope][@expression.get_name()][1]]

        elsif @expression == nil
            @@global_var[@@scope][@varName.get_name()] = [@datatype, nil]

        else
            @@global_var[@@scope][@varName.get_name()] = [@datatype, @expression.eval()]
        end
  
	end
end

class ReaVar
	def initialize(varName, expression)
		@varName = varName
		@expression = expression
	end

    def eval()
        for scope in @@global_var #.reverse()?
            if scope[@varName.get_name()]
                if @expression.class == Find_Variable
                    scope[@varName.get_name()][1] = scope[@expression.get_name()][1]
                    return nil
                else
                    scope[@varName.get_name()][1] = @expression.eval()
                    return nil
                end 
            end
        end
        puts "Variabel Error: No variable found with name #{@varName}!"
        return nil 
    end
end


class Find_Variable
    def initialize(varName)
        @varName = varName
    end

    def get_name
        for scope in @@global_var 
            if scope[@varName]
                return @varName #.eval()
                # return scope[@varName][1] #.eval()
            end
        end
        puts "NameError: undefined local variable or method #{@varName} for main:Object"
        return @varName

    end


    def eval
        p @@global_var
        for scope in @@global_var 
            if scope[@varName]
                # return @varName #.eval()
                return scope[@varName][1] #.eval()
            end
        end
        puts "NameError: undefined local variable or method #{@varName} for main:Object"
        return @varName
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
        puts "integgerrr"
        @value = value
    end
    def eval()
        return @value
    end
end

class String_node
    def initialize(value)
        puts "striiiing_node"
        @value = value.tr('"','')
    end
    def eval()
        return @value
    end
end

class Char_node
    def initialize(value)
        # if (value.length() > 1 )
        #   p "FEL"
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

class Bool_node
  def initialize(value)
      @value = value
  end
  def eval()
      return @value
  end
end


class Comparison_node
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


class Print_expr
	def initialize(expr)
		@expr = expr
	end
	def eval
		printer = @expr.eval
		puts printer
		return printer
	end
end


class If_condition_node
	def initialize(condition, blocks)
		@condition = condition
		@blocks = blocks
	end

	def eval
		incr_scope
		if @condition.eval
			return_val = @blocks.eval
			decr_scope
			return return_val
		end
		decr_scope
	end
end


# class If_else_condition_node
# def initialize(cond, stmts, else_stmts)
# @cond = cond
# @stmts = stmts
# @else_stmts = else_stmts
# end
# def eval
# open_scope
# if @cond.eval
# return_value = @stmts.eval
# else
# return_value = @else_stmts.eval
# end
# close_scope
# return return_value
# end
# end

















#       puts
  #       p @@global_var
  #       p @expression
  #       p @expression.class
  #       for varName in @@global_var #.reverse()?
  #           if varName[@expression]
  #               puts "hitta namnet"
  #           end
  #       end

  #       if (@expression == nil)
  #           puts "nilclassiisi"
  #           if @datatype == "string"
  #               @expression = String_node.new("nilClass")
  #           end
  #           # if @datatype == "bool"
  #           #     @expression = Bool_node.new("nilClass")
  #           # end
  #           if @datatype == "int"
  #               @expression = Integer_node.new("nilClass")
  #           end
  #           if @datatype == "float"
  #               @expression = Float_node.new("nilClass")
  #           end


  #           @@global_var[@@scope][@varName] = [@datatype, @expression]
  #           puts "Creating variabel with NilClass}"

        # elsif (@datatype == 'string' && @expression.class != String_node)
        #   puts "Invalid string value, value is #{@expression.class}"
        #   return
        
        # elsif (@datatype == 'float' && @expression.class != Float_node)
        #   puts "Invalid float value, value is #{@expression.class}"
        #   return
                
        # elsif (@datatype == 'int' && @expression.class != Integer_node)
        #   puts "Invalid Integer value, value is #{@expression.class}"
  #           p @varName.eval()
        #   # puts "Invalid Integer value, value"
        #   return
        
        # elsif (@datatype == 'bool' && @expression.class != Bool_node)
        #   puts "Invalid bool value, value is #{@expression.class}"
        #   return
                
        # elsif (@datatype == 'char' && @expression.class != Char_node)
        #   puts "Invalid char value, value is #{@expression.class}"
        #   return
        
        # elsif (@datatype == 'char' && @expression.class == Char_node && @expression.length() > 1)
        #   puts "Invalid char length"
        #   return
        # else
  #           puts "Creating variabel #{@expression.eval()}"
  #           p @varName.eval()
        #   @@global_var[@@scope][@varName] = [@datatype, @expression.eval()]
        # end
        # end
        # return @expression.eval()

        # else
        #   if @expression.class == Bool_node

        #       if (@expression.a != true || false)
        #           a = @@global_var[@@scope][@expression.a][1]
        #       end

        #       if (@expression.b != true || false)
        #           b = @@global_var[@@scope][@expression.b][1]
        #       end
        #       @@global_var[@@scope][@varName] = [@datatype, eval(a, @expression.operator, b)]



    # def eval()
    #   p "reavar eval"
 #        # p @@global_var[0][@varName]
    #   for scope in @@global_var #.reverse()?
 #            p scope[@varName]
    #       if scope[@varName]
 #                # p "eval()()()"
 #                if scope[@varName][1].class == @expression.eval().class
 #                  scope[@varName][1] = @expression.eval()
 #                  return scope[@varName][1]
 #                elsif scope[@varName][1].class == @expression.class
 #                    scope[@varName][1] = @expression.eval()
 #                    return scope[@varName][1]
 #                else
 #                    puts "#{scope[@varName][1].class} AssignError: #{@expression.class} is wrong type."
 #                    return
 #                end

 #            end
 #        end
 #        puts "Variabel Error: No variable found with name #{@id}!"
 #        return @ 
 #    end
