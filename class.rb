#!/usr/bin/env ruby

##############################################################################
#
# This part defines the language classes
#
##############################################################################

# Global Variables
@@scope = 0
@@global_var = [{}]
@@all_globals = {}
@@functions = {}
@@debug = true;

def incr_scope
	@@global_var << {} 
	@@scope += 1
	for g in @@all_globals
		@@global_var[@@scope][g[0]] = [g[1][0],g[1][1] ]
		@@global_var
	end
	# puts "Incrementing scope with 1 \n Scope count: #{@@scope}" if @@debug
end

def decr_scope
	@@global_var.pop
	@@scope -= 1
	# puts "Decrementing scope with -1 \n Scope count: #{@@scope}"
	if @@scope < 0
		raise("You cannot close base scope!")
	end
end


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

class DeclareVar
	attr_accessor :datatype, :varName, :expression, :global
	def initialize(datatype, varName, expression=nil, global = false)
		@datatype = datatype
		@varName = varName
		@expression = expression
		@global = global
	end
	def eval()
		if @global == true
			if @expression.class == Find_Variable && @expression.in_scope == true
				@@all_globals[@varName] = [@datatype, @@global_var[@@scope][@expression.get_name()][1]]
				@@global_var[@@scope][@varName.varName] = [@datatype, @@global_var[@@scope][@expression.get_name()][1]]

			elsif @expression == nil
	        	if @datatype == "int"
	            	@@all_globals[@@scope][@varName.varName] = [@datatype, Integer_node.new(nil)]
	            	@@global_var[@@scope][@varName.varName] = [@datatype, Integer_node.new(nil)]
	            end
			else
				@@all_globals[@varName.varName] = [@datatype, @expression.eval]
				@@global_var[@@scope][@varName.varName] = [@datatype, @expression.eval]
			end

        elsif @expression.class == Find_Variable
        	if @expression.in_scope == true
            	@@global_var[@@scope][@varName.varName] = [@datatype, @@global_var[@@scope][@expression.get_name()][1]]
            	return
            end

        elsif @expression == nil
        	if @datatype == "int"
            	@@global_var[@@scope][@varName.varName] = [@datatype, Integer_node.new(nil)]
            end
        else
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
    	if @expression.class == Find_Variable && @expression.in_scope == true && @varName.in_scope == true
    		if @operator == '='
    			@@global_var[@@scope][@varName.varName][1] = @expression.eval#[@datatype, @@global_var[@@scope][@expression.get_name()][1]]
    		elsif @operator == '-='
    			@@global_var[@@scope][@varName.varName][1] = @varName.eval - @expression.eval
    		elsif @operator == '+='
    			@@global_var[@@scope][@varName.varName][1] = @varName.eval + @expression.eval
    		end

    	elsif @expression == nil && @varName.in_scope == true && @@global_var[@@scope][@varName.varName][1].class == Fixnum
			if @operator == '++'
				@@global_var[@@scope][@varName.varName][1] = @varName.eval + 1
			elsif @operator == '--'
				@@global_var[@@scope][@varName.varName][1] = @varName.eval - 1
			else
				throw "NoMethodError: undefined method #{@operator} for nil:NilClass"
				return
			end
    	elsif @varName.in_scope == true
	    	if @operator == '+='
	    		@@global_var[@@scope][@varName.varName][1] = @varName.eval + @expression.eval
	    	elsif @operator == '-='
	    		@@global_var[@@scope][@varName.varName][1] = @varName.eval - @expression.eval
	    	elsif @operator == '='
	    		@@global_var[@@scope][@varName.varName][1] =  @expression.eval
	    	end
    	end
    end
end

class Find_Variable
	attr_accessor :varName
    def initialize(varName)
        @varName = varName
    end

    def returnName
    	@varName
    end

    def in_scope
    	if @@global_var[@@scope][@varName]
    		return true
    	else
    		puts "'#{@varName}': undefined local variable or method '#{@varName}' for main:Object (NameError) }"
    		return false
        end
    end

    def get_name
        for scope in @@global_var 
            if scope[@varName]
                return @varName
            end
        end
        return "false"
    end


    def eval
        for scope in @@global_var 
            if scope[@varName]
                return scope[@varName][1]
            end
        end
        puts "NameError: undefined local variable or method #{@varName} for main:Object"
        return
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

class Array_node
	def initialize(expr_list)
		@expr_list = expr_list
	end
	def eval()
		return @expr_list
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
    	if(@a.class == Find_Variable && @b.class != Find_Variable && @a.in_scope == true)
    		instance_eval("#{@@global_var[@@scope][@a.get_name()][1]} #{@operator} #{@b.eval}")
    	elsif(@a.class != Find_Variable && @b.class == Find_Variable && @b.in_scope == true)
    		instance_eval("#{@a.eval} #{@operator} #{@@global_var[@@scope][@b.get_name()][1]}")
    	elsif(@a.class == Find_Variable && @b.class == Find_Variable && @a.in_scope == true && @b.in_scope == true)
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
			if @expr.class != Find_Variable
				puts @expr.eval
				return @expr.eval
			elsif @expr.class == Find_Variable && @expr.in_scope == true
				if (@@global_var[@@scope][@expr.get_name][0] == "array")
					printer = "["
					for i in @@global_var[@@scope][@expr.get_name][1]
						printer << "#{i.eval},"
					end
					printer = printer[0...-1]
					printer << "]"
					puts printer
					return printer
				else
					puts @expr.eval
					return @expr.eval
				end
			end

		else
			puts "No input for print"
					return @expr.eval
			return "nil"
			return nil
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
	def eval
		incr_scope()
		@var.eval
		while @bool.eval do
			for block in @blocks
				if block.class == ReturnNode
					return block.eval
				elsif block.class == Conditions_Node && block.conditional.eval == true
					for b in block.ifbranch
						if b.class == ReturnNode
							block.eval
							return b.eval
						end
					end
				else
					block.eval
				end
			end
			@assignment.eval
		end
		decr_scope()
	end
end

class For_each_loop_node
	def initialize(var, iterable, blocks)
		@var = var
		@iterable = iterable
		@blocks = blocks 
	end

	def eval
		#Variabel som kommer ersättas av innehållet i iteratorn
		@@global_var[@@scope][@var.returnName] = ['temp',nil]

		if(@iterable.class == Find_Variable)
			#Iterera genom variablens lista
			for i in @@global_var[@@scope][@iterable.returnName][1]
				#Sätt värdet på den temporära variablen till värdet på i
				@@global_var[@@scope][@var.returnName][1] = i.eval
				#Utför loopens blocks
				for block in @blocks
					block.eval
				end
			end
	    elsif(@iterable.class == Array_node)
	    	#Iterera genom variablens lista
	    	for i in @iterable.eval
	    		#Sätt värdet på den temporära variablen till värdet på i
				@@global_var[@@scope][@var.returnName][1] = i.eval
				#Utför loopens blocks
				for block in @blocks
					block.eval
				end
			end
		end
	end
end


class While_loop_node
	def initialize(bool_expr, blocks)
		@bool_expr = bool_expr
		@blocks = blocks
	end
	def eval
		incr_scope()
		while @bool_expr.eval do
			for block in @blocks
				if block.class == ReturnNode
					return block.eval
				else
					block.eval
				end
			end
		end
		decr_scope()
	end
end



class Conditions_Node
	attr_accessor :conditional, :ifbranch, :elsebranch 
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
		# if @varName.in_scope
		if (@varName.get_name() != "false")
			puts "Function Variable name already exists"
			return nil
		else
			@@functions[@varName.returnName()] = [@datatype, @parameters, @blocks]
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
		if(@returnExpr != nil)
			if @returnExpr.class == Find_Variable && @returnExpr.in_scope == true
				return @returnExpr.eval
			elsif @returnExpr.class != Find_Variable
				return @returnExpr.eval()
			end
		end
	end
end

