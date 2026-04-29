class Lexer
    def initialize(filename)
        @filename = filename
        @buffer = File.read(filename)
        @index = 0
        @begin_reprise = -1
    end

    def next_token!
        while true
            case ch
            in nil
                if @begin_reprise != -1
                    raise error("you need to end reprise, found end of file", @begin_reprise, 3)
                end
                return :eof, nil
            in "A".."G"
                return :chord, next_chord!
            in "/"
                next_ch!
                return :base, next_note!
            in "|" if @buffer[@index, 3] == "||:"
                if @begin_reprise != -1
                    raise error("you need to end reprise before creating a new one", @begin_reprise, 3, "new one here", @index, 3)
                end
                @begin_reprise = @index
                advance! 3
                return :begin_reprise, nil
            in ":" if @buffer[@index, 3] == ":||"
                if @begin_reprise == -1
                    raise error("no beginning reprise", @index, 3)
                end
                reprise_ptr = @begin_reprise
                @begin_reprise = -1
                advance! 3
                return :end_reprise, reprise_ptr
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

    $EXTENSION_REGEX = /\G(sus(2|4|)|(-|\+|)((M?7|6)(b5)?|(6\/9|M?9|add9)|(M?11|add11)(b5)?|M?13(b5)?|b5)?)/
    def next_extension!
        if result = @buffer.match($EXTENSION_REGEX, @index)
            advance! result.captures[0].length
            return result.captures[0]
        else
            raise NotImplementedError, 'unreachable'
        end
    end

    $NOTE_REGEX = /\G(Ab|A#|Bb|C#|Db|D#|Eb|F#|Gb|G#|[A-G])/
    def next_note!
        if result = @buffer.match($NOTE_REGEX, @index)
            advance! result.captures[0].length
            return result.captures[0]
        else
            return nil
        end
    end

    def advance!(n)
        for _ in 1..n
            next_ch!
        end
        return ch
    end

    def next_ch!
        @index += 1
        return @buffer[@index]
    end

    def ch
        return @buffer[@index]
    end

end