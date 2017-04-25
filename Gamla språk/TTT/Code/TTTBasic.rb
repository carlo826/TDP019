#!/usr/bin/env ruby
#Made in ruby version 1.8.7
####################### NUM ##############################
class NUM_C
	attr_accessor :value,:type
	def initialize (value)
		@value = value
		@type = :NUM
	end
	def eval()
		return @value
	end
end
####################### STR ##############################
class STR_C
	attr_accessor :value,:type
	def initialize (value)
		@value = value
		@type = :STR
	end
	def eval()
		return @value
	end
end
####################### BOOL ##############################
class BOOL_C
	attr_accessor :value,:type
	def initialize (value)
	#because we don't use ruby's true we convert it to our symbol instead
		if value == true or value == "TRUE"
			value = :TRUE
		elsif value == false or value == "FALSE"
			value = :FALSE
		end
		@value = value
		@type = :BOOL
	end
	def eval()
		return @value
	end
end
####################### LIST ##############################
class LIST_C
	attr_accessor :list,:type
	def initialize(list)
		@list = list
		@type = :Array
	end
	
	def eval
		return @list
	end
end
####################### LIST GET ##############################
class LIST_GET
	attr_accessor :list,:index
	def initialize(var, index)
		@index = index
		@list = var
		
	end
	def eval
		if @index != nil
			return @list.eval[@index.eval]
		else
			return @list.eval
		end
	end
end
####################### LIST ADD ##############################
class LIST_ADD_C
	attr_accessor :list,:value
	def initialize(list,value)
		@list = list
		@value = value
	end
	def get_type(i)
		return (@@variables[i][@list.name])[1]
	end
	def eval
		value_type = :NUM if (@value.eval[0].kind_of?Float)
       	value_type = :STR if (@value.eval[0].kind_of?String)
   		type_error = false
   		i = @@scope_base.last
  		puts "#{@expr} is stored" if (@@Debug)
    	while(i<=@@scope)
      		if @@variables[i][@list.name] != nil
      			@type = get_type(i)
   				if(value_type==@type and @type != :ALL)
   					@value.eval.each do |element| 
   						if element.class != @value.eval[0].class
   							type_error = true
   						end
   					end
   				elsif(@type != :ALL)
   					type_error = true
   				end
   			end
   			if (type_error)
   				puts "Wrong type definition"
    			return :FALSE
   			end
			if @@variables[i][@list.name] != nil
				@value.eval.each do |element| 
					@@variables[i][@list.name][0].push(element)
				end
      		end
      		i+=1
    	end
    	@value.eval
	end
end
####################### LIST REMOVE ##############################
class LIST_REMOVE_C
	attr_accessor :list,:value
	def initialize(list,value)
		@list = list
		@value = value
	end
	def eval
		@list.eval.delete_at(@value.eval)
	end
end
####################### HASH ##############################
class HASH_C
	attr_accessor :hash,:type
	def initialize(hash)
		@hash = hash
		@type = :Hash
	end
	
	def eval
		return @hash
	end
end
####################### HASH GET ##############################
class HASH_GET
	attr_accessor :hash,:index
	def initialize(var, index)
		@index = index
		@hash = var
	end
	def eval
		if @index != nil
			return @hash.eval[@index.eval]
		else
			return @hash.eval
		end
	end
end
####################### HASH ADD ##############################
class HASH_ADD_C
	attr_accessor :hash,:value
	def initialize(hash,value)
		@hash = hash
		@value = value
	end
	def eval
		@hash.eval.merge!(value.eval)
	end
end
####################### HASH REMOVE ##############################
class HASH_REMOVE_C
	attr_accessor :hash,:index
	def initialize(hash,index)
		@hash = hash
		@index = index
	end
	def eval
		@hash.eval.delete(index.eval)
	end
end
####################### EMPTY ##############################
class EMPTY_C
	attr_accessor :data
	def initialize(data)
		@data = data
	end
	def eval
		BOOL_C.new(@data.eval.empty?).eval
	end
end