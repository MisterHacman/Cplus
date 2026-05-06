require "io/console"

class Interpreter
    def initialize(lexer, debug=false)
        @variables =* 1..12
        @lexer = lexer
        while @lexer.next_token![0] != :eof
        end
        @index = 0
        @debug = debug
        @current_inst_str = ""
    end

    def print_vars
        var_names = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"]
        print "#{@current_inst_str}: \t["
        @variables.each_with_index do |var, index|
            print "#{var_names[index]}: #{var}, "
        end
        puts "]"
    end

    def execute_next_token!
        print_vars if @debug
        case @lexer.tokens[@index]
        in :eof, _
            return false
        in :chord, [note, quality, extension, alteration, base]
            @current_inst_str = "#{note}#{quality}#{extension}#{alteration}#{"/#{base}" if base != ""}"
            execute_chord!(note, quality, extension, alteration, base)
        in :base, note
            @current_inst_str = "/#{note}"
            char = STDIN.getch
            if char == "\u0003"
                exit(0)
            end
            @variables[var_index note] = char.ord
        in :begin_reprise, _
            @index += 1
            return execute_next_token!
        in :end_reprise, [jump_pos, num_iters]
            @current_inst_str = ":||#{"x#{num_iters}" if num_iters}"
            if jump_pos == -1
                @index += 1
                return execute_next_token!
            end
            @lexer.tokens[@index][1][1] -= 1
            @lexer.tokens[@index][1][0] = -1 if num_iters == 1
            @index = jump_pos
            return execute_next_token!
        end
        @index += 1
        return true
    end

    def execute_chord!(note, quality, extension, alteration, base)
        var = var_index note
        if quality == "" && extension == "" && alteration == "" && base == ""
            print_var(var)
            return nil
        end
        if quality == ""
            execute_extension!(var, extension)
        elsif quality[0] == "m" || quality[0] == "-"
            execute_add!(note, extension, -1)
        elsif quality[0, 3] == "aug" || quality[0] == "+"
            execute_add!(note, extension, 1)
        end
        execute_alteration!(var, alteration)
        if base != ""
            @variables[var_index base] = @variables[var]
        end
    end

    def print_var(var)
        if @debug
            print "Print: "
            p @variables[var].chr
        else
            if @variables[var].chr == "\r"
                print "\n"
            else
                print @variables[var].chr
            end
        end
    end

    def execute_extension!(var, extension)
        if extension[0, 3] == "maj"
            num = 7
            result = extension[1..].match(/(\d+)/)
            num = result.captures[0].to_i if result
            @variables[var] = num if @variables[var] < num
        elsif extension[0, 4] == "add9"
            @variables[var] = "#{@variables[var]}9".to_i
        elsif extension[0, 3] == "6/9"
            @variables[var] = 69
        elsif extension[0] && extension[0].match?(/\d/)
            num = extension.match(/(\d+)/).captures[0].to_i
            @variables[var] = num
        end
        if extension.match?(/sus/)
            num = 4
            num = 2 if extension.include?("2")
            @index += 1 if @variables[var] == num
        end
    end

    def execute_alteration!(var, alteration)
        if alteration.match?(/b5/)
            @variables[var] *= 5
        elsif alteration.match?(/b9|#9/)
            @variables[var] *= 9
        elsif alteration.match?(/#11/)
            @variables[var] *= 11
        elsif alteration.match?(/b13/)
            @variables[var] *= 13
        end
    end

    def execute_add!(note, extension, sign)
        var = var_index note
        if extension == ""
            @variables[var] += sign
        elsif extension[1, 3] == "6/9"
            @variables[var] += sign * 69
        elsif extension[0].match?(/\d/)
            @variables[var] += sign * extension.match(/(\d+)/).captures[0].to_i
        else
            @variables[var] *= sign
            execute_chord!(note, "", extension, "", "")
        end
    end

    def var_index(note)
        case note
        when "C" then 0
        when "C#", "Db" then 1
        when "D" then 2
        when "D#", "Eb" then 3
        when "E" then 4
        when "F" then 5
        when "F#", "Gb" then 6
        when "G" then 7
        when "G#", "Ab" then 8
        when "A" then 9
        when "A#", "Bb" then 10
        when "B" then 11
        end
    end

    def token
        @lexer.tokens[@index]
    end
end