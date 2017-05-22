require_relative 'data_handler'
require_relative 'error_thrower'

@@error_thrower = ErrorThrower.new
@@data_handler = DataHandler.new(@@error_thrower)
@@scope_counter = 0

class Program
  def initialize(global_block)
    #Varje scope är en nyckel till en hash där alla
    #variabler deklarerade i det scopet finns.

    #Varje nod har en funktion set_scope
    #Noder som öppnar scope pushar scope_counter
    #till det nuvarande scopet, går igenom alla noder
    #i sitt block och kallar på deras set_scope
    #sedan ökas scope_counter med 1 och det nuvarande
    #scopet poppas.

    #Detta leder till att det blir ganska enkelt att
    #öka "uppåt" i scope-hierarkin efter en variabel.
    #Man behöver bara ange det scopet sökningen startar i
    #och variabelnamnet man letar efter.

    global_block.each do |statement|
      statement.set_scope([0])
    end
    #Sedan evaluera
    global_block.each do |statement|
      statement.evaluate
    end
    #@@data_handler.draw_scopes
  end
end


class Var_decl
  attr_reader :name, :value
  def initialize(name, expression)
    @name = name
    @expression = expression
  end
  def set_scope(scope)
    @my_scope = scope.dup
    @expression.set_scope @my_scope
  end
  def evaluate
    @value = @expression.evaluate
    @@data_handler.declare_var_in_scope(@name, @value, @my_scope)
  end
end

class Task_decl
  def initialize(name, block, param_list = [])
    @name = name
    @block = block
    @param_list = param_list
  end
  def set_scope(scope)
    scope.push(@@scope_counter)
    @my_scope = scope.dup
    @block.each do |statement|
      statement.set_scope(scope)
    end
    @@scope_counter += 1
    scope.pop
  end
  def evaluate()
    @@data_handler.try_add_task(@name, @param_list, @block, @my_scope.dup)
  end
end

class Arg_list
  def initialize(arg_list)
    @arg_list = arg_list
  end
  def set_scope(scope)
    @my_scope = scope.dup
    @arg_list.each do |expression|
      expression.set_scope @my_scope
    end
  end
  def evaluate
    evaluated_args = []
    @arg_list.each do |expression|
      evaluated_args.push(expression.evaluate)
    end
    evaluated_args
  end
end

class Call_stmt
  def initialize(task_to_call, arg_list = nil)
    @task_to_call = task_to_call
    @arg_list = arg_list
  end
  def set_scope(scope)
    @my_scope = scope.dup
    if !@arg_list.nil?
      @arg_list.set_scope @my_scope
    end
  end
  def evaluate
    if !@arg_list.nil?
      @@data_handler.try_call_task(@task_to_call, @arg_list.evaluate)
    else
      @@data_handler.try_call_task(@task_to_call, [])
    end
  end
end

#En condition_chain består av antingen en if-sats, eller en vanlig följd av elif / else satser.
#När en ett contition_statement returnerar sant, dvs när den gick in där så breakar vi loopen.
#Så fort koden går in i en elif-sats är ju alla condition-statements efteråt ointressanta.

#En rad av if-satser är alltså flera individuella condition-chains, vilket leder till att även om koden går in i en
#if-sats så kommer den även kolla i efterföljande if-satser.
class Condition_chain
  def initialize(condition_stmts)
    @condition_stmts = condition_stmts
  end
  def set_scope(scope)
    @condition_stmts.each do |condition_stmt|
      condition_stmt.set_scope(scope)
    end
  end
  def evaluate
    @condition_stmts.each do |condition_stmt|
       if condition_stmt.evaluate
         break
       end
    end
  end
end


class Condition_stmt
  def initialize(block, bool_expr = nil)
    @block = block
    @bool_expr = bool_expr
  end

  def set_scope(scope)
    scope.push(@@scope_counter)
    if @bool_expr != nil
      @bool_expr.set_scope(scope)
    end
    @block.each do |statement|
      statement.set_scope(scope.dup)
    end
    @@scope_counter += 1
    scope.pop
  end

  def evaluate
    #Om det inte finns ett bool_expr (else) eller den bool_expr returnerar sant, kör evaluera blocket
    #och returnera true till condition_chain.
    if @bool_expr == nil || @bool_expr.evaluate
      @block.each do |statement|
        statement.evaluate
      end
      return true
    end
  end
end

class Out_stmt
  def initialize(expression)
    @expression = expression
  end
  def set_scope(scope)
    @my_scope = scope.dup
    @expression.set_scope @my_scope
  end
  def evaluate
    print "\n\t#{@expression.evaluate}\n"
  end
end

#Test-uttryck för att se om rino evaluerar uttryck korrekt.
class Expression_test
  def initialize(expected, expression)
    @expected = expected
    @expression = expression
  end
  def set_scope(scope)
    @my_scope = scope.dup
    @expression.set_scope @my_scope
  end
  def evaluate
    expected =  eval @expected
    value = @expression.evaluate
    if expected == value
      print "\n\tSuccess! The rino expression evaluated to the expected expression #{expected} (left).\n\n"
    else
      print "\n\tFail! The rino expression did not evaluate to the expected #{expected} (left)\n\tThe result was #{value}.\n\n"
    end
  end
end


class For_loop
  def initialize(iterator_decl, iterations_expr, step_expr = 1, block)
    @iterator_decl = iterator_decl
    @iterations_expr = iterations_expr
    @step_expr = step_expr
    @block = block
  end

  def set_scope(scope)
    scope.push(@@scope_counter)
    @my_scope = scope.dup
    @iterator_decl.set_scope(@my_scope)
    @iterations_expr.set_scope(@my_scope)
    @block.each do |statement|
      statement.set_scope(scope)
    end
    @@scope_counter += 1
    scope.pop
  end

  #Evaluerar alla uttryck och kollar så att step är korrekt.
  #Kör sedan loopen.
  def evaluate
    @iterator_decl.evaluate
    @iterator_name = @iterator_decl.name
    @iterator_value = @iterator_decl.value
    @iterations = @iterations_expr.evaluate
    @step = @step_expr.evaluate

    if @step < 1
      @@error_thrower.invalid_step_exception(@step)
    end

    (@iterator_value..@iterations-1).step(@step).each do
      @block.each do |statement|
         statement.evaluate
      end
      @@data_handler.iterate_variable(@iterator_name, @my_scope, @step)
    end
  end
end

class While_loop
  def initialize(bool_expr, block)
    @bool_expr = bool_expr
    @block = block
  end
  def set_scope(scope)
    scope.push(@@scope_counter)
    @my_scope = scope.dup
    @bool_expr.set_scope(@my_scope)
    @block.each do |statement|
      statement.set_scope(scope)
    end
    @@scope_counter += 1
    scope.pop
  end
  #Medans uttrycket är sant kör loopen.
  def evaluate
    while @bool_expr.evaluate
      @block.each do |statement|
        statement.evaluate
      end
    end
  end
end

#Antingen aritmetiskt eller booleanskt uttryck
class Expression
  def initialize (expressions)
    @expressions = expressions
  end
  def set_scope(scope)
    @my_scope = scope.dup
    @expressions.each do |expression|
      #Kolla så att uttrycket inte är en sträng, dvs tecken (+ / - / && / ||...) då har det ju ingen set_scope-metod.
      if !expression.is_a? String
        expression.set_scope(@my_scope)
      end
    end
  end

  #Evaluerar hela uttrycket.
  #Algorithmen är sådan att den först evaluerar det första uttrycket i listan och tar bort det,
  #Nästa "uttryck" är alltid en operator, så den evaluerar vi inte, men sparar och tar bort från listan.
  #Nästa uttryck vet vi är ett riktigt uttryck så det evalueras som vanligt och tas bort från listan.
  #Jag har nu två värden och en operator jag sätter det första värdet till operatorn och det andra värdet
  #"skickat" på det första värdet. Processen upprepas tills att listan är tom.

  #Exempel:
  #expression = 2*(5+1)-4

  #value sätt till vad som 2 evalueras till, vilket är 2 (den är av typen rino_int)
  #expression är nu *(5+1)-4

  #gå in i while-loop

  #operator sätts till *
  #expression är nu (5+1)-4

  #(5+1) är av denna typ DVS klassen Expression, det som händer är att det blir rekurssion

  #right_value kommer alltså att bli vad (5+1) evalueras till.

  #value = 5
  #operator = +
  #right_value = 1
  #value = 5.send(+, 1) -> 6
  #nu är listan (5+1) tom så value returneras till föregående Expression.

  #right_value = 6
  #value = 2.send(*, 6) -> 12

  #expression ser nu ut såhär: -4

  #operator = -
  #right_value = 4

  #value = 12.send(-, 4) -> 8

  #klart!

  def evaluate
    expressions = @expressions.dup

    #Tar uttrycket längst fram och evaluerar (shift är som pop fast tar bort på motsat sida av arrayen)
    value = expressions.shift.evaluate

    #Medans antalet uttryck i detta uttryck inte är 0
    while expressions.count != 0
      #Ta nästa sak i uttrycket, vilket är en operator.
      operator = expressions.shift

      #Hämtar evaluerar uttrycket på höger sida.
      right_value = expressions.shift.evaluate

      #Ganska självförklarande, sätter värdet till det högra värdet
      #med operatorn.
      value = value.send(operator, right_value)
    end
    value
  end
end

class Identifier
  attr_reader :name,:value
  def initialize(name, value = nil)
    @name = name
    @value = value
  end
  def set_scope(scope)
    #debug_print scope
    @my_scope = scope.dup
  end
  def evaluate
    @value = @@data_handler.try_find_first_occurance(@name, @my_scope.dup)
  end
end

class Rino_string
  def initialize(value)
    @value = value
  end
  def set_scope(scope)
    @my_scope = scope.dup
  end
  def evaluate
    @value[1..-2]
  end
end

class Rino_int
  def initialize(value)
    @value = value
  end
  def set_scope(scope)
    @my_scope = scope.dup
  end
  def evaluate
    @value
  end
end

class Rino_float
  def initialize(value)
    @value = value
  end
  def set_scope(scope)
    @my_scope = scope.dup
  end
  def evaluate
    @value
  end
end

class Rino_bool
  def initialize(value)
    @value = value
  end
  def set_scope(scope)
    @my_scope = scope.dup
  end
  def evaluate
    @value
  end
end
