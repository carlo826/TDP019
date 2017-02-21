# -*- coding: utf-8 -*-

@@variables = [{}] # alla variabler sparas ner med ett värde
@@func = {} # alla funktionsnamnen sparas ner med en funktionsnod som värde
@@func_vars = {} # parametrar i funktioner sparas ner tillfälligt
@@scope = 0 # indikerar vilket index vi bör använda i @@variables
@@return = nil # har koll på ifall en funktion har en retursats

@@type_hash = {String => "sträng", Fixnum => "heltal", 
  Bignum => "heltal", Float => "flyttal", TrueClass => "bool", FalseClass => "bool", Array => "lista"}
@@type_value = {"sträng" => "", "heltal" => 0, "flyttal" => 0.0, "bool" => "sant", "lista" => []}


def open_scope
  @@scope +=1
  @@variables.push({})
end

def close_scope
  @@variables.pop
  @@scope-=1
  if @@scope < 0
    abort("Någonstans i koden har det blivit brutalt fel!")
  end
end


def look_up(var, hash)
  if hash == @@func_vars
    hash[var]
  elsif hash == @@variables
    i = @@scope
    while(i>=0)
      if @@variables[i][var] != nil
        return @@variables[i][var]
      end
      i-= 1
    end
    if @@variables[0][var] == nil
      abort("ERROR: Variabeln \'#{var}\' finns inte!")
    end
  end
end

class Stmt_node
  attr_accessor :stmt, :stmts
  def initialize(stmts)
    @stmts = stmts
  end

  def eval ()
    @stmts.each do |statement|
      statement.eval
    end
  end
end


class Print_node
  attr_accessor :value
  def initialize(value)
    @print = value
  end
  def eval()
    puts @print.eval
  end
end


class Return_node
  attr_accessor :expr
  def initialize (expr)
    @expr = expr
  end
  def eval()
    return @expr.eval
  end
end


class Variable_node              
  attr_accessor :name
  def initialize(id)
    @name = id
  end
  def eval()
    i = @@scope
    if @@func_vars.has_key?(@name) == true
      return look_up(@name, @@func_vars)
    else
      return look_up(@name, @@variables)
    end
  end
end


class Atom_node              
  attr_accessor :value
  def initialize (value)
    @value = value
  end
  def eval()
    return @value
  end
end


class StartAssign_node
  attr_accessor :var, :expr
  def initialize(type, var, expr = nil)
    @type = type
    @var = var
    @expr = expr
  end
  def eval()
    if @expr != nil
      varde = @expr.eval
    else
      varde = @@type_value[@type]
    end
    i = @@scope

    if @@variables[i].has_key?(@var.name)
      abort("ERROR: Variabeln finns redan!")
    else
      if (@type == 'bool') and (varde == 'sant' or varde == 'falskt')
        @@variables[i][@var.name] = varde
      else
        if @@type_hash[varde.class] == @type
          @@variables[i][@var.name] = varde
        else
          abort("ERROR: Värdet stämmer inte överrens med typen.")
        end
      end
    end
  end
end


class Assign_node
  attr_accessor :var, :op, :expr
  def initialize(var, op, expr)
    @var=var
    @op = op
    @expr = expr
  end
  def eval()
    if @expr == nil
      varde = 1
    else
      varde = @expr.eval
    end

    i = @@scope
    while(i>=0)
      if @@variables[i][@var.name] != nil
        hash = @@variables[i]
      end
      i-= 1
    end
    if hash == nil
      abort ('ERROR: Variabeln \'#{@var.name}\' finns inte!')
    end
    
    if (@var.eval.class == String and (varde.class == String or varde.class == Fixnum)) then
      case @op
      when '*='
        hash[var.name] *= varde
      when '+='
        hash[var.name] += varde
      when '='
        hash[var.name] = varde
      end
    elsif (@var.eval.class == Fixnum and 
           (varde.class == Fixnum or
            varde.class == Bignum or 
            varde.class)) or
        (@var.eval.class == Bignum and 
         (varde.class == Fixnum  or 
          varde.class == Bignum  or 
          varde.class)) or 
        (@var.eval.class == Float and 
         (varde.class == Fixnum or 
          varde.class == Bignum  or 
          varde.class or 
          varde.class == Float)) then
      case @op
      when '*='
        hash[var.name] *= varde
      when '/='
        hash[var.name] /= varde
      when '+='
        hash[var.name] += varde
      when '-='
        hash[var.name] -= varde
      when '='
        hash[var.name] = varde
      when '++'
        hash[var.name] += varde
      when '--'
        hash[var.name] -= varde
      end
    else
      abort ("ERROR: variabeln #{var.name} finns inte eller är fel typ. (#{varde.class})")
    end
  end
end

class Expr_node
  attr_accessor :operator, :operand1, :operand2
  def initialize(op, op1, op2)
    @operator = op
    @operand1 = op1
    @operand2 = op2
  end
  def eval()
    case @operator
    when '+'
      return @operand1.eval + @operand2.eval 
    when '-'
      return @operand1.eval - @operand2.eval
    when '*'
      return @operand1.eval * @operand2.eval 
    when '/'
      return @operand1.eval / @operand2.eval
    when '%'
      return @operand1.eval % @operand2.eval
    when '&'
      return @operand1.eval + @operand2.eval
    when '<'
      return t_or_f(@operand1.eval < @operand2.eval) 
    when '>'
      return t_or_f(@operand1.eval > @operand2.eval) 
    when '<='
      return t_or_f(@operand1.eval <= @operand2.eval) 
    when '>='
      return t_or_f(@operand1.eval >= @operand2.eval) 
    when '!='
      return t_or_f(@operand1.eval != @operand2.eval)
    when '=='
      return t_or_f(@operand1.eval == @operand2.eval)
    when 'och'
      return t_or_f(@operand1.eval && @operand2.eval)
    when 'eller'
      return t_or_f(@operand1.eval || @operand2.eval)
    else nil
    end
  end

  def t_or_f(var)
    if var == true or var == "sant"
      return "sant"
    else
      return "falskt"
    end
  end
end



class Array_node
  attr_accessor :array
  def initialize (array)
    @array = array
  end
  def eval()
    i = 0
    size = @array.size
    while(i<size)
      @array[i] = @array[i].eval
      i += 1
    end
    return @array
  end
end



class Array_index_node 
  def initialize(array_name, index)
    @array_name  = array_name
    @index = index
  end
  def eval
    var = look_up(@array_name.name,@@variables)
    value = var[@index.eval]
    return value
  end
  
end

class Array_add_node
  def initialize(array_name,item)
    @array_name = array_name
    @item = item
  end
  def eval
    array = look_up(@array_name.name,@@variables)
    array << @item.eval
    @@variables[@@scope][@array_name.name] = array
  end
end

class Array_size_node
  def initialize(array_name)
    @array_name  = array_name
	end
  def eval
    array = look_up(@array_name.name,@@variables)
    return array.size
  end
end

class Array_remove_index_node
  def initialize(array_name,index)
    @array_name  = array_name
    @index = index
  end
  def eval
    array = look_up(@array_name.name,@@variables)
    if array.delete_at(@index.eval) == nil
      abort ('ERROR: Detta index finns inte i listan!')
    end
    @@variables[@@scope][@array_name.name] = array
  end
end

class Array_remove_value_node
  def initialize(array_name,value)
    @array_name  = array_name
    @value = value
  end
  def eval
    array = look_up(@array_name.name,@@variables)
    if array.include?(@value.eval)
      array.delete(@value.eval)
    else
      abort ('ERROR: Listan innehåller inte det värdet!')
    end
    @@variables[@@scope][@array_name.name] = array
  end
end




class For_node      
  attr_accessor :decl,:pred,:assign,:stmts
  def initialize (decl,pred,assign,stmts)
    @decl = decl
    @pred = pred
    @assign = assign
    @stmts = stmts
  end
  def eval()
    open_scope()
    @decl.eval
    while (@pred.eval) == "sant" do
      @stmts.each do |stmt|
        if stmt.class == Return_node
          @@return = stmt.eval
          break
        else
          stmt.eval
        end
      end
      @assign.eval
    end
    close_scope()
  end
end


class While_node
  attr_accessor :pred, :stmts
  def initialize (pred, *stmts)
    @pred = pred
    @stmts = stmts
  end

  def eval()
    open_scope()
    while (@pred.eval) == "sant" do

      @stmts.each do |stmt|
        if stmt.class == Return_node
          @@return = stmt.eval
          break
        else
          stmt.eval
        end
      end
    end
    close_scope()
  end
end


class If_block_handler       
  attr_accessor :pred, :satser
  def initialize(pred, satser)
    @pred = pred
    @satser = satser
  end
  def eval()
    return nil
  end
end

class If_node    
  attr_accessor :satser2
  def initialize(satser2)
    @satser2 = satser2
  end
  def eval()
    open_scope()
    @satser2.each do |stmts|
      if stmts.pred.eval == "sant" then
        stmts.satser.each do |stmt|
          if stmt.class == Return_node
            @@return = stmt.eval
          else
            stmt.eval
          end
        end
        break
      end
    end
    close_scope()
  end
end


class Function_node              
  attr_accessor :type,:func_name,:parameters,:statements
  def initialize(type,name,para,satser)
    @type = type
    @func_name = name
    @parameters = para
    @satser = satser
  end
  
  def eval()
    if not @@func.has_key?(@func_name.name)
      @@func[@func_name.name] = self
    else
      abort ("ERROR: Funktionen \"#{@func_name.name}\" finns redan!")
    end
  end

  def get_values()
    return @satser,@parameters,@type
  end
end

class Function_call_node
  attr_accessor :name, :arguments
  def initialize(name,args)
    @name = name
    @args = args
  end
  def eval()
    if not @@func.has_key?(@name.name) then
      abort ("ERROR: Funktionen #{@name.name} finns inte.")
    end
    
    @satser , @parameters, @type = @@func[@name.name].get_values()

    if (@args == nil or @parameters == nil) and (@args != nil or @parameters != nil)
      abort ("ERROR: Antingen saknas parametrar eller argument!")
    end
    if @args != nil and @parameters != nil
      if @args.size() != @parameters.size() then
        abort ("ERROR: Antal parametrar stämmer inte överens. (#{@args.size} av #{@parameters.size})")
      end

      open_scope()

      i = 0
      size = @args.size()
      while i < size
        if @args[i].class == Variable_node
          if @@variables[@@scope-1].has_key?(@args[i].name)
            value = @@variables[@@scope-1][@args[i].name]
            @@variables[@@scope][@parameters[i].name] = value
          end
        else
          @@variables[@@scope][@parameters[i].name] = @args[i].eval
        end
        i +=1
      end
    end
    
    @satser.each do |stmt|
      if stmt.class == Return_node
        @@return = stmt.eval
        break
      else
        stmt.eval
      end
    end

    close_scope()

    if @@return == nil
      abort ('ERROR: Det finns ingen retursats!')
    else
      if @@type_hash[@@return.class] != @type
        abort ('ERROR: Retursatsen finns men är inte av rätt typ!')
      else
        ret = @@return
        @@return = nil
        return ret
      end
    end
  end
end
