require "./lexer.rb"
require "./lexer-error.rb"
require "./interpreter.rb"

lexer = Lexer.new ARGV[1]
interpreter = Interpreter.new(lexer, ARGV[2] && ARGV[2] == "-d")

while interpreter.execute_next_token!
end