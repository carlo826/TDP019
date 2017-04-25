#!/usr/bin/env ruby
require './rdparser.rb'
#Made in ruby version 1.8.7

class TTT
  def initialize
    @TTTParser = Parser.new("TTT") do
      token(/\s+/)
      token(/\t+/)
      token(/#.*\/#/)
      token(/TRUE/) {|m| m }
      token(/STR/) {|m| m}
      token(/NUM/) {|m| m}
      token(/FALSE/) {|m| m }
      token(/\IF/) {|m| :IF }
      token(/\ELSE/) {|m| :ELSE }
      token(/\/IF/) {|m| m }
      token(/FOR/) {|m| :FOR }
      token(/LIST/) {|m| m }
      token(/\/LIST/) {|m| m }
      token(/\/FOR/) {|m| m }
      token(/ADD/) {|m| m }
      token(/EMPTY/) {|m|m}
      token(/WHILE/) {|m| :WHILE }
      token(/\/WHILE/) {|m| m}
      token(/EACH/) {|m| m }
      token(/\/EACH/) {|m| m }
      token(/PRINT/) {|m| m }
      token(/\/PRINT/) {|m| m }
      token(/DONE/) {|m|m}
      token(/\/DONE/) {|m|m }
      token(/DECL/){|m| m }
      token(/\/DECL/){|m| m }
      token(/INCBY/){|m|m }
      token(/IN/) {|m|m }
      token(/TO/){|m|m}
      token(/FUNCTION/) {|m| :FUNCTION }
      token(/\/FUNCTION/) {|m|m }
      token(/READ/) {|m| m }
      token(/\/READ/) {|m|m }
      token(/HASH/) {|m|m}
      token(/\/HASH/) {|m|m }
      token(/"[\w\s!\?]*"/) {|m| m.to_s }
      token(/>>/){|m|m}
      token(/==/) {|m| m }
    		token(/=\/=/) {|m| m }
    		token(/>/) {|m| m }
    		token(/>=/) {|m| m }
    		token(/</) {|m| m }
    		token(/<=/) {|m| m }
    		token(/AND/) {|m| m }
      token(/OR/) {|m| m }
      token(/NOT/) {|m| m }
      token(/\&\&/) {|m| m }
      token(/\|\|/) {|m| m }
      token(/\d+\.*\d*/) {|m| m.to_f}
      token(/\w+/) {|m| m }
      token(/./){|m| m }
      
      start :PROGRAM do
        match(:STMT_LIST){|m| m.eval unless m.class == nil }
      end
      #STMT_LIST
      rule :STMT_LIST do
        match(:STMT,:STMT_LIST) {|stmt,stmt_list| STMT_LIST_C.new(stmt,stmt_list)}
        match(:STMT)
      end
      #STMT
      rule :STMT do
        match(:RETURN_STMT)
        match(:IO_STMT)
        match(:SEL_STMT)
        match(:ITER_STMT)
        match(:DATA_STMT)
        match(:ASSIGN_STMT)
        match(:FUNCTION_STMT)
        match(:EXPR)
      end
      
      rule :FUNCTION_STMT do
        match(:FUNCTION_DEF)
        match(:FUNCTION_CALL)
      end
      
      rule :FUNCTION_DEF do
        match(:FUNCTION,:FUNC_NAME,'(',')',:STMT_LIST,'/FUNCTION') {|_,name,_,_,body,_| DECL_FUNCTION_C.new(name,nil,body)}
        match(:FUNCTION,:FUNC_NAME,'(',:PARAMETER_LIST,')',:STMT_LIST,'/FUNCTION') {|_,name,_,parameter,_,body,_| DECL_FUNCTION_C.new(name,parameter.flatten,body)}
      end
      
      rule :FUNCTION_CALL do
        match(:FUNC_NAME,'(',')') {|name,_,_| FUNCTION_CALL_C.new(name,nil)}
        match(:FUNC_NAME,'(',:ARGUMENT_LIST,')') {|name,_,arg_list,_| FUNCTION_CALL_C.new(name,arg_list.flatten)}
      end
      
      rule :ARGUMENT_LIST do
        match(:STMT){|m| [m] }
        match(:ARGUMENT_LIST,',',:STMT){|m,_,n| [m]<<[n] }
      end
      
      rule :PARAMETER_LIST do
        match('<',:TYPES,'>',:VAR_DEC){|_,m,_,n| [m,n] }
        match(:PARAMETER_LIST,',',:PARAMETER_LIST){|m,_,n| [m]<<[n] }
      end
      
      rule :SEL_STMT do
        match(:IF,'(',:EXPR,')',:STMT_LIST,:ELSE,:STMT_LIST,'/IF'){|_,_,cond,_,ifbody,_,elsebody,_| IF_ELSE_C.new(cond,ifbody,elsebody)}
        match(:IF,'(',:EXPR,')',:STMT_LIST,:ELSE,:ELSEIF,'/IF'){|_,_,cond,_,ifbody,_,elsebody,_| IF_ELSE_C.new(cond,ifbody,elsebody)}
        match(:IF,'(',:EXPR,')',:STMT_LIST,'/IF') {|_,_,cond,_,ifbody,_| IF_C.new(cond,ifbody)}	
      end
      rule :ELSEIF do
        match(:IF,'(',:EXPR,')',:STMT_LIST,:ELSE,:ELSEIF){|_,_,cond,_,ifbody,_,elsebody| IF_ELSE_C.new(cond,ifbody,elsebody)}
        match(:IF,'(',:EXPR,')',:STMT_LIST,:ELSE,:STMT_LIST){|_,_,cond,_,ifbody,_,elsebody| IF_ELSE_C.new(cond,ifbody,elsebody)}
        match(:IF,'(',:EXPR,')',:STMT_LIST) {|_,_,cond,_,ifbody| IF_C.new(cond,ifbody)}
      end
      
      rule :ITER_STMT do
        match(:WHILE,'(',:EXPR,')',:STMT_LIST,'/WHILE') {|_,_,cond,_,body,_| WHILE_C.new(cond,body)}
        match(:FOR,'(',:ITER_VAR,'IN',:NUM,'TO',:NUM,'INCBY',:NUM,')',:STMT_LIST,'/FOR') {|_, _, iter_var, _, start, _, range, _, increase, _, block, _| FOR_C.new(iter_var, start, range, increase, block)}
        match('EACH','(',:ITER_VAR,'IN',:VAR_DEC,')',:STMT_LIST,'/EACH'){|_,_,var,_,list,_,body,_| EACH_C.new(var,VAR_C.new(list),body)}
      end
      
      rule :ITER_VAR do
        match('<',:TYPES,'>',:VAR_DEC) {|_, m, _, n|[m,n]} 
      end
      
      rule :ASSIGN_STMT do
        match('DECL',:ASSIGN_TYPE,:VAR_DEC,':',:EXPR,'/DECL'){|_,type,name,_,expr,_| DECL_C.new(VAR_C.new(name),expr,type)}
        match('DECL',:ASSIGN_TYPE,:VAR_DEC,':','/DECL'){|_,type,name,_,_| DECL_C.new(VAR_C.new(name),nil,type)}
        match('LIST',:ASSIGN_TYPE,:VAR_DEC,':',:LIST,'/LIST'){|_,type,name,_,expr,_| DECL_LIST_C.new(VAR_C.new(name),expr,type)}
        match('HASH',:VAR_DEC,':',:HASH,'/HASH'){|_,name,_,expr,_| DECL_LIST_C.new(VAR_C.new(name),expr)}	
        match(:VAR_DEC,':',:EXPR){|name,_,expr| ASSIGN_C.new(VAR_C.new(name),expr)}
      end
      
      rule :DATA_STMT do
        match('ADD',:VAR_DEC, :LIST){|_,var,list| LIST_ADD_C.new(VAR_C.new(var),list)}
        match('ADD',:VAR_DEC, :HASH){|_,var,hash| HASH_ADD_C.new(VAR_C.new(var),hash)}
        match('REMOVE',:VAR_DEC,'[',:NUM,']'){|_,var,_,index,_| LIST_REMOVE_C.new(VAR_C.new(var),index)}
        match('REMOVE',:VAR_DEC,'{',:STR,'}'){|_,var,_,index,_| HASH_REMOVE_C.new(VAR_C.new(var),index)}
      end
      
      rule :ASSIGN_TYPE do
        match('<',:TYPES,'>'){|_,m,_| m}
      end
      
      rule :IO_STMT do
        match(:PRINT_STMT) {|m|m}
        match(:READ_STMT) {|m|m}
      end
      
      rule :PRINT_STMT do
        match('PRINT',:STMT_LIST,'/PRINT'){|_,m,_| PRINT_C.new(m) }
      end
      
      rule :READ_STMT do
        match('READ',:VAR_DEC,'/READ') {|_,m,_| READ_C.new(m) }
        match('READ','<',:TYPES,'>',:VAR_DEC,'/READ') {|_,_,t,_,m,_| READ_C.new(m,t) }
      end
      
      rule :RETURN_STMT do
        match('DONE',:STMT_LIST,'/DONE') {|_,m,_| DONE_C.new(m) }
      end
      
      #EXPR
      rule :EXPR do
        match(:EXPR,:OPERATOR_A,:TERM) {|e,o,t| ARIT_OBJECT.new(o,e,t) }
        match(:TERM){|m|m}
      end
      
      rule :TERM do
        match(:TERM,:OPERATOR_B,:LOG) {|e,o,t| ARIT_OBJECT.new(o,e,t)}
        match(:LOG){|m|m}
      end
      
      rule :LOG do
        match(:LOG,:LOG_OPERATOR,:COMP){|e,o,t| LOG_OBJECT.new(o,e,t) }
        match(:LOG_OPERATOR_NOT,:COMP){|o,t| LOG_OBJECT_NOT.new(o,t) }
        match(:COMP){|m|m}
      end

      rule :COMP do
        match(:COMP,:COMP_OPERATOR,:FACTOR){|e,o,t| COMP_OBJECT.new(o,e,t) }
        match(:FACTOR){|m|m}
      end
      rule :FACTOR do
        match(:FUNCTION_CALL)
        match('(',:EXPR,')') {|_,m,_| m }
        match(:DATA)
        match(:TYPE)
        match(:VAR_CALL)
        match(:LIST)
        match(:HASH)
      end
      rule :DATA do
        match(:VAR_DEC,'[',:NUM,']') {|var,_,num,_| LIST_GET.new(VAR_C.new(var),num)}
        match(:VAR_DEC,'[',:VAR_CALL,']') {|var,_,num,_| LIST_GET.new(VAR_C.new(var),num)}
        match(:VAR_DEC,'{',:STR,'}') {|var,_,str,_| HASH_GET.new(VAR_C.new(var),str)}
        match(:VAR_DEC,'{',:VAR_CALL,'}') {|var,_,str,_| HASH_GET.new(VAR_C.new(var),str)}
      end
      
      rule :LIST do
        match('[',:TYPE_LIST,']'){|_,list,_| LIST_C.new(list.flatten) }
        match('[',']'){|_,_| LIST_C.new([]) }
      end
      
      rule :TYPE_LIST do
        match(:TYPE) {|m|[m.eval] }
        match(:TYPE_LIST,',',:TYPE) {|m,_,n| [m]+[n.eval] }
      end
      rule :HASH do
        match('{',:TYPE_HASH,'}'){|_,hash,_| HASH_C.new(hash) }
        match('{','}'){|_,_| HASH_C.new({}) }
      end
      rule :TYPE_HASH do
        match(:STR,'>>',:TYPE) {|m,_,n| {m.eval=>n.eval} }
        match(:TYPE_HASH,',',:TYPE_HASH) {|m,_,n| m.merge!(n)}
      end
      
      rule :COMP_OPERATOR do
        match('==') {|m| m }
        match('=/=') {|m| '!=' }
        match('>')  {|m| m }
        match('>=') {|m| m }
        match('<')  {|m| m }
        match('<=') {|m| m }
      end
      
      rule :LOG_OPERATOR do
        match('&&')  {|m| m }
        match('||')  {|m| m }
        match('AND') {|m| m }
        match('OR')  {|m| m }
        
      end
      rule :LOG_OPERATOR_NOT do
        match('!')   {|m| m }
        match('NOT') {|m| m }
      end
      
      rule :OPERATOR_A do
        match('+') {|m| m }
        match('-') {|m| m }
      end
      rule :OPERATOR_B do
        match('*') {|m| m }
        match('/') {|m| m }
        match('%') {|m| m }
      end
      rule :TYPES do
        match(/NUM/){|m| m = :NUM}
        match(/STR/){|m| m = :STR}
        match(/BOOL/){|m| m = :BOOL}
        match(/ALL/){|m| m = :ALL}
      end
      rule :TYPE do
        match(:NUM) 
        match(:STR)
        match(:BOOL)
        match(:ALL)
      end
      
      rule :NUM do
        match('-',Float){|_,m| NUM_C.new(-m) }
        match(Float){|m| NUM_C.new(m) }
      end
      
      #STR
      rule :STR  do
        match(/("[\w\s!\?]*")/){|m| STR_C.new(m) }
      end
      #VAR_CALL
      rule :VAR_CALL do
        match(/^[A-Z][a-zA_Z0-9_]*/){|m| VAR_C.new(m)}
      end
      #VAR_DEC
      rule :VAR_DEC do
        match(/^[A-Z][a-zA_Z0-9_]*/){|m| m}
      end
      #FUNC_NAME
      rule :FUNC_NAME do
        match(/[A-Z_]+/){|m|m}
      end
      #BOOL
      rule :BOOL do
        match(/TRUE/) {|m| BOOL_C.new(m) }
        match(/FALSE/){|m| BOOL_C.new(m) }
      end
    end # end of Parser.new
  end # initialize
end

