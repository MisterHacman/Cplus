module Token
    EOF = nil
    BAR = 0
    NEWLINE = 1
    BEGIN_REPR = 2
    END_REPR = 3
    REPEAT = 4
    REPEAT_TWO = 5
end

class Lexer
    def initialize(buffer)
        @buffer = buffer
        @index = 0
    end

    def next_token!
        token_start = false
        while !token_start
            case ch
            in nil
                return Token::EOF
            in '\n'
                next_ch!
                return Token::NEWLINE
            in 'A'..'G'
                return next_chord!
            in '/'
                next_ch!
                return next_note!
            in '%' if @buffer[@index, 2] == '%%'
                advance! 2
                return Token::REPEAT_TWO
            in '%'
                next_ch!
                return Token::REPEAT
            in '|' if @buffer[@index, 3] == '||:'
                advance! 3
                return Token::BEGIN_REPR
            in ':' if @buffer[@index, 3] == ':||'
                advance! 3
                return Token::END_REPR
            in '|'
                next_ch!
                return Token::BAR
            in _
                next_ch!
                next
            end
        end
    end

    def next_chord!
        note = self.next_note!
        if !note
            return nil
        end
        extension = next_extension!
        if !extension
            return nil
        end
        return note + extension
    end

    $EXTENSION_REGEX = /\G(sus(2|4|)|(-|\+|)((M?7|6)(b9|#9)?(#11)?(b13)?|(6\/9|add9|M?9)(#11)?(b13)?|(M?11)(b9|#9)?(b13)?|(M?13)(b9|#9)?(#11)?|))/
    def next_extension!
        if result = @buffer.match($EXTENSION_REGEX, @index)
            advance! result.captures[0].length
            result.captures[0]
        else
            raise NotImplementedError, 'unreachable'
        end
    end

    $NOTE_REGEX = /\G([A-G](b|#|))/
    def next_note!
        if result = @buffer.match($NOTE_REGEX, @index)
            advance! result.captures[0].length
            result.captures[0]
        else
            nil
        end
    end

    def advance!(n)
        for _ in 1..n
            next_ch!
        end
        ch
    end

    def next_ch!
        @index += 1
        @buffer[@index]
    end

    def ch
        @buffer[@index]
    end
end