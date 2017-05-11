#!/usr/bin/env ruby

##############################################################################
#
# This part defines the language classes
#
##############################################################################

# Global Variables
@@scope = 0
@@global_var = [{}]
@@functions = {}
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




# class Blocks
# 	def initialize(blocks, block)
# 		@block = block
# 		@blocks = blocks
# 	end
# 	def eval()
# 		puts "Blocks eval"
# 		return_val = @blocks.eval
# 		if @block.class != Block
# 			@blocks.eval
# 		else
# 			return return_val
# 		end
# 		return_val = @block.eval
# 	end
# end


class Block
	def initialize(expr)
		@expr = expr
	end

	def eval()
		return_value = nil
 		for b in @expr
			return_value = b.eval()
		end
		return return_value
		# return @expr.eval
	end
end


# class Block
# 	def initialize(expr)
# 		@expr = expr
# 	end

# 	def eval()
# 		return @expr.eval
# 	end
# end


class DeclareVar
	attr_accessor :datatype, :varName, :expression
	def initialize(datatype, varName, expression=nil)
		@datatype = datatype
		@varName = varName
		@expression = expression
	end
	def eval()

        if @expression.class == Find_Variable
            @@global_var[@@scope][@varName.returnName()] = [@datatype, @@global_var[@@scope][@expression.get_name()][1]]

        elsif @expression == nil
        	if @datatype == "int"
            	@@global_var[@@scope][@varName.returnName()] = [@datatype, Integer_node.new(nil)]
            end
        else
        	puts "eval function plz"
        	p @expression
            @@global_var[@@scope][@varName.returnName()] = [@datatype, @expression.eval()]
        end
  
	end
end

class ReaVar
	def initialize(varName, operator, expression)
		@varName = varName
		@expression = expression
		@operator = operator
	end

    def eval()
        for scope in @@global_var #.reverse()?
            if scope[@varName.get_name()]
                if @expression.class == Find_Variable
                    scope[@varName.get_name()][1] = scope[@expression.get_name()][1]
                    return nil
                else
					if(@operator == '+=')
						scope[@varName.get_name()][1] = @varName.eval + @expression.eval
					elsif(@operator == '-=')
						scope[@varName.get_name()][1] = @varName.eval - @expression.eval
					elsif(@operator == '++' && @expression == nil)
						scope[@varName.get_name()][1] = @varName.eval + 1
					elsif(@operator == '--' && @expression == nil)
						scope[@varName.get_name()][1] = @varName.eval - 1
					elsif(@operator == '=')
						scope[@varName.get_name()][1] = @expression.eval
					end

                    # scope[@varName.get_name()][1] = instance_eval("#{@varName.eval} #{@operator} #{@expression.eval}")
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

    def returnName
    	@varName
    end

    def get_name
        for scope in @@global_var 
            if scope[@varName]
                return @varName #.eval()
                # return scope[@varName][1] #.eval()
            end
        end
        # puts "no variabel found"
        # puts "NameError: undefined local variable or method #{@varName} for main:Object"
      	# p "get_name"
        return "false"
        # return @varName

    end


    def eval
        for scope in @@global_var 
            if scope[@varName]
                # return @varName #.eval()
                return scope[@varName][1] #.eval()
            end
        end
        puts "NameError: undefined local variable or method #{@varName} for main:Object"
        return
        # return @varName
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
  #   	p "@a: #{@a} "
  #   	if (@a.class == Find_Variable) then
  #   		@a = @a.eval
		# end
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
        # puts "striiiing_node"
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

class Neg_node
	def initialize(bool_expr)
		@bool_expr = bool_expr
	end
		def eval
		return (not @bool_expr.eval)
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

    	# p @b.class
    	if(@a.class == Find_Variable && @b.class != Find_Variable)
    		instance_eval("#{@@global_var[@@scope][@a.get_name()][1]} #{@operator} #{@b.eval}")
    	elsif(@a.class != Find_Variable && @b.class == Find_Variable)
    		instance_eval("#{@a.eval} #{@operator} #{@@global_var[@@scope][@b.get_name()][1]}")
    	elsif(@a.class == Find_Variable && @b.class == Find_Variable)
    		instance_eval("#{@@global_var[@@scope][@a.get_name()][1]} #{@operator} #{@@global_var[@@scope][@b.get_name()][1]}")
    	else
        	instance_eval("#{@a.eval} #{@operator} #{@b.eval}") 
    	end
    end
end 


class Print_expr
	def initialize(expr=nil)
		@expr = expr
	end
	def eval
		if (@expr != nil)
			printer = @expr.eval
			puts printer
			return printer
		else
			puts "No input for print"
		end
	end
end
class For_loop_node
	def initialize(var, bool, assignment, blocks)
		@var = var
		@bool = bool 
		@assignment = assignment 
		@blocks = blocks
	end
	# for (int i = 0; i < 10; i++)

	def eval
		incr_scope()
		@var.eval
		while @bool.eval do
			for block in @blocks
				block.eval
			end
			# @blocks.eval
			@assignment.eval
		end
		decr_scope()
	end
end


class Conditions_Node
	def initialize(conditional, ifbranch, elsebranch=nil)
		@conditional = conditional
		@ifbranch = ifbranch
		@elsebranch = elsebranch
	end

	def eval
		if(@conditional == true)
			conditional = true
		else
			conditional = @conditional.eval()
		end
		if (conditional)
			for condition in @ifbranch
				condition.eval
			end
			#return_value = @ifbranch.eval()
		else
			if (@elsebranch != nil)
				return_value = @elsebranch.eval()
			end
		end
		return return_value
	end
end

class Def_function_node
	def initialize(datatype, varName,parameters, blocks)

		@datatype = datatype
		@varName = varName
		@parameters = parameters
		@blocks = blocks
	end



	def eval()
		if (@varName.get_name() != "false")
			puts "Function Variable name already exists"
			return nil
		else
			@@functions[@varName.returnName()] = [@datatype, @parameters, @blocks]
        	# @@global_var[@@scope][@varName.returnName()] = ["func", [@datatype, @parameters, @blocks]]
        	# p "else 2"
		end
	end
end


# hej(1,2,3)

class Call_function_node
	def initialize(varName, parameters)
		@varName = varName
		@parameters = parameters
	end




	def eval()
		if @@functions[@varName.returnName][1] == nil
			puts "no parameters"
			#puts "global var #{@@global_var}"
			#p @@functions[@varName.returnName][2][0].eval
			#@@functions[@varName.returnName][2][1].eval
			incr_scope()
			for i in p @@functions[@varName.returnName][2]
				if i.class == ReturnNode
					return i.eval
				else
					i.eval
				end
			end
			decr_scope
			return nil
		end
		#TODO Implementera felhantering, matcha varje arguments datatyp med datatypen som angavs vid deklaration
		j = 0;
		incr_scope()
		for i in @@functions[@varName.returnName][1]

			@@global_var[@@scope][i.varName.returnName] = [i.datatype, @parameters[j].eval]
			j += 1
		end

		@@functions[@varName.returnName][2][0].eval
		decr_scope
		return nil
		if !(@@functions[@varName.returnName()])
			puts "No function exists with name #{@varName}"
			return nil
		end

	end
		
end

class ReturnNode
	def initialize(returnExpr=nil)
		@returnExpr = returnExpr
	end

	def eval
		p "jing yangjing"

		if(@returnExpr != nil)
			if @returnExpr.class == Find_Variable && @returnExpr.get_name != "false"
				return @returnExpr.eval
			elsif @returnExpr.class != Find_Variable
				# puts @returnExpr.eval()
				return @returnExpr.eval()
			else
				puts "No variable exists with name #{@returnExpr} in this scope"
			end
		else
			@return_value = []
		end
		# puts @returnExpr
		return @returnExpr
	end
end


# class ReturnNode
# 	def initialize(returnExpr=nil)
# 		@returnExpr = returnExpr
# 		@return_value = nil
# 	end
# 	def get_value
# 		return @return_value
# 	end
# 	def eval
# 		p "jing yangjing yangjing yangjing yangjing yangjing yangjing yangjing yangjing yangjing yangjing yangjing yangjing yang"
# 		if(@returnExpr != nil)
# 			if @returnExpr.class == Find_Variable && @returnExpr.get_name != "false"
# 				return @returnExpr.eval
# 			elsif @returnExpr.class != Find_Variable
# 				@return_value = 
# 				puts @returnExpr.eval()
# 				return @returnExpr.eval()
# 			else
# 				puts "No variable exists with name #{@returnExpr} in this scope"
# 			end
# 		else
# 			@return_value = []
# 		end
# 		puts @return_value
# 		return @return_value
# 	end
# end


	# def int hej(int a, int b, int c)

	# hej(1,2,3)
	# hejs(1,2,3)

	# {"i"=>["int", 3]}
# 		e

#         if @expression.class == Find_Variable

#             @@global_var[@@scope][@varName.returnName()] = ["func", @@global_var[@@scope][@expression.get_name()][1]]

#         elsif @expression == nil
#             @@global_var[@@scope][@varName.returnName()] = [@datatype, nil]

#         else
#             @@global_var[@@scope][@varName.returnName()] = [@datatype, @expression.eval()]
#         end
# 	end

# end








# class Param_List
# 		def initialize(parameters)
# 			@parameters = parameters
	
# 		end
		
# 		def eval()
# 			return @parameters
# 		end
# 	end

# end












# class If_condition_node
# 	def initialize(condition, blocks)
# 		@condition = condition
# 		@blocks = blocks
# 	end

# 	def eval
# 		incr_scope
# 		if @condition.eval
# 			return_val = @blocks.eval
# 			decr_scope
# 			return return_val
# 		end
# 		decr_scope
# 	end
# end


# class If_else_condition_node
# 	def initialize(condition, blocks, else_condition)
# 		@condition = condition
# 		@blocks = blocks
# 		@else_condition = else_condition
# 	end

# 	def eval
# 		incr_scope
# 		if @condition.eval
# 			return_val = @blocks.eval
# 		else
# 			return_val = @else_condition.eval
# 		end
# 		decr_scope
# 		return return_val
# 	end
# end

# class Else_condition_node
# 	def initialize(condition, blocks, else_condition)
# 		@condition = condition
# 		@blocks = blocks
# 		@else_condition = else_condition
# 	end
	
# 	def eval
# 		incr_scope
# 		if @condition.eval
# 			return_val = @blocks.eval
# 		else
# 			return_val = @else_condition.eval
# 		end
# 		decr_scope
# 		return return_val
# 	end
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
