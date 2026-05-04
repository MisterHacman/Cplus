class Lexer
    attr_reader :tokens
    def initialize(filename)
        @tokens = []
        @filename = filename
        @buffer = File.read(filename)
        @index = 0
        @begin_reprise = -1
    end

    def next_token!
        @tokens << get_next_token!
        return @tokens[@tokens.length - 1]
    end

    def get_next_token!
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
                @begin_reprise = @tokens.length
                advance! 3
                return get_next_token!
            in ":" if @buffer[@index, 3] == ":||"
                if @begin_reprise == -1
                    raise error("no beginning reprise", @index, 3)
                end
                reprise_ptr = @begin_reprise
                @begin_reprise = -1
                if advance!(3) == "x"
                    next_ch!
                    return :end_reprise, [reprise_ptr, Float::INFINITY] if @buffer[@index, 3] == "inf"
                    num_iters = next_regex!(/\G(\d+)/).to_i
                    return :end_reprise, [reprise_ptr, num_iters]
                end
                return :end_reprise, [reprise_ptr, 1]
            in _
                next_ch!
                next
            end
        end
    end

    def next_chord!
        note = self.next_note!
        extension = next_extension!
        if ch == "/"
            next_ch!
            base = next_note!
        end
        return note, extension, base
    end

    $NOTE_REGEX = /\G(A#|Bb|C#|Db|D#|Eb|F#|Gb|G#|Ab|[A-G])/
    def next_note!
        next_regex! $NOTE_REGEX
    end

    $EXTENSION_REGEX = /\G(sus(2|4|)|6\/9|(-|m|\+|aug)?((M|7|M7|6)(b5)?|(M?9|add9)(b5)?|(M?11|add11)(b5)?|M?13(b5)?|b5)?)/
    def next_extension!
        next_regex! $EXTENSION_REGEX
    end

    def next_regex!(regex)
        if result = @buffer.match(regex, @index)
            advance! result.captures[0].length
            return nil if result.captures[0] == ""
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