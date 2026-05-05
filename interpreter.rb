require "io/console"

class Interpreter
    def initialize(lexer, debug=false)
        @variables = [0,0,0,0,0,0,0,0,0,0,0]
        @lexer = lexer
        while @lexer.next_token![0] != :eof
        end
        @index = 0
        @debug = debug
        @current_inst_str = ""
    end

    def print_vars
        var_names = ["A", "Bb", "B", "C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab"]
        print "#{@current_inst_str}: \t["
        @variables.each_with_index do |var, index|
            print "#{var_names[index]}: #{var}, " if var != 0
        end
        puts "]"
    end

    def execute_next_token!
        print_vars if @debug
        case @lexer.tokens[@index]
        in :eof, _
            return false
        in :chord, [note, extension, base]
            @current_inst_str = "#{note}#{extension}#{"/#{base}" if base}"
            execute_chord!(note, extension, base)
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

    def execute_chord!(note, extension, base)
        var = var_index note
        if !extension && base
        elsif !extension && !base
            if @debug
                print "Print: "
                p @variables[var_index note].chr
            else
                if @variables[var].chr == "\r"
                    print "\n"
                else
                    print @variables[var_index note].chr
                end
            end
        elsif "-m".include?(extension[0]) || extension[0] == "+"
            execute_add!(note, extension, "-m".include?(extension[0]) ? -1 : 1)
        elsif extension[0, 3] == "aug"
            execute_add!(note, extension[2..], 1)
        elsif extension[0] == "M"
            num = 7
            num = extension[1..].match(/(\d+)/).captures[0].to_i if extension[1]
            @variables[var] = num if @variables[var] < num
        elsif extension[0, 3] == "sus"
            num = 4
            num = extension[3].to_i if extension[3]
            if @variables[var] == num
                @index += 1
            end
        elsif extension[0, 3] == "add"
            @variables[var] = (@variables[var].to_s + extension[3..]).to_i
        elsif extension[0, 3] == "6/9"
            @variables[var] = 69
        elsif extension[0].match?(/\d/)
            num = extension.match(/(\d+)/).captures[0].to_i
            @variables[var] = num
        end
        if base
            @variables[var_index base] = @variables[var]
        end
    end

    def execute_add!(note, extension, sign)
        var = var_index note
        if extension[1] == nil
            @variables[var] += sign
        elsif extension[1].match?(/\d/)
            @variables[var] += sign * extension[1..].match(/(\d+)/).captures[0].to_i
        else
            @variables[var] *= sign
            execute_chord!(note, extension[1..])
        end
    end

    def var_index(note)
        case note
        when "A" then 0
        when "A#", "Bb" then 1
        when "B" then 2
        when "C" then 3
        when "C#", "Db" then 4
        when "D" then 5
        when "D#", "Eb" then 6
        when "E" then 7
        when "F" then 8
        when "F#", "Gb" then 9
        when "G" then 10
        when "G#", "Ab" then 11
        end
    end

    def token
        @lexer.tokens[@index]
    end
end