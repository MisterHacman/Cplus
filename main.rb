require "./lexer.rb"
require "./lexer-error.rb"
require "./interpreter.rb"

lexer = Lexer.new "example.c+"
interpreter = Interpreter.new lexer

while interpreter.execute_next_token!
end