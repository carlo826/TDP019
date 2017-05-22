require_relative 'rdparse'
require_relative 'nodes'

class RINORules
  attr_reader :content
  attr_accessor :RINOParser
  def initialize(content, argv)
    @content = content
    @RINOParser = Parser.new("RINOParser") do

      #Literals:
      token(/".*"/) {|m| m}
      token(/^(?!return$|continue$|break$|if$|elif$|else$|for$|loop$|while$|task$|out$|or$|and$|is$|not$)[a-zA-Z\_]\w*/) { |m| m }
      token(/^\d+\.\d+/) {|m| m.to_f}
      token(/^\d+/) {|m| m.to_i}
      token(/^-\d+\.\d+/) {|m| m.to_f}
      token(/^-\d+/) {|m| m.to_i}

      #Compare operators:
      token(/<=/) {|m| m}
      token(/>=/) {|m| m}
      token(/==/) {|m| m}
      token(/!=/) {|m| m}

      #Logical operators:
      token(/&&/) {|m| m}
      token(/\|\|/) {|m| m}

      #Ignore comments, spaces
      token(/#.*/)
      token(/\\\\[\W\w]+\/\//)
      token(/\s+/)

      #Single characters
      token(/./) {|m| m}


      start :program do
        match(:global_statements) {|global_statements| Program.new(global_statements)}
      end


      rule :global_statements do
        match(:global_statements, :global_statement) { |global_statements, global_statement| global_statements + global_statement}
        match(:global_statement) { |global_statement| global_statement}
      end

      rule :global_statement do
        match(:expression, ';') {|expression, _| [expression]}
        match(:var_decl) {|var_decl| [var_decl]}
        match(:task_decl) { |task_decl| task_decl}
      end

      rule :block do
        match(:block, :local_statement) { |block, local_statement| block + [local_statement]}
        match(:local_statement) { |local_statement| [local_statement]}
      end

      rule :local_statement do
        match(:condition_chain) { |condition_chain| Condition_chain.new(condition_chain)}
        match(:var_decl)
        match(:expression, ';')
        match(:loop_stmt)
      end

      rule :condition_chain do
        match(:if_stmt, :condition_successors) { |if_stmt, condition_successors| if_stmt + condition_successors}
        match(:if_stmt) { |if_stmt| if_stmt}
      end

      rule :condition_successors do
        match(:elif_stmt, :condition_successors) { |elif_stmt, condition_successors| elif_stmt + condition_successors}
        match(:elif_stmt) {|elif_stmt| elif_stmt}
        match(:else_stmt) {|else_stmt| else_stmt}
      end

      rule :if_stmt do
        match("if", '(', :bool_expr, ')', '{', :block, '}') {|_,_,bool_expr,_,_,block,_| [Condition_stmt.new(block, Expression.new(bool_expr))] }
      end

      rule :elif_stmt do
        match("elif", '(', :bool_expr, ')', '{', :block, '}') {|_, _, bool_expr,_,_,block,_| [Condition_stmt.new(block, Expression.new(bool_expr))]}
      end

      rule :else_stmt do
        match("else", '{', :block, '}') {|_,_,block,_| [Condition_stmt.new(block)]}
      end

      rule :loop_stmt do
        match("for", '(', :var_decl, :expression, ';', :expression, ')', '{', :block, '}') { |_, _, var_decl, iterations, _, step, _ ,_ ,block, _| For_loop.new(var_decl, iterations, step, block)}
        match("while", '(', :bool_expr, ')', '{', :block, '}' ) {|_, _, bool_expr, _, _, block, _| While_loop.new(Expression.new(bool_expr), block)}
      end


      rule :task_decl do
        match("task", :identifier, '(', :param_list, ')', '{', :block, '}') {|_,identifier,_,param_list,_,_,block,_| [Task_decl.new(identifier.name, block, param_list)] }
        match("task", :identifier, '(', ')', '{', :block, '}') {|_,identifier,_, _, _,block,_| [Task_decl.new(identifier.name, block)] }
      end

      rule :var_decl do
        match(:identifier, '=', :expression, ';')  { |identifier, _, expression, _| Var_decl.new(identifier.name, expression) }
      end

      rule :identifier do
        match(/^(?!return$|if$|elif$|else$|for$|loop$|while$|task$|out$|or$|and$|is$|not$)[a-zA-Z\_]\w*/) { |identifier| Identifier.new(identifier)}
      end

      rule :param_list do
        match(:param_list, ',', :identifier) { |param_list, _, identifier| param_list +[identifier.name]}
        match(:identifier) { |identifier| [identifier.name] }
      end

      rule :expression do
        match(:bool_expr)  { |bool_expr| Expression.new(bool_expr)}
        match(:aritm_expr) { |aritm_expr| Expression.new(aritm_expr)}
      end

      rule :literal do
        match(:call_stmt)
        match(:boolean)
        match(:numeric)
        match(:string)
        match(:identifier)
      end

      rule :bool_expr do
        match(:bool_expr, :or_oper, :bool_term)  {|expr, _, term| expr + ['|'] + term}
        match(:bool_term)  {|term| term }
      end

      rule :bool_term do
        match(:bool_term, :and_oper, :bool_factor) {|term, _, factor| term + ['&'] + factor}
        match(:bool_factor) {|factor| factor }
      end

      rule :bool_factor do
        match('(',:bool_expr,')') { |_, expr, _| [Expression.new(expr)] }
        match(:aritm_expr, :compare_op, :aritm_expr)  { |left_expr, compare_op, right_expr| [Expression.new(left_expr + [compare_op] + right_expr)]  }
        match(:aritm_expr)
      end

      rule :or_oper do
        match("||")
        match("or")
      end

      rule :and_oper do
        match("&&")
        match("and")
      end

      rule :compare_op do
        match('>')     { '>' }
        match('<')     { '<' }
        match("==")    { "==" }
        match("is")    { "==" }
        match("!=")    { "!=" }
        match("not")   { "!=" }
        match(">=")    { ">=" }
        match("<=")    { "<=" }
      end

      #Längst upp i trädet för aritmetiska uttryck finns det ett uttryck adderat / subtraherat med ett annat. Samt
      #En speciell kombination där det är ett uttryck utan någon operator, detta för att om man kollar längre
      #ner i syntax trädet finnes en literaler (aritm_factor), dessa kan vara tex. -5.
      #Vad match(:aritm_expr, :aritm_term) {|expr, term| expr + ['+'] + term} då "fångar" upp är
      #när det finns en operator i själva literalen, dvs -5. Detta leder till att jag i nästa steg:
      #match(:aritm_expr, '-', :aritm_term) {|expr, oper, term| expr + [oper] + term} kan fånga upp
      #när det blir dubbel negativt.
      rule :aritm_expr do
        match(:aritm_expr, '+', :aritm_term) {|expr, oper, term| expr + [oper] + term}
        match(:aritm_expr, :aritm_term) {|expr, term| expr + ['+'] + term}
        match(:aritm_expr, '-', :aritm_term) {|expr, oper, term| expr + [oper] + term}
        match(:aritm_term) {|term| term }
      end

      #Näst längst ner i syntax-trädet för aritmetiska uttryck är en term, som kan vara flera termer multiplicerat / dividerat med faktorer
      #eller en enkilt faktor. *, / har ju samma nivå av företräde, det spelar ingen roll vilken ordning man utför de operationerna.
      rule :aritm_term do
        match(:aritm_term, '*', :aritm_factor) {|term, oper, factor| [Expression.new(term + [oper] + factor)]}
        match(:aritm_term, '/', :aritm_factor) {|term, oper, factor| [Expression.new(term + [oper] + factor)]}
        match(:aritm_factor) {|factor| factor}
      end

      #Längst ner i syntax-trädet för aritmetiska uttryck är en factor, som kan vara en literal eller ett annat uttryck.
      rule :aritm_factor do
        match('(', :aritm_expr, ')') { |_, expr, _| [Expression.new(expr)] }
        match(:literal) {|literal| [literal]}
      end

      rule :call_stmt do
        match(:rino_stmt)
        match(:identifier, '(', :arg_list, ')') {|identifier,_,arg_list,_| Call_stmt.new(identifier.name, Arg_list.new(arg_list))}
        match(:identifier, '(', ')') {|identifier,_, _| Call_stmt.new(identifier.name)}
      end

      rule :rino_stmt do
        match(:IO_stmt)
        match(:debug_stmt)
        #...
      end

      rule :IO_stmt do
        match(:out_stmt)
        match(:in_stmt)
      end

      rule :debug_stmt do
        match("expr_test", '(',:debug_expr, ',', :expression,')') {|_,_, debug_expr, _, expression2, _| Expression_test.new(debug_expr, expression2)}
      end

      #Ganska onödigt stor regel kanske.
      rule :debug_expr do
        match(Integer, '+', :debug_expr) { |l, _, d| l.to_s << '+' << d}
        match(Integer, '-', :debug_expr) { |l, _, d| l.to_s << '-' <<d}
        match(Integer, '*', :debug_expr) { |l, _, d| l.to_s << '*' <<d}
        match(Integer, '/', :debug_expr) { |l, _, d| l.to_s << '/' <<d}
        match(Float, '+', :debug_expr) { |l, _, d| l.to_s << '+'<<d}
        match(Float, '-', :debug_expr) { |l, _, d| l.to_s << '-'<<d}
        match(Float, '*', :debug_expr) { |l, _, d| l.to_s << '*'<<d}
        match(Float, '/', :debug_expr) { |l, _, d| l.to_s << '/' <<d}
        match(Float) {|l| l.to_s}
        match(Integer) {|l| l.to_s}
        match("true") {|b| b.to_s}
        match("false") {|b| b.to_s}
      end

      rule :out_stmt do
        match("out", '(', :expression, ')') { |_,_, expression, _| Out_stmt.new(expression) }
      end

      rule :arg_list do
        match(:arg_list, ',', :expression) { |arg_list, _, expr| arg_list + [expr] }
        match(:expression) { |expr| [expr]}
      end


      rule :numeric do
        match(:integer)
        match(:float)
      end

      rule :boolean do
        match("true") { Rino_bool.new(true) }
        match("false") { Rino_bool.new(false) }
      end

      rule :string do
        match(/".*"/) { |string| Rino_string.new(string)}
      end

      rule :float do
        match(Float) { |float| Rino_float.new(float.to_f)}
      end

      rule :integer do
        match(Fixnum) {|integer| Rino_int.new(integer.to_i) }
      end
    end
    @RINOParser.parse @content
  end
end