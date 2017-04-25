#!/usr/bin/env ruby
#Made in ruby version 1.8.7
@@variables =[{}]	# List with hash that holds the variables in the program.
					# The list grows one hash with every scope. 
					# Stored [{"varibel"=>value,"varibel"=>value},{"varibel"=>value},{}]
					
@@functions = {} 	# HASH that holds the functions that is created in the program.
					# Stored {"name_on_function"=>function_class_object}
					
@@scope = 0 		# Global scope that change the scope so local and global scope works.

@@scope_base = [0] 	# Basic scope for function so variabel outside the function is 
					# not reach and variables in the function is local with in it self.
					
@@Debug = false		# Do Debug set true. false for regulary use

####################### Look up ##############################

def look_up(variable)
  	i = @@scope
  	while(i>=@@scope_base.last)
    	if @@variables[i][variable] != nil
      		return @@variables[i][variable][0]
      		puts "#{@@variables[i][variable]} is found" if (@@Debug)
      		#return var[0]
    	end
    	i -= 1
  	end
  	puts "Variable '#{variable}' does not exist."
  	:FALSE
end
def look_up_function(function_name)
	if @@functions[function_name] != nil
		return @@functions[function_name]
	end
	puts "Function '#{function_name}' does not exist."
	:FALSE
end
####################### Check type ##############################

def convert_to_object(expr_in)
	#to make type check we need to convert the expr to type object
	if (expr_in.eval.kind_of?Float)
  		object= NUM_C.new(expr_in.eval)
  	elsif(expr_in.eval.kind_of?String)
  		object= STR_C.new(expr_in.eval)
  	elsif(expr_in.eval == :FALSE)
  		object= BOOL_C.new(expr_in.eval)
	elsif(expr_in.eval == :TRUE)
		object= BOOL_C.new(expr_in.eval)
  	end
  	return object
end
####################### declare variable ##############################
def declare_variable(variable,expr,type)
	i = @@scope_base.last
    add_variable = true
    while(i<=@@scope)
    	if @@variables[i][variable.name] != nil
      		puts "#{@variable.name} is changed in #{i}" if (@@Debug)
      		@@variables[i][variable.name] =  [expr.eval,type]
       		add_variable = false
    		end
    	i+=1
    end
    if add_variable
    	puts "#{@variable.name} is added in #{@@scope}" if (@@Debug)
    	@@variables[@@scope][@variable.name] = [expr.eval,type]
    end
end

####################### SCOPE CONTROL ##############################

def new_scope()
	puts "#{@@scope} is incresed by one" if (@@Debug)
  	@@scope +=1
 	@@variables << {}
end

def new_scope_base()
  	new_scope()
  	@@scope_base << @@scope
  	puts "#{@@scope_base} is base" if (@@Debug)
end

def close_scope()
  	@@variables.pop
  	puts "#{@@scope} is decrease by one" if (@@Debug)
  	@@scope-=1
  	if @@scope < 0
    	raise("Scope is less then 0. Error in scope.")
 	end
end

def close_scope_base()
  	close_scope()
  	@@scope_base.pop
  	puts "#{@@scope_base} is base" if (@@Debug)
end

####################### FUNCTION ##############################
class DECL_FUNCTION_C
	attr_accessor :function_name, :parameters, :function_body
  	def initialize(function_name, parameters ,function_body)
    	@function_name = function_name
    	if parameters
    		@parameters = parameters
    	else
    		@parameters = []
    	end
    	@function_body = function_body
  	end
  	def eval
  		puts "#{function_name} is made" if (@@Debug)
  		@@functions[function_name] = [@parameters,@function_body]
  		:TRUE
  	end
end
class FUNCTION_CALL_C
	attr_accessor :function_name, :arguments
	def initialize(function_name, arguments)
    	@function_name = function_name
    	@arguments = []
    	@arguments = arguments if arguments
  	end
  	def declare_num_parameter(param,param_counter,arg,arg_counter)
  		DECL_C.new(VAR_C.new(param[param_counter]), NUM_C.new(arg[arg_counter]),param[param_counter-1]).eval
  	end
  	def declare_str_parameter(param,param_counter,arg,arg_counter)
  		DECL_C.new(VAR_C.new(param[param_counter]), STR_C.new(arg[arg_counter]),param[param_counter-1]).eval
  	end
  	def declare_bool_parameter(param,param_counter,arg,arg_counter)
  		DECL_C.new(VAR_C.new(param[param_counter]), BOOL_C.new(arg[arg_counter]),param[param_counter-1]).eval
  	end
  	def run_parameters(parameters,argument)
  		number_of_parameters = parameters.length-1
  		if (number_of_parameters > 0)
  		#The to counters for parameters and arguments. 
  		#The parameter has two value for each argument. 
  		#So parameters_countern increase by two each loop and the arguments_counter increase by one.
  			parameter_counter = 1
  			arguments_counter = 0
  			#Loop and set the parameters to it's value.
  			while(parameter_counter<=number_of_parameters)
  				if parameters[parameter_counter-1] == :NUM
  					declare_num_parameter(parameters,parameter_counter,argument,arguments_counter)
  				elsif parameters[parameter_counter-1] == :STR
  					declare_str_parameter(parameters,parameter_counter,argument,arguments_counter)
  				elsif parameters[parameter_counter-1] == :BOOL
  					declare_bool_parameter(parameters,parameter_counter,argument,arguments_counter)
  				else #THIS IS THE ALL TYPE
  					if @argument[arguments_counter].class == NUM_C
  						declare_num_parameter(parameters,parameter_counter,argument,arguments_counter)
  					elsif @argument[arguments_counter].class == STR_C
  						declare_str_parameter(parameters,parameter_counter,argument,arguments_counter)
  					elsif @argument[arguments_counter].class == BOOL_C
  						declare_bool_parameter(parameters,parameter_counter,argument,arguments_counter)
  					end
  				end
  				parameter_counter+=2
  				arguments_counter+=1
  			end
  		end
  	end
  	def check_parameters(parameters,arguments)
  		number_of_parameters = parameters.length-1
  	# this is check the quantity is the same for parameters and arguments
  		if (parameters.length/2) != (arguments.length)
  			return false
  		end
  		# this is the check for right type
  		if (number_of_parameters > 0)
  			parameter_counter = 1
  			arguments_counter = 0
  			while(parameter_counter<=number_of_parameters)
  				if @arguments[arguments_counter].class == NUM_C
  					if  parameters[parameter_counter-1] != :NUM
  						return false
  					end
  				elsif @arguments[arguments_counter].class == STR_C
  					if  parameters[parameter_counter-1] != :STR
  						return false
  					end
  				elsif @arguments[arguments_counter].class == BOOL_C
  					if  parameters[parameter_counter-1] != :BOOL
  						return false
  					end
  				end
  				parameter_counter+=2
  				arguments_counter+=1
  			end
  		end
  		return true
  	end
  	
	def eval
  		argument_list=[]
		#We run eval on all the arguments that is set.
		if (!@arguments.empty?)
			(0...@arguments.length).each do |i|
				argument_list[i] = @arguments[i].eval
			end
		end
  		new_scope_base()
  		# This is to get the function with parameters and body.
  		function = look_up_function(@function_name)
  		
  		# We need to check the parameters are right we do so by running check_parameters
  		if (check_parameters(function[0],argument_list))
  			run_parameters(function[0],argument_list)
  			puts "#{@function_name} is called" if (@@Debug)
  			block = function[1]
  			# Here the body or block in the function is run
  			result = block.eval
  			close_scope_base()
  			return result
  		else
  			puts "Argument and parameter error, check quantity or type"
  			return :FALSE
  		end
  	end
end
####################### STATEMENT LIST ##############################

class STMT_LIST_C
  attr_accessor :stmt, :stmt_list
  def initialize (stmt,stmt_list)
    @stmt = stmt
    @stmt_list = stmt_list
  end
  def eval()
    return_value = @stmt.eval
    if @stmt.class != DONE_C
      	@stmt_list.eval
    else
      return return_value
    end
  end
end

####################### DECL ##############################
class DECL_C
	attr_accessor :variable, :expr, :type
  	def initialize(var, expr,type)
    	@variable = var
    	@expr = expr
    	@type = type
  	end
  	def eval
		expr = convert_to_object(@expr)
  		if((@type == :ALL) or (@type == expr.type))
    		declare_variable(@variable,expr,@type)
    	else
    		puts "Wrong type definition"
    		return :FALSE
    	end
    	@expr.eval
  	end
end
####################### ASSIGN ##############################
class ASSIGN_C
  	attr_accessor :variable, :expr
  	def initialize(id, expression)
    	@variable = id
    	@expr = expression
  	end
  	def eval  	
  		expr = convert_to_object(@expr)	
  		i = @@scope_base.last
  		found = false
  		
    	while(i<=@@scope)
      		if @@variables[i][@variable.name] != nil
      			type = (@@variables[i][@variable.name])[1]
      			if (type == :ALL)
      				return_value = @@variables[i][@variable.name] =  [expr.eval,type]
      				found = true
      			elsif(type == expr.type)
      				return_value = @@variables[i][@variable.name] =  [expr.eval,type]
      				found = true
      			end
      		end
      		i+=1
    	end
    	if (found == false)
    		puts "Wrong type definition"
    		return :FALSE
    	end
  		return_value[0]
  	end
end
####################### VARIABLE ###############################
class VAR_C
  attr_accessor :name
  def initialize(variable)
    @name = variable
  end
  def eval
    return look_up(@name)
  end
end
####################### DECL LIST ##############################
class DECL_LIST_C
	attr_accessor :variable, :expr, :type
  	def initialize(id, expression,type)
    	@variable = id
    	@expr = expression
    	@type = type
  	end
  	def eval
       	value_type = :NUM if (@expr.eval[0].kind_of?Float)
       	value_type = :STR if (@expr.eval[0].kind_of?String)
   		type_error = false
   		if(value_type and @type != :ALL)
   			@expr.eval.each do |i| 
   				if i.class != @expr.eval[0].class
   					type_error = true
   				end
   			end
   		end
   		if (type_error)
   			puts "Wrong type definition"
    		return :FALSE
   		end
   		if (@type == :ALL) or (@type == value_type)
   			declare_variable(@variable,@expr,@type)
    	else
    		puts "Wrong type definition"
    		return :FALSE
    	end
    	@expr.eval
  	end
end
####################### DECL HASH ##############################
class DECL_HASH_C
	attr_accessor :variable, :expr, :type
  	def initialize(id, expression,type)
    	@variable = id
    	@expr = expression
    	@type = type
  	end
  	def eval
   		declare_variable(@variable,@expr,@type)
    	@expr.eval
  	end
end

####################### MATH ##############################
class ARIT_OBJECT
  	attr_accessor :value1,:value2,:operator
  	def initialize (operator,value1,value2)
    	@operator = operator
    	@value1 = value1
   		@value2 = value2
  	end
  
	def eval()
      	return instance_eval("#{@value1.eval()} #{@operator} #{@value2.eval()}")
  	end
end

class LOG_OBJECT
	attr_accessor :value1,:value2,:operator
  	def initialize (operator,value1,value2)
    	@operator = operator
    	@value1 = value1
    	@value2 = value2
  	end
  
  	def eval()
    	if @operator == 'AND' 
      		@operator = 'and'
    	elsif @operator == 'OR'
     		@operator = 'or'
    	end
    	return BOOL_C.new(instance_eval("#{@value1.eval()} #{@operator} #{@value2.eval()}")).eval
  	end
end
class LOG_OBJECT_NOT
  	attr_accessor :value1,:operator
  	def initialize (operator,value1)
    	@operator = operator
    	@value1 = value1
  	end
  	def eval()
    	if @operator == 'NOT'
      		@operator = 'not'
    	end
    	return BOOL_C.new(instance_eval("#{@operator} #{@value1.eval()}")).eval
  	end
end
class COMP_OBJECT
  	attr_accessor :value1,:value2,:operator
  	def initialize (operator,value1,value2)
    	@operator = operator
    	@value1 = value1
    	@value2 = value2
  	end
  	def eval()
    	return BOOL_C.new(instance_eval("#{@value1.eval()} #{@operator} #{@value2.eval()}")).eval
  	end
end

####################### RETURN ##############################
class DONE_C
	attr_accessor :value
	def initialize (value)
		@value = value
	end
	def eval()
		return @value.eval
	end
end
####################### INPUT AND OUTPUT #########################
class PRINT_C
	attr_accessor :value
	def initialize (value)
		@value = value
	end
	def eval()
		puts "== "+ @value.eval.to_s
	end
end
class READ_C
	attr_accessor :name ,:type
	def initialize (name,type= :STR)
		@name = name
		@type = type
	end
	def eval()
		print "<< "
		if (@type == :NUM)
			indata = NUM_C.new(gets.to_i)
		else
			indata = STR_C.new(gets.to_s)
		end
		return DECL_C.new(VAR_C.new(@name),indata,@type).eval
	end
end
####################### ITERATORS ##############################

class WHILE_C
  attr_accessor :condition, :statement
  def initialize(cond, stmt)
    @condition = cond
    @statement = stmt
  end
  def eval
    new_scope()
    while @condition.eval == :TRUE do
      	if @statement.class == DONE_C
      		return_value = @statement.eval
      		close_scope()
      		return return_value
      		break
     	else
      	 	@statement.eval
      		puts "#{@statement.eval} is eval" if (@@Debug)
      	end
    end
    close_scope()
    :TRUE
  end
end

class FOR_C
  attr_accessor :iter_var, :start, :range, :increase, :block
  def initialize (iter_var, start, range, increase, block)
    @iter_var = iter_var
    @start = start
    @range = range
    @increase = increase
    @block = block
  end
  def eval()
  	new_scope()
  	# Declare the iterator variable to it start value
    DECL_C.new(VAR_C.new(@iter_var[1]), @start, @iter_var[0]).eval
    while (@start.eval <= @range.eval) do
    	if @block.class == DONE_C
      		return_value = @block.eval
      		close_scope()
      		return return_value
      		break
     	else
      	 	@block.eval
      	end 
      	# Redeclare the iterator variable in the loop
     	DECL_C.new(VAR_C.new(@iter_var[1]), @start = NUM_C.new((@start.eval + @increase.eval)), @iter_var[0]).eval
    end
    close_scope()
    :TRUE
  end
end

class EACH_C
  def initialize(iter_var, iter_values, block)
		@iter_var = iter_var
		@iter_values = iter_values
		@block = block
	end
	def eval
		new_scope()
		@iter_values.eval.each do |i|
			if (i.kind_of?Float)
  				DECL_C.new(VAR_C.new(@iter_var[1]), NUM_C.new(i),@iter_var[0]).eval
  			elsif(i.kind_of?String)
  				DECL_C.new(VAR_C.new(@iter_var[1]), STR_C.new(i),@iter_var[0]).eval
  			elsif(i == :FALSE)
  				DECL_C.new(VAR_C.new(@iter_var[1]), BOOL_C.new(i),@iter_var[0]).eval
			elsif(i == :TRUE)
				DECL_C.new(VAR_C.new(@iter_var[1]), BOOL_C.new(i),@iter_var[0]).eval
			end
			@block.eval
		end
		close_scope()
		:TRUE
	end
end

####################### SELECT ################################
class IF_C
  attr_accessor :condition,:stmt
  def initialize (condition,stmt)
    @condition = condition
    @stmt = stmt
  end
  def eval()
  	new_scope()
    if @condition.eval()== :TRUE
      	return_value = @stmt.eval()
      	close_scope()
      	return return_value
    end
    close_scope()
  end
end

class IF_ELSE_C
	attr_accessor :condition, :statement1, :statement2
 	def initialize(condition, stmt1, stmt2)
    	@condition = condition
   		@statement1 = stmt1
   		@statement2 = stmt2
  	end
  	def eval
    	new_scope()
    	if @condition.eval()== :TRUE
      		return_value = @statement1.eval
    	else
    		return_value = @statement2.eval
    	end
		close_scope()
    	return return_value
  	end
end
