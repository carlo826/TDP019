class Operationer
  def initialize(operation)
    @operationList = []
    @operationList << operation
  end

  def add(operation)
    @operationList << operation
  end

  def setScope(scope)
    @operationList.each { |operation| operation.setScope(scope)}
  end

  def eval
    @operationList.each { |operation|
      operation.eval
    }
    nil
  end

  #returns declarations of variables
  def getNewVariables
    scope = Hash.new(Struct::Variable.new(Datatyp.new(Inget), Inget.new))
    
    @operationList.each { |operation|
        if operation.getVariable.class == Variable
          datatype,name,expr = operation.getVariable.to_a
          scope[name] = Struct::Variable.new(datatype, expr)
      end
    }
    scope
  end

  #returns updates to already declared variables
  def getVariableUpdates
    updates = {}
    @operationList.each {|operation|
      if operation.getVariable.class == VariableUpdate
        var = operation.getVariable
        updates[var.getName] = var.getValue
      end
    }
    updates
  end
end
#### End of class Operationer

class Operation
  def initialize(stmt)
    #Seperate Variables as they are handled in a different way
    if stmt.class == Variable or stmt.class == VariableUpdate
      @stmt = Inget.new
      @var = stmt
    else
      @stmt = stmt
      @var = Inget.new
    end
  end

  def setScope(scope)
    @stmt.setScope(scope)
    @var.setScope(scope)
  end

  def eval
    return @stmt.eval()
  end

  def getVariable
    return @var
  end
end
#### End of class Operation

#The print class
class Skriv 
  def initialize(expr)
    @expr = expr
    @scope = 0
  end

  def setVariableList(variables)
    @@variables = variables
  end

  def setScope(newScope)
    @scope = newScope
    if @expr.class == Uttryck
      @expr.setScope(newScope)
    end
  end

  def eval
    expr = @expr
    if @expr.class == String #indicates a Variable call
       expr = @@variables.get(@expr, @scope)
    end
    if @expr.class == FunktionAnrop #need to setScope
      expr.setScope(@scope)
    end
    puts expr.eval
  end
end
#### End of class Skriv

class Text
  attr_accessor :datatype
  def initialize(value)
    @value = value
    @datatype = Datatyp.new(self.class)
  end
  def eval
    return @value
  end
end
#### End of class Text

class Uttryck
  attr_accessor :datatype
  def initialize(exprLh,operator,exprRh)     
    @exprLh = exprLh
    @operator = operator
    @exprRh = exprRh
    
    @scope = 0
    @datatype = Datatyp.new(Tal)
    @test = true
  end

  def setVariableList(variableList)
    @@variables = variableList
  end

  def setScope(scope)
    if @exprLh.class == Uttryck
      @exprLh.setScope(scope)
    end
    if @exprRh.class == Uttryck
      @exprRh.setScope(scope)
    end

    @scope = scope
  end

  def getTal
    #temp variables is used as we dont want to replace the expr with the variable-expr, only eval it for this instance of the class
    if @exprLh.class == String
      tempExprLh = @@variables.get(@exprLh, @scope)
    else
      tempExprLh = @exprLh
    end

    if @exprRh.class == String
      tempExprRh = @@variables.get(@exprRh, @scope)
    else
      tempExprRh = @exprRh
    end

    if @operator == "*"
      result = Tal.new(tempExprLh.eval * tempExprRh.eval)
    elsif @operator == "/"
      result = Tal.new(tempExprLh.eval / tempExprRh.eval)
    elsif @operator == "-"
      result = Tal.new(tempExprLh.eval - tempExprRh.eval)
    elsif @operator == "+"
      result = Tal.new(tempExprLh.eval + tempExprRh.eval)
    end
    
    result
  end

  def eval
    getTal.eval
  end
    
end
#### End of class Uttryck

class Tal
  attr_accessor :datatype
  
  def initialize(value)
    @value = value
    @datatype = Datatyp.new(self.class)
  end

  def eval
    @value
  end
end
#### End of class Tal

class Sanning
  attr_accessor :datatype

  def initialize(value)
    @bool = value
    @datatype = Datatyp.new(self.class)
  end

  def eval
    if @bool == 1
      return "sant"
    else
      return "falskt"
    end
  end
end
#### End of class Sanning

#The nil value
class Inget
  attr_accessor :datatype

  def initialize
    @datatype = Datatyp.new(self.class)
  end
  
  def setScope(scope)
    nil
  end
  
  def eval
    return "inget"
  end
end
#### End of class Inget

class Variable
  def initialize(datatype, name, expr)
    @datatype = datatype
    @name = name
    @expr = expr
    @scope = 0
  end

  def setScope(scope)
    @scope = scope
    if @expr.class == Uttryck
      @expr.setScope(scope)
    end
  end
  
  def to_a
    return [@datatype, @name, @expr]
  end

  def eval
    Inget.new
  end
end
#### End of class Variable

#Used for updating already declared variables
class VariableUpdate
  def initialize(name, expr)
    @name = name
    @expr = expr
  end

  def setScope(scope)
    if @expr.class == Uttryck
      @expr.setScope(scope)
    end
  end

  def getValue
    return @expr
  end

  def getName
    return @name
  end
end
#### End of class VariableUpdate

#Handles all the variables
class VariableList
  attr_accessor :currentScope, :prevScope

  def initialize
    #Create struct
    Struct.new("Variable", :datatype, :expr)

    #Set standard value to hash
    globalScope = Hash.new(Struct::Variable.new(Datatyp.new(Inget), Inget.new))

    @scopes = {}
    @scopes[0] = globalScope
  end
  
  #Adds a Variable of the given data to given scope
  def add(datatype, name, expr, scope)
    @scopes[scope][name] = Struct::Variable.new(datatype, expr)
  end

  def updateVariable(name, expr, scope)
    #Does the variable exist on given scope?
    if @scopes[scope][name] != nil
      if expr.class == String
        expr = get(expr, scope)
      end

      if @scopes[scope][name].datatype.isValid(expr)
        if expr.class == Uttryck
          expr = expr.getTal
        end
        @scopes[scope][name].expr = expr

      else
        puts "Går ej tilldela variabel #{name} datatyp #{expr.class} då den är av datatyp #{@scopes[scope][name].expr.class}"
      end
      
    #Does the variable exist on global scope?
    elsif @scopes[0][name] != nil
      if @scopes[0][name].datatype.isValid(expr)
        @scopes[0][name].expr = expr
      else

        puts "Går ej tilldela variabel #{name} datatyp #{expr.class} då den är av datatyp #{@scopes[0][name].expr.class}"
      end

    else
      puts "Variabel #{name} är ej deklarerad, kan inte tilldela värde"
    end
  end

  def get(name, scope)
    #variable on given-scope/global-scope
    if @scopes[scope][name] != nil
      return @scopes[scope][name].expr
    else
      return @scopes[0][name].expr
    end
  end

  def addScope(scope, variables)
    @scopes[scope] = Hash.new(Struct::Variable.new(Datatyp.new(Inget), Inget.new))
    @scopes[scope] = variables
  end
end
#### End of class VariableList

class Datatyp
  attr_accessor :classType

  def initialize(classType)
    @classType = classType
  end

  def isValid(x)
    if x.class == FunktionAnrop
       return true
    end

    x.datatype.classType == @classType
  end
end
#### End of class Datatyp

class Funktion
  def initialize(name, operationList, datatype, returnExpr, parameterList, scope, variableUpdates)
    @name = name
    @operationList = operationList
    @datatype = datatype
    @returnExpr = returnExpr
    @parameterList = parameterList
    @scope = scope
    
    if variableUpdates.class != Inget
      @variableUpdates = variableUpdates
    else
      @variableUpdates = {}
    end
  end

  def getName
    @name
  end

  def getScope
    @scope
  end

  def getParameterList
    @parameterList
  end

  def getVariableUpdates    
    @variableUpdates
  end

  def eval
    @operationList.eval
    if @returnExpr.class == Struct::Variable
      @returnExpr.expr.eval
    else
      @returnExpr.eval
    end
  end
end
#### End of class Funktion

class FunktionAnrop
  
  def initialize(funcName,argList)
    @funcName = funcName
    @scope = 0
    @arguments = argList.getArguments
  end
  
  def setVariableList(variables)
    @@variables = variables
  end
  
  def setScope(scope)
    @scope = scope
  end

  def eval
    func = @@variables.get(@funcName, @scope) 
    
    #Update parameters with the arguments
    if func.getParameterList.class != Inget
      func.getParameterList.getNumbers.each {|name,number|
        value = @arguments[number]
        datatype = func.getParameterList.getParameters[name].datatype
        @@variables.updateVariable(name, value, func.getScope)
      }
    end

    #Make sure all variables is updated
    func.getVariableUpdates.each{|name,expr|
      @@variables.updateVariable(name,expr,func.getScope)
    }
    return func.eval
  end
end
#### End of class FunktionAnrop

class ParameterLista
  def initialize(datatype, name)
    @variables = {}
    @numbers = {}
    @counter = 0

    @numbers[name] = @counter
    @variables[name] = Struct::Variable.new(datatype, Inget.new)
  end
  
  #Each parameter gets paired with a number to be able to match the arguments later
  def add(datatype, name)
    @counter += 1
    @numbers[name] = @counter
    @variables[name] = Struct::Variable.new(datatype, Inget.new)
  end

  def getNumbers
    @numbers
  end

  def getParameters
    @variables
  end
end
#### End of class ParameterLista

class ArgumentLista
  def initialize(arg)
    @counter = 0
    @arguments = {}

    if arg.class != Inget
      @arguments[@counter] = arg
    end
  end
  
  #Each argument gets paired with a number to be able to match the parameters later
  def add(arg)
    @counter += 1
    @arguments[@counter] = arg
  end

  def getArguments
    return @arguments
  end
end
#### End of class ArgumentLista

class Scope
  attr_accessor :currentScope, :prevScope

  def initialize
    @scopeList = {}
    @scopeList[0] = 0 #pair the scopes with its previous scope
    @scope = 0
    @prevScope = 0
    @highestScope = 0
  end

  #returns a unique scope
  def getNewScope
    @prevscope = @scope
    @highestScope += 1
    @scope = @highestScope
    @scopeList[@scope] = @prevScope

    @scope
  end

  def closeScope
    @scope = @prevscope
    @prevscope = @scopeList[@prevScope]
  end
end
#### End of class Scope

class Jamforelse
  attr_accessor :datatype
  
  def initialize(exprLh, rOperator, exprRh)
    @exprLh = exprLh
    @rOperator = rOperator
    @exprRh = exprRh
    @scope = 0

    #Jamforelse is a valid value for Sanning datatype
    @datatype = Datatyp.new(Sanning)
  end

  def setVariableList(variableList)
    @@variables = variableList
  end

  def setScope(scope)
    @scope = scope
  end
  
  def eval
    value = false
    tempExprLh = @exprLh
    tempExprRh = @exprRh

    #temp variables is used as we dont want to replace the expr with the variable-expr, only eval it for this instance of the class
    if @exprLh.class == String
      tempExprLh = @@variables.get(@exprLh, @scope)
    end
    if @exprRh.class == String
      tempExprRh = @@variables.get(@exprRh, @scope)
    end
    
    if @rOperator == "<" 
      if tempExprLh.eval < tempExprRh.eval 
        value = true
      end
    elsif @rOperator == "<="
      if tempExprLh.eval <= tempExprRh.eval 
        value = true
      end
    elsif @rOperator == ">"
      if tempExprLh.eval > tempExprRh.eval
        value = true
      end
    elsif @rOperator == ">="
      if tempExprLh.eval >=tempExprRh.eval 
        value = true
      end
    elsif @rOperator == "=="
      if tempExprLh.eval == tempExprRh.eval 
        value = true
      end
    elsif @rOperator == "!="
      if tempExprLh.eval != tempExprRh.eval 
        value = true
      end
    end
    return value
  end
end
#### End of class Jamforelse

class OmJamforelse
  def initialize(jamforelse,operationer)
    @om = [jamforelse, operationer]
    @annarsOm = Inget.new
    @annars = Inget.new
    @scope = 0
  end

  def setAnnars(operationList)
    @annars = operationList
  end

  def setAnnarsOm(operationList)
    @annarsOm = operationList
  end

  def setScope(scope)
    @scope = scope
    @om[0].setScope(scope)

    if @annarsOm.class != Inget
      @annarsOm.each {|jamforelse,_| jamforelse.setScope(scope) }
    end
    if @annars.class != Inget
      @annars.setScope(scope)
    end
  end

  def setVariableList(variables)
    @@variables = variables
  end

  def eval
    #Variable-call
    if @om[0].class == String
      @om[0] = @@variables.get(@om[0], @scope)
    end
    
    #Update the variables and do eval
    allFalse = true
    #if
    if @om[0].eval == true
      @om[1].getVariableUpdates.each {|name,expr|
        @@variables.updateVariable(name,expr,@scope)
      }
      allFalse = false
      @om[1].eval

    #elseif
    elsif @annarsOm.class != Inget
      @annarsOm.reverse.each {|jamforelse,operationer|
        if jamforelse.eval == true
          operationer.getVariableUpdates.each {|name,expr|
            @@variables.updateVariable(name,expr,@scope)
          }

          allFalse = false
          operationer.eval
        end

        if !allFalse
          break
        end
      }
    end
    
    #else
    if allFalse == true
      if @annars.class != Inget
        @annars.getVariableUpdates.each {|name,expr|
          @@variables.updateVariable(name,expr,@scope)
        }
        @annars.eval
      end
    end
  end
end
#### End of class OmJamforelse

class MedansJamforelse
  def initialize(jamforelse,operationer)
    @medans = [jamforelse, operationer]
    @scope = 0
  end

  def setScope(x)
    @scope = x
    @medans[0].setScope(x)
    @medans[1].setScope(x)
  end

  def setVariableList(x)
    @@variables = x
  end

  def eval
    #Update variables and do evals
    while @medans[0].eval
       @medans[1].getVariableUpdates.each {|name,expr|
        @@variables.updateVariable(name,expr,@scope)
      }
      @medans[1].eval
    end
  end
end
#### End of class MedansJamforelse
