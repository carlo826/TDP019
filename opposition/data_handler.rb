#För min skull när jag debuggar saker.
def debug_print(*msgs)
  print("\n\tDEBUG LOGIC PRINT:")
  msgs.each do |msg|
    print("\n\t#{msg}")
  end
  print("\n\n")
end

#Klass som hanterar all kommunikation med datastrukturerna tasks och variables. Tasks är en hash med namnet på tasken som nyckel
#Värde är array med parameter-lista, block, och taskens scope.
class DataHandler
  def initialize(error_thrower)
    @error_thrower = error_thrower
    @tasks = {}
    @variables = {[0] => []}
  end

  #Försöker kalla på en task.
  def try_call_task(task_to_call, arg_list = [])
    #Om den ens finns:
    if @tasks.has_key? task_to_call
      candidate = @tasks[task_to_call]
      param_list = candidate[0]
      #Om parameter-listan matchar med argument-listan
      if param_list.count == arg_list.count
        block = candidate[1]
        task_scope = candidate[2].dup
        #Deklarerar argumenten i taskens scope.
        for i in 0..param_list.count - 1
          declare_var_in_scope(param_list[i], arg_list[i], task_scope)
        end
        #Evaluerar tasken.
        block.each do |statement|
          statement.evaluate
        end
      else
        @error_thrower.invalid_arg_list_size_exception(caller.task_to_call, item.param_list, caller.arg_list)
      end
    else
      @error_thrower.task_not_found_exception(task_to_call)
    end
  end
  #Försöker lägga till en ny task.
  def try_add_task(name, param_list, block, scope)
    #Om den namnet inte finns lägg till.
    if !@tasks.has_key? name
      @tasks[name] = [param_list]+[block]+[scope]
    else
      #Annars kasta undantag
      @error_thrower.task_name_occupied_exception(name)
    end
  end

  #Deklerar en variabel
  def declare_var_in_scope(name, value, scope)
    #Hämta alla nåbara variabler från scopet som denna deklareras i
    vars = get_reachable_vars(scope.dup)
    #Skriv över en likadan hittas.
    vars.each do |pair|
      if pair[0] == name
        pair[1] = value
      end
    end
    #Kolla om detta scope är definierat i datastrukturen, om sant, pusha.
    if @variables.has_key? scope
      @variables[scope].push([name] + [value])
    else
      #Annars skapa ny.
      @variables[scope] = [[name] + [value]]
    end
  end

  #Hämtar alla nåbara variabler från ett scope.
  def get_reachable_vars(scope)
    reachable_vars = []
    while scope != []
      if @variables[scope] == nil
        scope = find_next_populated_scope(scope.dup)
      end
      reachable_vars += @variables[scope]
      scope.pop
    end
    reachable_vars
  end

  #Hittar det nästa scopet som det finns variabler deklarerade i.
  def find_next_populated_scope(scope)
    while @variables[scope] == nil
      scope.pop
    end
    scope
  end

  #Hittar första förekomsten av en variabel, används när man använder en variabel i ett uttryck.
  def try_find_first_occurance(name, scope)
    while scope != []
      #Om vi kommer till ett tomt scope, t.ex. i en nestling av if-satser där det i den föregående if-satsen
      #inte finns någon variabel deklarerat så letar vi efter nästa scope med variabler i.
      if @variables[scope] == nil
        scope = find_next_populated_scope(scope.dup)
      end
      #Går igenom scopet och returnerar värdet på variabeln om namnet överenstämmer.
      @variables[scope].each do |pair|
        if pair[0] == name
          return pair[1]
        end
      end
      scope.pop
    end
    #Om ingen variabel hittades kasta undantag.
    @error_thrower.var_not_found_exception(name)
    nil
  end

  #Iterarer en variabel, används i for - loop
  def iterate_variable(name, scope, step)
    var = try_find_first_occurance(name, scope)
    declare_var_in_scope(name, var+=step, scope)
  end

  #Skriver ut datastrukturen
  def draw_scopes
    @variables.each do |key, value|
      tabs = "\t"*key.count
      print("\n#{tabs}Scope #{key}:\n")
      value.each do |var|
        print("#{tabs} #{var}\n")
      end
    end
    print("\n")
  end
end