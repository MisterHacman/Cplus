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

    $EXTENSION_REGEX = /\G(sus(2|4|)|(-|\+|)((M?7|6)(b9|#9)?(#11|b5)?(b13)?|(6\/9|M?9|add9)(#11|b5)?(b13)?|(M?11|add11)(b9|#9)?(b13)?|M?13(b9|#9)?(#11|b5)?|b5)?)/
    def next_extension!
        if result = @buffer.match($EXTENSION_REGEX, @index)
            advance! result.captures[0].length
            return result.captures[0]
        else
            raise NotImplementedError, 'unreachable'
        end
    end

    $NOTE_REGEX = /\G([A-G](b|#)?)/
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

class Lexer
    def error(msg, start_index, length, msg2=nil, start_index2=nil, length2=nil)
        if !msg2
            return "\nError: " + error_msg(msg, start_index, length)
        else
            return "\nError: " + error_msg(msg, start_index, length) + "\n" + error_msg(msg2, start_index2, length2)
        end
    end

    def error_msg(msg, start_index, length)
        row, column = grid_pos_at start_index
        row_str = row.to_s
        line = ""
        i = start_index - column + 1
        while @buffer[i] != "\n" && @buffer[i] != nil
            line << @buffer[i]
            i += 1
        end
        spaces = " " * (column - 1 + row_str.length)
        arrows = "^" * length
        return "#{msg}\n  -> #{@filename} at [Ln #{row}, Col #{column}]\n  | \e[34m#{row_str}\e[0m #{line}\n  | #{spaces} \e[31m#{arrows}"
    end

    def grid_pos
        grid_pos_at @index
    end

    def grid_pos_at(index)
        row = 1
        column = 1
        i = 0
        while i < index
            column += 1
            if @buffer[i] == "\n"
                row += 1
                column = 1
            end
            i += 1
        end
        return row, column
    end
end