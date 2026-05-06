# An iterator interface for tokenizing a file.
class Lexer
    # Takes one or two error messages, string slices in `@buffer` and returns an error string.
    #
    # @param msg [String] the first error message
    # @param start_index [Integer] index in `@buffer`
    # @param length [Integer] length of slice in `@buffer`
    # @param msg2 [String, nil] the second error message
    # @param start_index [String, nil] index in `@buffer`
    # @param length2 [Integer] length of slice in `@buffer`
    # @return [String]
    #
    # @example
    #   Lexer(@filename = "examples/example.c+", @buffer = "||:", @index = 3)
    #     .error("you need to end reprise, found end of file", 0, 3)
    #     #=> %q{
    #     #=> Error: you need to end reprise, found end of file
    #     #=>   -> examples/example.c+ at [Ln 1, Col 1]
    #     #=>   | 1 ||:
    #     #=>   |   ^^^
    #     #=> }
    #   Lexer(@filename = "examples/example.c+", @buffer = "||: ||:", @index = 3)
    #     .error("you need to end reprise, found end of file", 0, 3, "")
    #     #=> %q{
    #     #=> Error: you need to end reprise before creating a new one
    #     #=>   -> .\examples\blues.c+ at [Ln 1, Col 1]
    #     #=>   | 1 ||: ||:
    #     #=>   |   ^^^
    #     #=> new one here
    #     #=>   -> .\examples\blues.c+ at [Ln 1, Col 5]
    #     #=>   | 1 ||: ||:
    #     #=>   |       ^^^
    #     #=> }
    #
    # @author August Stokes
    def error(msg, start_index, length, msg2=nil, start_index2=nil, length2=nil)
        if !msg2
            return "\nError: " + error_msg(msg, start_index, length)
        else
            return "\nError: " + error_msg(msg, start_index, length) + "\n" + error_msg(msg2, start_index2, length2)
        end
    end


    # Takes an error messages and a string slices in `@buffer`, then returns an error string.
    #
    # @param msg [String] the first error message
    # @param start_index [Integer] index in `@buffer`
    # @param length [Integer] length of slice in `@buffer`
    # @return [String]
    #
    # @example
    #   Lexer(@filename = "examples/example.c+", @buffer = "||:", @index = 3)
    #     .error_msg("you need to end reprise, found end of file", 0, 3)
    #     #=> %q{
    #     #=> you need to end reprise, found end of file
    #     #=>   -> examples/example.c+ at [Ln 1, Col 1]
    #     #=>   | 1 ||:
    #     #=>   |   ^^^
    #     #=> }
    #
    # @author August Stokes
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
        return "#{msg}\n  -> #{@filename} at [Ln #{row}, Col #{column}]\n  | \e[34m#{row_str}\e[0m #{line}\n  | #{spaces} \e[31m#{arrows}\e[0m"
    end

    # Returns the current line and column
    #
    # @return [Array(Integer, Integer)] the line and column
    #
    # @example
    #   Lexer(@buffer = "C F\nF G", @index = 2).grid_pos #=> [1, 3]
    #   Lexer(@buffer = "C F\nF G", @index = 5).grid_pos #=> [2, 1]
    #   Lexer(@buffer = "C F\nF G", @index = 4).grid_pos #=> [2, 0]
    #
    # @author
    # August Stokes
    def grid_pos
        grid_pos_at @index
    end

    # Returns line and column at `index`
    #
    # @param index [Integer] the `@buffer` index
    # @return [Array(Integer, Integer)] the line and column
    #
    # @example
    #   Lexer(@buffer = "C F\nF G").grid_pos_at(2) #=> [1, 3]
    #   Lexer(@buffer = "C F\nF G").grid_pos_at(5) #=> [2, 1]
    #   Lexer(@buffer = "C F\nF G").grid_pos_at(4) #=> [2, 0]
    #
    # @author
    # August Stokes
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