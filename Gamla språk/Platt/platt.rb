# -*- coding: utf-8 -*-

require './rdparse'
require './node'


class Platt

  def initialize
    @plattParser = Parser.new("pLätt språk") do
      
      ####################### LEXER ##########################
      token(/\/\*(.|\n)*\*\//) # flerradskommentar matchas
      token(/\/\/(.)*$/) # enradskommentar matchas
      token(/\s+/) # blanksteg matchas
      token(/\d+[.]\d+/) {|m| m.to_f} # positiva floattal matchas
      token(/-(\d+[.]\d+)/) {|m|m.to_f} # negativa floattal matchas
      token(/\d+/) {|m| m.to_i } # positiva heltal matchas
      token(/"[^\"]*"/) {|m| m } # strängar i form av "innehåll" matchas
      token(/'[^\']*'/) {|m| m } # strängar i form av 'innehåll' matchas
      token(/ifall/) {|m| m } # 'ifall' satsen matchas
      token(/annars ifall/) {|m| m } # 'annars ifall' satsen matchas
      token(/annars/) {|m| m } # 'annars' satsen matchas
      token(/avsluta ifall/) {|m| m } # 'avsluta ifall' satsen matchas
      token(/returnera/) {|m| m } # returnera satsen matchas
      token(/skriv ut/) {|m| m } # 'skriv ut' satsen matchas
      token(/för/) {|m| m } # 'för' satsen matchas
      token(/avsluta för/) {|m| m } # 'avsluta för' satsen matchas
      token(/under tiden/) {|m| m } # 'under tiden' satsen matchas
      token(/avsluta under tiden/) {|m| m } # 'avsluta under tiden' satsen matchas
      token(/funktion/) {|m| m } # 'funktion' satsen matchas
      token(/avsluta funktion/) {|m| m } # 'avsluta funktion' satsen matchas
      token(/ta bort värde/) {|m| m } # 'ta bort värde' satsen matchas
      token(/ta bort index/) {|m| m } # 'ta bort index' satsen matchas
      token(/i/) {|m| m } # 'i' satsen matches
      token(/lägg till/) {|m| m } # 'lägg till' satsen matchas
      token(/storlek på/) {|m| m } # 'storlek på' satsen matchas
      token(/(\+=|-=|\*=|\/=|\+\+|--|\+|\-|\*|\/|!=|\.|,|\]|\[|{|}|\(|\)|\:|<=|>=|<|>|==|=)/) {|m| m} # enstaka specialtecken matchas
      token(/[a-zA-ZåäöÅÄÖ]+[a-zA-ZåäöÅÄÖ0-9_]*/) {|m| m} # variabler matchas      
      ###################### SLUT PÅ LEXER ###################

      
      #################### SATSER I SPRÅKET ###################
      
      start :program do
        match(:statements) {|stmts| Stmt_node.new(stmts)}
      end

      rule :statements do
        match(:statement) {|sats| sats }
        match(:statements, :statement) {|satser,sats| 
          satser += sats
          satser }
      end

      rule :statement do
        match(:array_add_element){|array_add|[array_add]}
        match(:array_remove_by_index){|array_remove_ele|[array_remove_ele]}
        match(:array_remove_by_value){|array_remove_value|[array_remove_value]}
        match(:return) {|ret| [ret] }
        match(:if_block) {|if_rule| [if_rule] }
        match(:loop) {|loop| [loop] }
        match(:print) {|print| [print] }
        match(:declare_func) {|declare_func| [declare_func] }
        match(:function_call) {|func| [func] }
        match(:declare_var) {|declare_var| [declare_var] }
        match(:assign) {|assign| [assign] }
      end
      #################### SLUT PÅ SATSER #####################
      
      
      #################### UTSKRIFT & VARIABLER ###############
      
      rule :print do
        match('skriv ut', :expr) {|_, print| 
          Print_node.new(print) }
      end
      
      rule :identifier do
        match(/[a-zA-ZåäöÅÄÖ]+[a-zA-ZåäöÅÄÖ0-9_]*/)  {|var| 
          Variable_node.new(var) }
      end

      rule :function_call do
        match(:identifier,'(',:arguments,')') {|name,_,args,_| 
          Function_call_node.new(name,args)}
        match(:identifier ,'(',')'){|name,_,_| 
          Function_call_node.new(name,nil)}		
      end

      rule :return do
        match('returnera',:expr){|_,expr| 
          Return_node.new(expr)}
      end

      ###################### SLUT PÅ UTSKRIFT & VARIABLER ####


      ################### DEKLARERA VARIABLER & FUNKTIONER ###

      rule :declare_var do
        match(:type, :identifier, '=', :array) {|type, var, _, array| 
          StartAssign_node.new(type,var,array) }
        match(:type, :identifier, '=', :expr) {|type, var, _, expr| 
          StartAssign_node.new(type,var,expr) }
        match('bool', :identifier, '=', :bool) {|type, var, _, bool| 
          StartAssign_node.new(type,var,bool) }
        match(:type, :identifier, '=', :string) {|type, var, _, str| 
          StartAssign_node.new(type,var,str) }
        match(:type, :identifier) {|type, var| 
          StartAssign_node.new(type, var)}
      end

      rule :declare_func do
        match(:type, 'funktion', :identifier, '(', :parameters, ')', 
              '{', :statements, '}', 
              'avsluta funktion') {|type, _, var, _, para, _, _, stmts, _, _| 
          Function_node.new(type, var, para, stmts) }
        match(:type, 'funktion', :identifier, '(', ')', '{', :statements, '}', 
              'avsluta funktion') {|type, _, var, _, _, _, stmts, _, _| 
          Function_node.new(type, var, nil, stmts) }
      end

      rule :assign do
        match(:identifier, '++') {|var, op| 
          Assign_node.new(var, op, Atom_node.new(1)) }
        match(:identifier, '--') {|var, op| 
          Assign_node.new(var, op, Atom_node.new(1)) }
        match(:identifier, :assign_operator, :expr) {|var, op, value| 
          Assign_node.new(var, op, value) }
        match(:identifier, :assign_operator, :string) {|var, op, str| 
          Assign_node.new(var, op, str) }
      end

      rule :assign_operator do
        match('*=') {|m| m }
        match('/=') {|m| m }
        match('+=') {|m| m }
        match('-=') {|m| m }
        match('=') {|m| m }
      end

      ############# SLUT PÅ VARIABLER & FUNKTIONER ###########

      ################ LOOPAR ################################

      rule :loop do
        match(:for_loop)
        match(:while_loop)
      end

      rule :for_loop do
        match('för', '(', :declare_var, ':', :pred_expr, ':', :assign, ')', 
              '{', :statements, '}', 
              'avsluta för') {|_, _, decl, _, pred, _, assign, _, _,stmts, _, _| 
          For_node.new(decl, pred, assign, stmts) }
      end

      rule :while_loop do
        match('under tiden', '(', :pred_expr, ')', 
              '{', :statements, '}', 
              'avsluta under tiden') {|_, _, pred, _, _, stmts, _, _| 
          While_node.new(pred, stmts) }
      end

      #################### SLUT PÅ LOOPAR ####################

      #################### IF SATSER #########################

      rule :if_block do
        match(:if_rule){|if_stmts| 
          If_node.new(if_stmts)}
      end


      rule :if_rule do
        match(:if, :else_if, :else_, 'avsluta ifall'){|ifstmt, elsestmt, else_ , _| 
          [ifstmt] + elsestmt + [else_] }
        match(:if, :else_, 'avsluta ifall'){|ifstmt, else_, _| 
          [ifstmt] + [else_] }
        match(:if, :else_if, 'avsluta ifall'){|ifstmt, elsestmt, _| 
          [ifstmt] + elsestmt }
        match(:if, 'avsluta ifall'){|ifstmt, _| 
          [ifstmt] }
      end

      rule :if do
        match('ifall', '(', :pred_expr , ')', 
              '{', :statements, '}') {|_, _, pred, _, _,satser, _| 
          If_block_handler.new(pred,satser)}
      end

      rule :else_if do
        match('annars ifall', '(', :pred_expr , ')', 
              '{', :statements, '}'){|_, _, pred, _, _, satser, _| 
          [If_block_handler.new(pred,satser)] }
        match(:else_if, :else_if) {|else_if, else_if2| 
          else_if += else_if2 }
      end

      rule :else_ do
        match('annars', '{', :statements, '}') {|_, _, satser, _|
          a = Expr_node.new("<", Atom_node.new(1),Atom_node.new(2))
          If_block_handler.new(a,satser) }
      end

      ############### SLUT PÅ IF SATSER ##########################

      rule :parameters do
        match(:parameter) {|para| 
          [para]}
        match(:parameters, ',', :parameter) {|paras, _, para| 
          paras+ [para]}
      end
      
      rule :parameter do
        match(:identifier)
      end

      rule :arguments do
        match(:argument) {|arg| 
          [arg]}
        match(:arguments, ',', :argument) {|args, _, arg| 
          args+ [arg]}
      end

      rule :argument do
        match(:expr)
      end

      rule :type do
        match('heltal') 
        match('flyttal')
        match('sträng') 
        match('bool')
        match('lista')
      end

      rule :expr do
        match(:array_indexing)
        match(:array_size)
        match(:pred_expr)
        match(:addition_expr)
        match(:string)
        match(:array)
      end

      rule :pred_expr do
        match(:logic_expr)
        match(:rel_expr)
      end

      rule :logic_expr do
        match(:bool)
        match(:logic_operand, :logic_operator, :logic_expr)
        match(:logic_operand, :logic_operator, :logic_operand) {|op1, op, op2| 
          Expr_node.new(op, op1, op2) }
      end

      rule :logic_operand do
        match(:rel_expr)
        match(:bool)
      end

      rule :logic_operator do
        match('och')
        match('eller')
      end

      rule :rel_expr do
        match(:rel_operand, :rel_operator, :rel_operand) {|op1, op, op2| 
          Expr_node.new(op, op1, op2) }
      end

      rule :rel_operand do
        match(:addition_expr)
      end

      rule :rel_operator do
        match('>=')
        match('<=')
        match('>') 
        match('<') 
        match('==')
        match('!=')
      end
      
      rule :addition_expr do
        match(:addition_expr, :addition_operand, :multi_expr) {|op1, op, op2| 
          Expr_node.new(op, op1, op2) }
        match(:multi_expr)
      end

      rule :addition_operand do
        match('+')
        match('-')
      end

      rule :multi_expr do
        match(:multi_expr, :multi_operand, :multi_expr) {|op1, op, op2| 
          Expr_node.new(op, op1, op2) }
        match(:aritm_brackets)
      end

      rule :multi_operand do
        match('*')
        match('/')
      end


      rule :aritm_brackets do
        match('(', :expr, ')') {|_, expr, _| 
          expr }
        match(:string)
        match(:int)
        match(:float)
        match(:function_call)
      end

      rule :int do
        match(Integer) {|int| 
          Atom_node.new(int.to_i)}
        match('-', Integer) {|_, int| 
          Atom_node.new(-int.to_i)}
      end

      rule :float do
        match(Float) {|float| 
          Atom_node.new(float.to_f) }
        match('-', Float) {|_, float| 
          Atom_node(-float.to_f) }
      end
      
      rule :string do
        match(/"[^\"]*"/) {|str| 
          Atom_node.new(str.slice(1,str.length-2))}
        match(/'[^\']*'/) {|str| 
          Atom_node.new(str.slice(1,str.length-2))}
        match(:function_call)
        match(:identifier)
      end

      rule :bool do
        match('sant') 
        match('falskt')
      end

      rule :array do
        match('[',:array_values,']'){|_,array,_| 
          Array_node.new(array)}
      end

      rule :array_values do
        match(:array_values,',',:string){|exprs,_,string| 
          exprs+[string]}
        match(:array_values,',',:expr){|exprs,_,expr| 
          exprs+[expr]}
        match(:string){|expr| 
          [expr]}
        match(:expr){|expr| 
          [expr]}
      end


      rule :array_size do
        match('storlek på',:identifier){|_,array| 
          Array_size_node.new(array)}
      end

      rule :array_indexing do
        match(:identifier ,'[',:int,']'){|array,_,index,_| 
          Array_index_node.new(array,index)}
      end

      rule :array_add_element do
	match('lägg till',:string, 'i', :identifier){|_,string, _, array| 
          Array_add_node.new(array,string)}
        match('lägg till',:expr, 'i', :identifier){|_,expr,_,array| 
          Array_add_node.new(array,expr)}
      end

      rule :array_remove_by_index do
        match('ta bort index',:int, 'i', :identifier){|_,index, _, array| 
          Array_remove_index_node.new(array,index)}
      end

      rule :array_remove_by_value do
	match('ta bort värde',:string, 'i', :identifier){|_,value, _, array| 
          Array_remove_value_node.new(array,value)}
        match('ta bort värde',:expr, 'i', :identifier){|_,value, _, array| 
          Array_remove_value_node.new(array,value)}
      end

    end
  end
  
  def done(str)
    ["quit","exit","bye",""].include?(str.chomp)
  end
  

  def start_manually
    print "[pLätt] "
    str = gets
    if done(str) then
      puts "Bye."
    else
      result = @plattParser.parse(str)
      result.eval
      start_manually
    end
  end
    
  def start_with_file(file)
    result = Array.new()
    file = File.read(file)
    result = @plattParser.parse(file)
    result.eval
  end


  def log(state = true)
    if state
      @plattParser.logger.level = Logger::DEBUG
    else
      @plattParser.logger.level = Logger::WARN
    end
  end
end


if ARGV.length == 1
  filename = ARGV[0]
  if File.exist? filename
    p = Platt.new
    p.log(false)
    p.start_with_file(filename)
  else
    puts "Filen #{filename} finns inte."
  end
else
  p = Platt.new
  p.log(false)
  p.start_manually
end
