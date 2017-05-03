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
            token(/for/) {|m| m}
            token(/\]/) {|m| m}
            token(/\[/) {|m| m}
            token(/\d+\.\d+/) {|m| m.to_f}

            token(/float/) {|m| m}
            token(/int/) {|m| m}
            token(/string/) {|m| m}
            token(/bool/) {|m|m}
            # match('void') {|m| m} // Implementera rule :returnValues do <--.
            token(/array/) {|m| m}
            token(/char/) {|m| m}
    

            token(/\d+/){|m| m.to_i }
            token(/\==/) {|m| m} #=/
            token(/<=/) {|m| m} #=/
            token(/>=/) {|m| m} #=/
            token(/!=/) {|m| m} #=/
            token(/</)  {|m| m} #=/
            token(/\=/)  {|m| m} #=/
            token(/\+\+/) {|m| m}
            token(/--/) {|m| m}
            token(/||/) {|m| m}
            token(/&&/) {|m| m}
            token(/!/) {|m| m}
            token(/\+/) {|m| m}
            token(/\*/) {|m| m}
            token(/\%/) {|m| m}
            token(/\-/) {|m| m}
            token(/\//) {|m| m}
            token(/\".*\"/){|m| m}
            token(/\'.+\'/) {|m| m.to_s}
            token(/[A-Za-z]+/) {|m| m.to_s}
            token(/./) {|m| m}


            start :begin do
                match(:blocks) {|m| m.eval()}
            end

            rule :blocks do
                match(:blocks, :block){|a, b| Blocks.new(a, b)}
                match(:block) {|m| Block.new(m)}
            end

            rule :block do
                match(:declaration)
                match(:assignment) 
                # match(:condition)
                # match(:output)
                # match(:input)
                # match(:loop)
            end

            rule :declaration do
                match(:datatype, :varName, '=', :expression,';') {|datatype, varName, _, expression, _| DeclareVar.new(datatype,
                varName, expression) }
                match(:datatype, :varName, ';') {|datatype, varName, _| DeclareVar.new(datatype,
                varName, nil) }
                match(:datatype, :varName, '=', :varName, ';') {|datatype, varName, _, expression, _| DeclareVar.new(datatype,
                varName, expression) }
            end
            rule :assignment do
                match(:varName, '=', :expression, ';') {|varName, _, expression, _ | ReaVar.new(varName, expression) }
                match(:varName, '=', :varName, ';') {|varName, _, expression, _ | ReaVar.new(varName, expression) }
            end

            rule :expression do
                match(:aritm_expression)
                match(:bool_expression)
                match(:string_expression)
                match(:char_expression)
            end

            rule :varName do
                match(/[A-z]+[A-z0-9]*/) {|m| Find_Variable.new(m)}
            end

            rule :char_expression do
                match(/\'.+\'/) {| m | Char_node.new(m)}
            end

            rule :string_expression do
                match(/\".*\"/) {| m | String_node.new(m)}
            end
                
            rule :aritm_expression do 
                match(:aritm_expression, '+', :term){ |a,b,c | Aritm_node.new(a,b,c)}
                match(:aritm_expression, '-', :term){ |a,b,c | Aritm_node.new(a,b,c)}
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
                # match('(', :bool_expression, :comparison_operator, :bool_expression,')') {|_, a, b, c, _| Bool_node.new(a, b, c) }
                match('(', :bool_expression, :logic_operator, :bool_expression,')') {|_, a, b, c, _| Comparison_node.new(a, b, c) }
                # match('(', :aritm_expression, :logic_operator, :aritm_expression,')') {|_, a, b, c, _| Comparison.new(a, b, c) }
                match('true') { | m | Bool_node.new(true)}
                match('false') { | m | Bool_node.new(false)}
                # match(:varName)
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
            rule :datatype do
                match('float') {|m| m}
                match('int') {|m| m}
                match('string') {|m| m}
                match('bool') {|m|m}
                # match('void') {|m| m} // Implementera rule :returnValues do <--.
                match('array') {|m| m}
                match('char') {|m| m}
            end
       
            

        end
    end

  
    def done(str)
        ["quit","exit","bye",""].include?(str.chomp)
    end
  
    def lingua
        print "[LinguaParser] "
        str = gets
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


Lingua.new.lingua



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