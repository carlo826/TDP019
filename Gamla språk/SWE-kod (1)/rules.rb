require 'rdparse'
require 'classes'


class Rules

  def initialize(file)
    @file = file
    @ruleparser = Parser.new("rules") do

      #VariableList and scope init
      @variables = VariableList.new
      @currentScope = 0
      @scope = Scope.new

      #First init of classes in need of the variableList as static
      dummySkriv = Skriv.new("dummy")
      dummySkriv.setVariableList(@variables)

      dummyFunktionAnrop = FunktionAnrop.new("dummy", ArgumentLista.new(Inget.new))
      dummyFunktionAnrop.setVariableList(@variables)

      dummyUttryck = Uttryck.new(Inget.new,Inget.new,Inget.new)
      dummyUttryck.setVariableList(@variables)

      dummyJamforelse = Jamforelse.new(Inget.new, Inget.new,Inget.new)
      dummyJamforelse.setVariableList(@variables)

      dummyOmJamforelse = OmJamforelse.new(Inget.new,Inget.new)
      dummyOmJamforelse.setVariableList(@variables)

      dummyMedansJamforelse = MedansJamforelse.new(Inget.new,Inget.new)
      dummyMedansJamforelse.setVariableList(@variables)

      #Structs
      Struct.new("Str", :value)
      Struct.new("Function", :scope, :prevScope)


      ##Tokens
      token(/\s/) #Remove whitespaces
      token(/#.+/) #Remove comments
      token(/falskt/) {Sanning.new(0)}
      token(/sant/) {Sanning.new(1)}
      token(/-?\d+\.\d+/) {|x| x.to_f} #Match Float
      token(/-?\d+/) {|x| x.to_i} #Match Integer

      #Match String
      token(/\".+\"/) {|x|
        Struct::Str.new(x)
      }

      #Match function/slutfunktion for scoping
      token(/funktion/) { 
        @currentScope = @scope.getNewScope
        Struct::Function.new(@currentScope)
      }
      token(/slutfunktion/) {|x| @currentScope = @scope.closeScope
        x}

      token(/[\w]+/) {|x| x} #Match keywords
      token(/./) {|x| x} #Match rest
      ##end Tokens

      start :kor do
        match(:operation_lista) {|operationList|

          #Variables declaration to global scope
          @variables.addScope(0, operationList.getNewVariables)
          
          #Variable updates to global scope
          operationList.getVariableUpdates.each{|varName,expr|
            @variables.updateVariable(varName,expr,0)
          }
          operationList.eval()
        }

      end

      rule :operation_lista do
        match(:operation_lista, :operation) {|operationList,operation| 
          operationList.add(operation)
          operationList
        }

        match(:operation) {|operation| Operationer.new(operation)}
      end
      
      rule :operation do
        match(:normal_operation) {|operation| Operation.new(operation)}
      end

      rule :normal_operation do
        match(:om_jamforelse)
        match(:medans_jamforelse)
        match(:funktion)
        match(:tilldelning)
        match(:skriv)
        match(:funk_anrop)
      end

      rule :funktion do
        #Without parameterlist
        match(:datatyp, Struct::Function, String, :operation_lista,
              "tillbaka", :a_uttryck, "slutfunktion") {
          |datatype,funcStruct,name,operationList,_,returnExpr,_|
          
          operationList.setScope(funcStruct.scope)
          #Variables is collected
          @localVariables = operationList.getNewVariables

          #Variable call
          if returnExpr.class == String
            returnExpr = @localVariables[returnExpr]
          end

          if datatype.isValid(returnExpr)
            @variables.addScope(funcStruct.scope, @localVariables)
            func = Funktion.new(name,operationList,datatype,
                                returnExpr,Inget.new,
                                funcStruct.scope,Inget.new)
          else
            func = Inget.new
            puts "Tillbaka värdet stämmer inte överens med funktions-definieringen"
          end

          #The function will be added the the variableList
          Variable.new(datatype,name,func)
        }

        #Function without operations just return value
        match(:datatyp, Struct::Function, String, "tillbaka", :a_uttryck, "slutfunktion") {
          |datatype,funcStruct,name,_,returnExpr,_|

          if datatype.isValid(returnExpr)
            func = Funktion.new(name,Inget.new,datatype,
                                returnExpr,Inget.new,
                                funcStruct.scope,Inget.new)
          else
            func = Inget.new
            puts "Tillbaka värdet stämmer inte överens med funktions-definieringen"
          end

          #The function will be added the the variableList
          Variable.new(datatype,name,func)
        }

        #With parameterlist and statements
        match(:datatyp, Struct::Function, String,  :parameterlista, 
              :operation_lista, "tillbaka", :a_uttryck, "slutfunktion") {
          |datatype,funcStruct,name,parameters,operationList,_,returnExpr,_|

          operationList.setScope(funcStruct.scope)

          #Variable declarations, parameter variables and variable updates is collected
          @localVariables = parameters.getParameters
          @localVariables= @localVariables.merge(operationList.getNewVariables)
          @localVariableUpdates = operationList.getVariableUpdates
          
          #Variable call
          if returnExpr.class == String
            returnExpr = @localVariables[returnExpr]
          end
          
          if datatype.isValid(returnExpr)
            @variables.addScope(funcStruct.scope, @localVariables)
            func = Funktion.new(name,operationList,datatype,
                                returnExpr,parameters,
                                funcStruct.scope, @localVariableUpdates)
          else
            func = Inget.new
            puts "Tillbaka värdet stämmer inte överens med funktions-definieringen"
          end

          #The function will be added the the variableList
          Variable.new(datatype,name,func)
        }
      end

      rule :parameterlista do
        match("(", :parameterlista, ")") {|_,parameterList,_| parameterList}

        #Match more parameters
        match(:parameterlista, ",", :datatyp, String) {|parameterList,_,datatype,name|
          parameterList.add(datatype,name)
          parameterList
        }
        
        #Match first parameter
        match(:datatyp, String) {|datatype,name| ParameterLista.new(datatype,name)}
      end
          
      rule :tilldelning do
        match(:datatyp, String, "=", :uttryck) {|datatype,name,_,expr| 
          objReturn = Inget.new

          if datatype.isValid(expr) 
            objReturn = Variable.new(datatype,name,expr)
          else
            puts "Datatypen är av #{datatype.classType} angivet värde uppfyller inte dessa krav"
          end
          objReturn
        }

        match(:datatyp, String) {|datatype,name|
          Variable.new(datatype,name,Inget.new)}

        match(String, "=", :uttryck) {|name,_,expr| VariableUpdate.new(name,expr)}
      end

      rule :datatyp do
        match("Tal") {Datatyp.new(Tal)}
        match("Flyt") {Datatyp.new(Tal)} 
        match("Sanning") {Datatyp.new(Sanning)}
        match("Text") {Datatyp.new(Text)}
        match(:inget) {Datatyp.new(Inget)}
      end

      rule :inget do
        match("Inget") {Inget.new}
      end
      
      rule :skriv do
        match("skriv",:a_uttryck) {|_,aExpr| Skriv.new(aExpr)}
      end

      rule :medans_jamforelse do
        match("medans", :jamforelse, "gor", :operation_lista, "slutmedans") {
          |_,relExpr,_,operationList,_|MedansJamforelse.new(relExpr,operationList)}
      end
      
      rule :om_jamforelse do
        match("om",:jamforelse, "gor", :operation_lista, "slutom") {
          |_,relExpr,_,operationList,_| OmJamforelse.new(relExpr,operationList)}
        
        match("om",:jamforelse, "gor", :operation_lista,
              "annars", :operation_lista, "slutom") {
          |_,relExpr,_,operationList,_,elseOperationList,_|

          x = OmJamforelse.new(relExpr,operationList)
          x.setAnnars(elseOperationList)
          x
        }

        match("om",:jamforelse, "gor", :operation_lista,
              :annars_om_jamforelse, "slutom") {
          |_,relExpr,_,operationList,elseIfOperation,_|

          x = OmJamforelse.new(relExpr,operationList)
          x.setAnnarsOm(elseIfOperation)
          x
        }
        
        match("om",:jamforelse, "gor", :operation_lista,
              :annars_om_jamforelse,"annars", :operation_lista, "slutom") {
          |_,relExpr,_,operationList,elseIfOperationList,_,elseOperationList,_|
          
          x = OmJamforelse.new(relExpr,operationList)
          x.setAnnarsOm(elseIfOperationList)
          x.setAnnars(elseOperationList)
          x
        }
      end

      rule :annars_om_jamforelse do
        match("annarsom", :jamforelse, :operation_lista, :annars_om_jamforelse) {
          |_,relExpr,operationList,elseIfOperationList|

          elseIfOperationList << [relExpr,operationList]
          elseIfOperationList
        }

        match("annarsom", :jamforelse, :operation_lista) {
          |_,relExpr,operationList| [[relExpr,operationList]]}
      end
      
      rule :jamforelse do
        #normal relation expression
        match(:a_uttryck, :j_operator, :a_uttryck) {|aExprLh,relOperator,aExprRh|
          Jamforelse.new(aExprLh,relOperator,aExprRh)}

        #Jamforelse with only "sant" and "falskt" as expr
        match(:pastaende) {|bool|
          objReturn = Jamforelse.new(Inget.new,"!=",Inget.new)
          if bool.eval == "sant" 
            objReturn = Jamforelse.new(Inget.new,"==",Inget.new)
          end
          objReturn
        }

        #Need to be able to nestle and use variables
        match(:a_uttryck)
      end
      
      rule :j_operator do
        match("<")
        match("<=")
        match(">") 
        match(">=")
        match("==")
        match("!=")
      end

      rule :uttryck do
        match(:jamforelse)
        match(:a_uttryck)
      end
      
      rule :a_uttryck do
        match(:a_uttryck, '+', :m_uttryck) {|aExprLh,aOperator,aExprRh|
          Uttryck.new(aExprLh,aOperator,aExprRh)}

        match(:a_uttryck, '-', :m_uttryck) {|aExprLh,aOperator,aExprRh|
          Uttryck.new(aExprLh,aOperator,aExprRh)}

        match(:m_uttryck)
      end

      rule :m_uttryck do
        match(:m_uttryck, '*', :atom) {|aExpr,aOperator,atom| 
          Uttryck.new(aExpr,aOperator,atom)}

        match(:m_uttryck, '/', :atom) {|aExpr,aOperator,atom| 
          Uttryck.new(aExpr,aOperator,atom)}

        match(:atom)
      end

      rule :atom do
        match("(", :a_uttryck, ")") {|_,aExpr,_| aExpr}
        match(:pastaende)
        match(:inget)
        match(:funk_anrop)
        match(:variabel)
        match(:flyt)
        match(:tal)
        match(:text)
      end

      rule :variabel do
        match(String)
      end
      
      rule :text do
        match(Struct::Str) {|string| Text.new(string.value)}
      end
      
      rule :flyt do
        match(Float) {|float| Tal.new(float)}
      end
      
      rule :tal do
        match(Integer) {|integer| Tal.new(integer)}
      end
      
      rule :pastaende do
        match(Sanning)
      end
      
      rule :funk_anrop do
        match(String,"(",:argumentlista,")") {|name,_,arguments,_| 
          FunktionAnrop.new(name, arguments)}

        match(String,"(",")") {|name,_,_|
          FunktionAnrop.new(name, ArgumentLista.new(Inget.new))}
      end

      rule :argumentlista do
        match(:argumentlista, "," ,:a_uttryck) {|arguments,_,aExpr| 
          arguments.add(aExpr)
          a
        }

        match(:a_uttryck) {|aExpr| argument = ArgumentLista.new(aExpr)}
      end   
     
    end     
  end
  
  def start
    compile = File.read(@file)
    @ruleparser.logger.level =  Logger::WARN
    puts "=> #{@ruleparser.parse compile}"
    nil
  end

end
