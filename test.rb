

a = {"a" => 1, "b" => 2}


if a["c"] == nil
	p "hej"
end
i = 1337

def func

	puts "puts i #{i}"

end

func
class Find_Variable
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
    		puts "NameError: undefined local variable or method #{@varName} for main:Object"
    		return false
        end
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