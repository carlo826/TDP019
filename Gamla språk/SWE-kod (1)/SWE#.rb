require 'rules'

file = ARGV[0]

if file != nil
  swe = Rules.new(file)
  swe.start
else
  puts "Filnamn saknas!"
end
