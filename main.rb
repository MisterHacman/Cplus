require "./lexer.rb"

lexer = Lexer.new "example.c+"

while true
    token, data = lexer.next_token!
    puts "#{token}: #{data}"
    break if token == :eof
end