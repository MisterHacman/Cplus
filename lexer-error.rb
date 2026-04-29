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