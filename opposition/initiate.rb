require_relative 'grammar'

if ARGV.size == 0 
  puts "Error: no rino-script entered." 
elsif File.exist?(ARGV[0])
  content = File.read(ARGV[0])
  RINORules.new(content, ARGV[1..ARGV.size])
else
  puts "Error: file "+ "'" + ARGV[0] + "'" + " was not found."
end