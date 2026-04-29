require "./lexer.rb"

file = File.read("example.c+")
lexer = Lexer.new file
while token = lexer.next_token!
    puts token
end
p Token::EOF