require "io/console"

# Iterator interface for interpreting file.
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

    # Print all variable values.
    #
    # @example
    #   Interpreter(@variables = [1,2,3,4,5,6,7,8,9,10,11,12], @current_inst_str = "C").print_vars
    #     #=> prints "C:  [C:1, Db:2, D:3, Eb:4, E:5, F:6, Gb:7, G:8, Ab:9, A:10, Bb:11, B: 12, ]"
    #
    # @author August Stokes
    def print_vars
        var_names = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"]
        print "#{@current_inst_str}:\t["
        @variables.each_with_index do |var, index|
            print "#{var_names[index]}:#{var}, "
        end
        puts "]"
    end

    # Execute next instruction, and returns whether the interpreter should continue or stop.
    #
    # @return [Boolean] true if interpreter should continue, false if it should end
    #
    # @example
    #   Interpreter(@lexer = Lexer(@buffer = "A E", @index = 0)).execute_next_token! #=> true
    #   Interpreter(@lexer = Lexer(@buffer = "A E", @index = 1)).execute_next_token! #=> false
    #
    # @author August Stokes
    def execute_next_token!
        print_vars if @debug
        case token
        in :eof, _
            return false
        in :chord, [note, quality, extension, alteration, base]
            @current_inst_str = "#{note}#{quality}#{extension}#{alteration}#{"/#{base}" if base != ""}"
            execute_chord! var_index(note), quality, extension, alteration, base
        in :base, note
            @current_inst_str = "/#{note}"
            execute_base! var_index(note)
        in :begin_reprise, _
            @index += 1
            return execute_next_token!
        in :end_reprise, [jump_pos, num_iters]
            return execute_end_reprise!(jump_pos, num_iters)
        end
        @index += 1
        return true
    end

    # Execute base token. This takes an ascii character and puts the ascii value in the variable.
    #
    # @param var [Integer] an index to the `@variables` array
    # @raise [SystemExit] if ^C was typed
    #
    # @example
    #   interpreter = Interpreter(@variables = [1,2,3,4,5,6,7,8,9,10,11,12])
    #   interpreter.execute_base!(0)
    #   # If input character is 'A'
    #   interpreter.variables #=> [65,2,3,4,5,6,7,8,9,10,11,12]
    #
    # @author August Stokes
    def execute_base!(var)
        char = STDIN.getch
        if char == "\u0003"
            exit(0)
        end
        @variables[var] = char.ord
    end

    # Execute an end reprise and the instruction after that.
    #
    # @param jump_pos [Integer] instruction to jump to
    # @param num_iters [Integer] number of times to jump left
    # @return [Boolean] if interpreter should continue
    #
    # @example
    #   interpreter = Interpreter(@index = 1)
    #   interpreter.token #=> [:end_reprise, [0, 1]]
    #   interpreter.execute_end_reprise!(0, 1) #=> true
    #   interpreter.token #=> [:end_reprise, [-1, 0]]
    #   interpreter.execute_end_reprise!(-1, 0) #=> false
    #
    # @author August Stokes
    def execute_end_reprise!(jump_pos, num_iters)
        @current_inst_str = ":||#{"x#{num_iters}" if num_iters}"
        if jump_pos == -1
            @index += 1
        else
            @lexer.tokens[@index][1][1] -= 1
            @lexer.tokens[@index][1][0] = -1 if num_iters == 1
            @index = jump_pos
        end
        return execute_next_token!
    end

    # Execute chord. If the chord is just a major chord, e.g. ["C#", "", "", "", ""],
    # the ascii code in the variable is printed. Minor and augmented chords subtract
    # and add respectively. A major chord with an extension will assign the variable
    # to that extension. The alterations will multiply by those alterations. A base
    # will assign the value of the variable to the base variable.
    #
    # @param var [Integer] an index to the `@variables` array
    # @param quality [String]
    # @param extension [String]
    # @param alteration [String]
    # @param base [String]
    #
    # @example
    #   interpreter = Interpreter(@variables = [1,2,3,4,5,6,7,8,9,10,11,12])
    #   interpreter.execute_chord!(11, "m", "7", "b13", "C") # Bm7b13/C, C=B=(12-7)*13
    #   interpreter.variables #=> [65,2,3,4,5,6,7,8,72,10,11,65]
    #   interpreter.execute_chord!(0, "", "", "", "") #=> prints "A"
    #
    # @author August Stokes
    def execute_chord!(var, quality, extension, alteration, base)
        if quality == "" && extension == "" && alteration == "" && base == ""
            print_var(var)
            return nil
        end
        if quality == ""
            execute_extension!(var, extension)
        elsif quality[0] == "m" || quality[0] == "-"
            execute_add!(var, extension, -1)
        elsif quality[0, 3] == "aug" || quality[0] == "+"
            execute_add!(var, extension, 1)
        end
        execute_alteration!(var, alteration)
        if base != ""
            @variables[var_index base] = @variables[var]
        end
    end

    # Print a variables number as an ascii character.
    #
    # @param var [Integer] an index to the `@variables` array
    #
    # @example
    #   Interpreter(@variables = [69,2,3,4,5,6,7,8,9,10,11,12]).print_var(0) #=> prints "E"
    #
    # @author August Stokes
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

    # Execute an extension by assigning the variable to the value of the extension.
    # If the extension has a major 7, the variable will be assigned to the maximum
    # of the extension and the variables value.
    #
    # @param var [Integer] index in the `@variables` array
    # @param extension [String]
    #
    # @example
    #   interpreter = Interpreter(@variables = [1,2,3,4,5,6,7,8,9,10,11,12])
    #   interpreter.execute_extension!(0, "7")
    #   interpreter.variables #=> [7,2,3,4,5,6,7,8,9,10,11,12]
    #   interpreter.execute_extension!(0, "6/9")
    #   interpreter.execute_extension!(4, "maj7")
    #   interpreter.execute_extension!(6, "maj7")
    #   interpreter.execute_extension!(11, "add9")
    #   interpreter.variables #=> [69,2,3,4,7,6,7,8,9,10,11,129]
    #   interpreter.lexer = Lexer(@buffer = "Dsus C", @index = 0)
    #   interpreter.execute_extension!(2, "sus")
    #   interpreter.execute_next_token! #=> prints "E"
    #   interpreter.lexer = Lexer(@buffer = "Ebsus C", @index = 0)
    #   interpreter.execute_extension!(3, "sus")
    #   interpreter.execute_next_token! #=> false
    #   interpreter.lexer = Lexer(@buffer = "Dbsus2 C", @index = 0)
    #   interpreter.execute_extension!(1, "sus2")
    #   interpreter.execute_next_token! #=> false
    #
    # @author August Stokes
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

    # Executes alteration, which multiplies the variable by the extension value.
    #
    # @param var [Integer] index in the `@variables` array
    # @param alteration [String]
    #
    # @example
    #   interpreter = Interpreter(@variables = [1,2,3,4,5,6,7,8,9,10,11,12])
    #   interpreter.execute_alteration!(0, "b5")
    #   interpreter.execute_alteration!(1, "b5b9")
    #   interpreter.execute_alteration!(2, "#9")
    #   interpreter.execute_alteration!(3, "#9#11b13")
    #   interpreter.variables #=> [5,90,27,5148,5,6,7,8,9,10,11,12]
    #
    # @author August Stokes
    def execute_alteration!(var, alteration)
        if alteration.match?(/b5/)
            @variables[var] *= 5
        end
        if alteration.match?(/b9|#9/)
            @variables[var] *= 9
        end
        if alteration.match?(/#11/)
            @variables[var] *= 11
        end
        if alteration.match?(/b13/)
            @variables[var] *= 13
        end
    end

    # Execute an addition or subtraction instruction.
    #
    # @param var [Integer] index in the `@variables` array
    # @param extension [String]
    # @param sign [Integer] 1 if we should add, -1 if we should subtract
    #
    # @example
    #   interpreter = Interpreter(@variables = [1,2,3,4,5,6,7,8,9,10,11,12])
    #   interpreter.execute_add!(0, "", -1)
    #   interpreter.execute_add!(1, "7", 1)
    #   interpreter.execute_add!(2, "6/9", 1)
    #   interpreter.execute_add!(3, "add9", -1)
    #   interpreter.variables #=> [0,9,72,39,5,6,7,8,9,10,11,12]
    #
    # @author August Stokes
    def execute_add!(var, extension, sign)
        if extension == ""
            @variables[var] += sign
        elsif extension[1, 3] == "6/9"
            @variables[var] += sign * 69
        elsif extension[0].match?(/\d/)
            @variables[var] += sign * extension.match(/(\d+)/).captures[0].to_i
        else
            @variables[var] += sign
            execute_chord!(var, "", extension, "", "")
        end
    end

    # Get the index in the `@variables` array from a note.
    #
    # @param note [String]
    # @return [Integer] the index in the `@variables` array
    #
    # @example
    #   Interpreter.var_index("C") #=> 0
    #   Interpreter.var_index("C#") #=> 1
    #   Interpreter.var_index("Db") #=> 1
    #
    # @author August Stokes
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

    # Returns the current token
    #
    # @return [Array] the token
    #
    # @example
    #   interpreter = Interpreter(@lexer = Lexer(tokens = [[:chord, ["C","","","",""]], [:eof, nil]]))
    #   interpreter.token #=> [:chord, ["C","","","",""]]
    #   interpreter.index += 1
    #   interpreter.token #=> [:eof, nil]
    #
    # @author August Stokes
    def token
        @lexer.tokens[@index]
    end
end