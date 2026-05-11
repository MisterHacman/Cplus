require "./lexer.rb"
require "./lexer-error.rb"
require "./interpreter.rb"

lexer = Lexer.new ARGV[1]
begin
    interpreter = Interpreter.new(lexer, ARGV[2] && ARGV[2] == "-d")
rescue CompilerError => err
    abort err.message
end

begin
    while interpreter.execute_next_token!
    end
rescue CompilerError => err
    abort err.message
end