#!/usr/bin/env ruby

##############################################################################
#
# This part defines the (insert name) language.
#
##############################################################################

require './rdparse.rb'
require './class.rb'
require 'logger'

#iners_discipuli/alumni piger = Lazy_Students ;D Notitia_cognitionis

class Lingua
        
    # def DiceRoller.roll(times, sides)
    #     (1..times).inject(0) {|sum, _| sum + rand(sides) + 1 }
    # end

    def initialize
        # Tokenizer

        @LinguaParser = Parser.new("LinguaNotitia") do
            token(/\s+/)
            # token(/'.*'/) {|m| m}
            #token(/'/) {|m| m}
            token(/\;/) {|m| m}
            token(/\(/) {|m| m}
            token(/\)/) {|m| m}
            token(/\{/) {|m| m}
            token(/\}/) {|m| m}
            token(/for_each/) {|m| m}
            token(/for/) {|m| m}
            token(/\]/) {|m| m}
            token(/\[/) {|m| m}
            token(/\d+\.\d+/) {|m| m.to_f}
            token(/true/) {|m| m}
            token(/false/) {|m| m}
            token(/return/) {|m| m}
            token(/float/) {|m| m}
            token(/int/) {|m| m}
            token(/string/) {|m| m}
            token(/bool/) {|m|m}
            #match(/void/) {|m| m} #// Implementera rule :returnValues do <--.
            token(/array/) {|m| m}
            token(/char/) {|m| m}
            token(/if/) {|m| m}
            token(/elseif/) {|m| m}
            token(/else/) {|m| m}
            token(/@/) { |m| m}
            token(/\d+/){|m| m.to_i }
            token(/\==/) {|m| m} #=/
            token(/<=/) {|m| m} #=/
            token(/>=/) {|m| m} #=/
            token(/\!/) {|m| m} #=/
            token(/!=/) {|m| m} #=/
            token(/</)  {|m| m} #=/
            token(/\=/)  {|m| m} #=/
            token(/\+\+/) {|m| m}
            token(/--/) {|m| m}
            token(/\|\|/) {|m| m}
            token(/\&\&/) {|m| m}
            token(/!/) {|m| m}
            token(/\+\=/) {|m| m}
            token(/\+\+/) {|m| m}
            token(/\+/) {|m| m}
            token(/\*/) {|m| m}
            token(/\%/) {|m| m}
            token(/\-\=/){|m| m}
            token(/\-\-/){|m| m}
            token(/\-/) {|m| m}
            token(/\//) {|m| m}
            token(/\".*\"/){|m| m}
            token(/\'.+\'/) {|m| m.to_s}
            token(/[A-Za-z]+/) {|m| m.to_s}
            token(/./) {|m| m}


            start :begin do
                match(:blocks) {|m| Block.new(m).eval()}
            end

            rule :blocks do
                match(:blocks, :block){|a, b| [a, b].flatten}
                match(:block) {|m| [m]}
            end

            rule :block do
                match(:output)
                match(:for_loop)
                match(:for_each_loop)
                match(:while_loop)
                match(:declaration)
                match(:assignment,';') 
                match(:else_condition)
                match(:def_function)
                match(:if_condition)
                match(:call_function)
                match(:return,';')
                # match(:input)
            end

            rule :def_function do
                match('def',:datatype, :varName, '(',:parameters,')','{',:blocks,'}',';') {|_,datatype, varName, _, parameters,_,_,blocks,_,_| Def_function_node.new(datatype, varName,parameters,blocks)}
                match('def',:datatype, :varName, '(', ')','{',:blocks,'}',';') {|_,datatype, varName, _,_,_,blocks,_,_| Def_function_node.new(datatype, varName,nil,blocks)}
                match('def',:datatype, :varName, '(', ')','{','}',';') {|_,datatype, varName, _,_,_,_,_| Def_function_node.new(datatype, varName,nil,[])}
            end

            rule :call_function do
                match(:varName, '(',:expression_list,')',) {|varName, _, parameters,_| Call_function_node.new(varName, parameters)}
                match(:varName, '(',:varName_list,')',) {|varName, _, parameters,_| Call_function_node.new(varName, parameters)}
                match(:varName, '(',')',) {|varName,_,_| Call_function_node.new(varName, nil)}
            end

            rule :expression_list do
                match(:expression_list,',',:expression){|a,_,b | [a, b].flatten}
                match(:expression){| a | [a].flatten}
            end

            rule :parameters do
                match(:declaration, ',',:parameters) {|a,_, b| [a, b].flatten}
                match(:expression,',', :parameters) {|a,_, b| [a, b].flatten}
                match(:declaration) {| a | [a].flatten}
            end

            rule :for_loop do
                match('for', '(', :declaration, ';', :bool_expression, ';', :assignment, ')', '{', :blocks, '}', ';'){|_, _, var, _,bool, _, assignment, _, _, blocks,_, _| For_loop_node.new(var, bool, assignment, blocks)}
            end

            rule :for_each_loop do
                match('for_each', '(', :varName,',',:varName, ')', '{', :blocks, '}', ';'){|_, _, var,_,array, _,_,blocks,_,_| For_each_loop_node.new(var,array,blocks)}
                match('for_each', '(', :varName,',',:array_expression, ')', '{', :blocks, '}', ';'){|_, _, var,_,array, _,_,blocks,_,_| For_each_loop_node.new(var,array,blocks)}
            end

            rule :while_loop do
                match('while', '(', :bool_expression, ')', '{', :blocks, '}', ';'){|_, _, bool_expr, _, _, blocks, _,_| While_loop_node.new(bool_expr, blocks) }
            end

            rule :declaration do
                match(:datatype, :varName, '=', :expression,';') {|datatype, varName, _, expression,_| DeclareVar.new(datatype,
                varName, expression) }
                match(:datatype, :varName, '=', :varName,';') {|datatype, varName, _, expression,_| DeclareVar.new(datatype,
                varName, expression) }
                match(:datatype, :varName) {|datatype, varName| DeclareVar.new(datatype,
                varName, nil) }
                match('@', :datatype, :varName, '=', :expression) {|_,datatype, varName, _, expression| DeclareVar.new(datatype,
                varName, expression, true) }
                match('@', :datatype, :varName, '=', :varName) {|_,datatype, varName, _, expression| DeclareVar.new(datatype,
                varName, expression, true) }
                match('@', :datatype, :varName) {|_,datatype, varName| DeclareVar.new(datatype,
                varName, nil, true) }
            end

            rule :assignment do
                match(:varName, '=', :varName) {|varName, operator, expression | ReaVar.new(varName, operator, expression) }
                match(:varName, '+=', :varName) {|varName, operator, expression | ReaVar.new(varName, operator, expression) }
                match(:varName, '-=', :varName) {|varName, operator, expression | ReaVar.new(varName, operator, expression) }
                match(:varName, '=', :expression) {|varName, operator, expression | ReaVar.new(varName, operator, expression) }
                match(:varName, '+=', :aritm_expression) {|varName, operator, expression | ReaVar.new(varName, operator,expression) }
                match(:varName, '-=', :aritm_expression) {|varName, operator, expression | ReaVar.new(varName, operator,expression) }
                match(:varName, '--') {|varName, operator | ReaVar.new(varName, operator,nil) }
                match(:varName, '++') {|varName, operator | ReaVar.new(varName, operator,nil) }
            end

            rule :output do
                match('print', '(', :expression, ')', ';') {|_, _, expression, _ | Print_expr.new(expression) }
                match('print', '(', :varName, ')', ';') {|_, _, varName, _ | Print_expr.new(varName) }
                match('print', '(',')', ';') {|_, _, _ | Print_expr.new() }
            end

            rule :if_condition do
                match('if', :bool_expression, '{', :blocks, '}', :else_condition, ';') {|_, cond, _, blocks, _, _else,_ | Conditions_Node.new(cond,blocks,_else)}
 
                match('if', :bool_expression, '{', :blocks, '}', ';') {|_, cond, _, blocks, _,_| Conditions_Node.new(cond,blocks)}
            end
 
            rule :else_condition do
                match('elseif', :bool_expression,  '{', :blocks, '}', :else_condition) {|_,  cond,  _, blocks, _, _else | Conditions_Node.new(cond,blocks,_else)}
 
                match('elseif', :bool_expression,  '{', :blocks, '}') {|_,  cond,  _, blocks, _| Conditions_Node.new(cond,blocks)}

                match('else', '{', :blocks, '}') {|_, _, blocks, _| Conditions_Node.new(true,blocks)}
            end
             
			rule :datatype do
                match('float') {|m| m}
                match('int') {|m| m}
                match('string') {|m| m}
                match('bool') {|m|m}
                match('array') {|m| m}
                match('char') {|m| m}
                #match('void') {|m| m}   #// Implementera rule :returnValues do <--.
            end


            rule :expression do
                match(:aritm_expression)
                match(:bool_expression)
                match(:string_expression)
                match(:char_expression)
                match(:call_function)
                match(:array_expression)
            end

            rule :char_expression do
                match(/\'.+\'/) {| m | Char_node.new(m)}
            end

            rule :string_expression do
                match(/\".*\"/) {| m | String_node.new(m)}
            end

            rule :array_expression do
                match('[', :expression_list, ']') {| _, a, _| Array_node.new(a) }
                match('[',']') {| _, _| Array_node.new([]) }
            end
                
            rule :aritm_expression do 
                # match(:varName, '+=', :aritm_expression) {|a,b,c | Aritm_node.new(a,b,c)}
                match(:aritm_expression, '+', :term){ |a,b,c | Aritm_node.new(a,b,c)}
                match(:aritm_expression, '-', :term){ |a,b,c | Aritm_node.new(a,b,c)}


                # match(:varName, '=', :varName, '-', :aritm_expression) {|varName, _, expression | ReaVar.new(varName, expression) }
                # match(:varName, '=', :varName, '*', :aritm_expression) {|varName, _, expression | ReaVar.new(varName, expression) }
                # match(:varName, '=', :varName, '%', :aritm_expression) {|varName, _, expression, _ | ReaVar.new(varName, expression) }
                match(:term)
            end

            rule :term do
                match(:term, '*', :factor) {|a, b, c| Aritm_node.new(a, b, c) }
                match(:term, '/', :factor) {|a, b, c| Aritm_node.new(a, b, c) }
                match(:term, '%', :factor) {|a, b, c| Aritm_node.new(a, b, c) }
                match(:factor)
            end

            rule :factor do
                match('(', :aritm_expression, ')') { | _,a,_ | a}
                match(Float) {|m| Float_node.new(m)}
                match(Integer) {|m| Integer_node.new(m)}
            end


            rule :bool_expression do
                # match(Integer, :comparison_operator, Integer ) {|a, b, c| Comparison.new(a, b, c) }
                match('(', :aritm_expression, :comparison_operator, :aritm_expression,')') {|_, a, b, c, _| Comparison_node.new(a, b, c) }
                match('(', :varName, :comparison_operator, :aritm_expression,')') {|_, a, b, c, _| Comparison_node.new(a, b, c) }
                match('(', :aritm_expression, :comparison_operator, :varName,')') {|_, a, b, c, _| Comparison_node.new(a, b, c) }
                match('(', :varName, :comparison_operator, :varName,')') {|_, a, b, c, _| Comparison_node.new(a, b, c) }
                match('(', :bool_expression, :logic_operator, :bool_expression,')') {|_, a, b, c, _| Comparison_node.new(a, b, c) }
                match('(', 'true',')') { |_,_,_ | Bool_node.new(true)}
                match('(', 'false',')') { |_,_,_| Bool_node.new(false)}
                match(:negation_bool)
            end

            rule :negation_bool do
            	match('!', :bool_expression) { |_,a| Neg_node.new(a) }
            end

            rule :return do
				match('return', :expression) {|_, expr| ReturnNode.new(expr)}
				match('return', :varName) {|_, varName| ReturnNode.new(varName)}
				match('return') {ReturnNode.new()}
			end

            rule :logic_operator do
                match('&&') {|m| m }
                match('||') {|m| m }
                match('!') {|m| m }
            end
            
            rule :comparison_operator do
                match('==') {|m| m }
                match('!=') {|m| m }
                match('>')  {|m| m }
                match('>=') {|m| m }
                match('<')  {|m| m }
                match('<=') {|m| m }
            end

            rule :varName do
                match(/[A-z]+[A-z0-9]*/) {|m| Find_Variable.new(m)}
                #match(/bool|int|!|([A-z]+[A-z0-9]*)/) {|m| Find_Variable.new(m)}
            end

            
            rule :varName_list do
                match(:varName_list,',',:varName){|a,_,b | [a, b].flatten}
                match(:varName){| a | [a].flatten}
            end

        end
    end

  
    def done(str)
        ["quit","exit","bye",""].include?(str.chomp)
    end

    def openFile(file)
        output = ""
        if (File.exist?(file)) then
            File.open(file, 'r') do |line|
                str = line.readlines
                output = str.join
            end
            puts "=> #{@LinguaParser.parse output}"
            p @@global_var
        else
            # puts "=> FileError: #{inFile} not found"
        end
        
        
    end

    def lingua
        print "[LinguaParser] "
        str = gets
        # if (file(str))
        #     fileName = str.gsub(/load\s*/,"").strip.chomp
        #     puts fileName
        #     str = ""
        #     if File.exist?(fileName)
        #         File.open(fileName, 'r') do |line|
        #             temp = line.readlines
        #             str = temp.join
        #         end

        if done(str) then
            puts "Bye."

        elsif str.chomp.eql?('gb')
            print @@global_var
            lingua
        else
            puts "=> #{@LinguaParser.parse str}"
            lingua
        end
    end


    def log(state = false)
        if state
            @LinguaParser.logger.level = Logger::DEBUG
        else
            @LinguaParser.logger.level = Logger::WARN
        end
    end
end

if ARGV[0]
   
    test = Lingua.new
    if test.openFile(ARGV[0])    
         puts "Running file #{ARGV[0]}"
    else
        puts "Couldn't open file #{ARGV[0]}"
    end

else
    puts "Running Lingua terminal"
    Lingua.new.lingua
end

# Examples of use

# irb(main):1696:0> DiceRoller.new.roll
# [diceroller] 1+3
# => 4
# [diceroller] 1+d4
# => 2
# [diceroller] 1+d4
# => 3
# [diceroller] (2+8*d20)*3d6
# => 306












    #         match(:expr, '+', :term) {|a, _, b| a + b }
    #         match(:expr, '-', :term) {|a, _, b| a - b }
    #         match(:term)
    # end
      
    #     rule :term do 
    #         match(:term, '*', :dice) {|a, _, b| a * b }
    #         match(:term, '/', :dice) {|a, _, b| a / b }
    #         match(:dice)
    #     end

    #     rule :dice do
    #         match(:atom, 'd', :sides) {|a, _, b| DiceRoller.roll(a, b) }
    #         match('d', :sides) {|_, b| DiceRoller.roll(1, b) }
    #         match(:atom)
    #     end
      
    #     rule :sides do
    #         match('%') { 100 }
    #         match(:atom)
    #     end
      
    #     rule :atom do
    #         # Match the result of evaluating an integer expression, which
    #         # should be an Integer
    #         match(Integer)
    #         match('(', :expr, ')') {|_, a, _| a }
    #     end
    # end