# An iterator interface for tokenizing a file.
class Lexer
    attr_reader :tokens
    def initialize(filename)
        @tokens = []
        @filename = filename
        @buffer = File.read(filename)
        @index = 0
        @begin_reprise = -1
    end

    # Advance lexer one token, append the token to `@tokens` and return it.
    #
    # The tokens shape depends on the token type.
    # A chord has the shape `[:chord, [<note>, <quality>, <extension>, <alteration>, <base>]]`,
    # <note> being the only required item, the rest can be `""`.
    #
    # A base has the shape `[:base, <note>]` and an end reprise,
    # the shape `[:end_reprise, [<jump_ptr>, <reps>]]`. End of file has the simple shape `[:eof, nil]`
    # 
    # @return [Array] returns a token in the form [keyword, data]
    # @raise [CompilerError] if we hit end of file without closing a reprise
    #
    # @example
    #   Lexer(@buffer = "Gb+#9", @index = 0).get_next_token! #=> [:chord, ["Gb", "+", "", "#9", ""]]
    #   Lexer(@buffer = "Gb+#9", @index = 5).get_next_token! #=> [:eof, nil]
    #   Lexer(@buffer = "Gb+#9", @index = 6).get_next_token! #=> [:eof, nil]
    #   Lexer(@buffer = "/A ||: B :||x5", @index = 0).get_next_token! #=> [:base, "A"]
    #   Lexer(@buffer = "/A ||: B :||x5", @index = 2).get_next_token! #=> [:chord, ["B", "", "", "", ""]]
    #   Lexer(@buffer = "/A ||: B :||x5", @index = 8).get_next_token! #=> [:end_reprise, [1, 5]]
    #   Lexer(@buffer = "||: ", 3).get_next_token! #=> RuntimeError
    #
    # @author August Stokes
    def next_token!
        @tokens << get_next_token!
        return @tokens[@tokens.length - 1]
    end

    # Advances to the next token and returns it.
    # Use `next_token!` instead of this one, as it doesn't fully advance the lexer.
    #
    # @return [Array] the token which is returned
    # @raise [CompilerError] if we hit end of file without closing a reprise
    #
    # @example
    #   Lexer(@buffer = "Gb+#9", @index = 0).get_next_token! #=> [:chord, ["Gb", "+", "", "#9", ""]]
    #   Lexer(@buffer = "Gb+#9", @index = 5).get_next_token! #=> [:eof, nil]
    #   Lexer(@buffer = "Gb+#9", @index = 6).get_next_token! #=> [:eof, nil]
    #   Lexer(@buffer = "/A ||: B :||x5", @index = 0).get_next_token! #=> [:base, "A"]
    #   Lexer(@buffer = "/A ||: B :||x5", @index = 2).get_next_token! #=> [:chord, ["B", "", "", "", ""]]
    #   Lexer(@buffer = "/A ||: B :||x5", @index = 8).get_next_token! #=> [:end_reprise, [1, 5]]
    #   Lexer(@buffer = "||: ", 3).get_next_token! #=> RuntimeError
    #
    # @author August Stokes
    def get_next_token!
        while true
            case ch
            # Eof
            in nil
                raise CompilerError, error("you need to end reprise, found end of file", @begin_reprise, 3) unless @begin_reprise == -1
                return :eof, nil
            # Chord
            in "A".."G"
                return :chord, next_chord!
            # Base
            in "/"
                next_ch!
                return :base, next_regex!($NOTE_REGEX)
            # Start reprise
            in "|" if @buffer[@index, 3] == "||:"
                return next_start_reprise!
            # End reprise
            in ":" if @buffer[@index, 3] == ":||"
                return next_end_reprise!
            # Comment
            in "#"
                while next_ch! != "\n"
                end
                next_ch!
                next
            # Whitespace / unused characters
            in _
                next_ch!
                next
            end
        end

    end

    # Advance start reprise. Since the begin reprise is not a token,
    # rather just an index that the end_reprise can't restart from,
    # it will return the token after this one.
    #
    # @return [Array] the proceding token
    # @raise [CompilerError] if there was an unended begin reprise previously
    #
    # @example
    #   Lexer(@filename = "examples/add.c+", @index = 5).next_start_reprise! #=> [:chord, ["C", "+", "7", "", ""]]
    #   Lexer(@buffer = "||: ||:", index = 3).next_start_reprise! #=> RuntimeError
    #
    # @author August Stokes
    def next_start_reprise!
        raise CompilerError, error("you need to end reprise before creating a new one", @begin_reprise, 3, "new one here", @index, 3) unless @begin_reprise == -1
        @begin_reprise = @tokens.length
        advance! 3
        return get_next_token!
    end

    # Advance end reprise. This returns a token of the form `[:end_reprise, [<jump_ptr>, <reps>]]`, where
    # `<jump_ptr>` is the index in @tokens we are jumping to when returning and `<reps>` is the amount of
    # times to return.
    #
    # @return [Array] the end reprise token
    # @raise [CompilerError] if there is no matching begin reprise
    #
    # @example
    #   Lexer(@filename = "examples/add.c+", @index = 13).next_end_reprise! #=> [:end_reprise, [2, 5]]
    #   Lexer(@buffer = ":||", @index = 0).next_end_reprise! #=> RuntimeError
    #
    # @author August Stokes
    def next_end_reprise!
        raise CompilerError, error("no beginning reprise", @index, 3) if @begin_reprise == -1
        reprise_ptr = @begin_reprise
        @begin_reprise = -1
        if advance!(3) == "x"
            next_ch!
            return :end_reprise, [reprise_ptr, Float::INFINITY] if @buffer[@index, 3] == "inf"
            num_iters = next_regex!(/\G(\d+)/).to_i
            return :end_reprise, [reprise_ptr, num_iters]
        end
        return :end_reprise, [reprise_ptr, 1]
    end

    $NOTE_REGEX = /(A#|Bb|C#|Db|D#|Eb|F#|Gb|G#|Ab|[A-G])/
    $QUALITY_REGEX = /^(-|m|\+|aug|)/
    $EXTENSION_REGEX = /^(((maj)?(7|9|11|13)|add9|6\/9|6)?(sus(4|2|))?)/
    $ALTERATION_REGEX = /^((b5)?(b9|#9)?(#11)?(b13)?)/
    $INVALID_REGEX = /((-|m).*(sus|#9)|(\+|aug).*(b5|b13)|9.*9|9sus2|11.*11|11sus[^2]|13.*13|6.*13|sus2.*9|sus[^2].*#11|b5.*#11)/

    # Advance chord. Returns a token of the shape `[:chord, [<note>, <quality>, <extension>, <alterations>, <base>]]`.
    #
    # @return [Array] the token
    # @raise [CompilerError] if chord is invalid, given by the `$INVALID_REGEX` regular expression
    #
    # @example
    #   Lexer(@buffer = "C").next_chord! #=> [:chord, ["C", "", "", "", ""]]
    #   Lexer(@buffer = "Db9").next_chord! #=> [:chord, ["Db", "", "9", "", ""]]
    #   Lexer(@buffer = "Dmb9").next_chord! #=> [:chord, ["D", "m", "", "b9", ""]]
    #   Lexer(@buffer = "Dmb9/C").next_chord! #=> [:chord, ["D", "m", "", "b9", "C"]]
    #   Lexer(@buffer = "D9b9").next_chord! #=> RuntimeError
    #
    # @author August Stokes
    def next_chord!
        start_index = @index
        note = next_regex! $NOTE_REGEX
        quality = next_regex! $QUALITY_REGEX
        extension = next_regex! $EXTENSION_REGEX
        alteration = next_regex! $ALTERATION_REGEX
        raise CompilerError, error("invalid chord", start_index, @index - start_index) if (quality + extension + alteration).match?($INVALID_REGEX)
        base = ""
        if ch == "/"
            next_ch!
            base = next_regex! $NOTE_REGEX
        end
        return note, quality, extension, alteration, base
    end

    # Takes a regex and advances the lexer by the match. Returns the matching string.
    #
    # @param [Regexp] the regex
    # @return [String] the matching string
    # @raise [CompilerError] unless `@index` is less than `@buffer.length`
    #
    # @example
    #   Lexer(@buffer = "110.", @index = 1).next_regex!(/^(\d+)/) #=> "10"
    #   Lexer(@buffer = "110.", @index = 3).next_regex!(/^(\d+)/) #=> ""
    #   Lexer(@buffer = "110.", @index = 5).next_regex!(/^(\d+)/) #=> RuntimeError
    #
    # @author August Stokes
    def next_regex!(regex)
        if result = @buffer[@index..].match(regex)
            advance! result.captures[0].length
            return result.captures[0]
        else
            return ""
        end
    end

    # Advances `@buffer` `n` characters and returns the character at that position.
    #
    # @param [Integer] how many characters to advance
    # @return [String, nil] the character at the end of the advancement, nil if we hit end of file
    #
    # @example
    #   Lexer(@buffer = "110.", @index = 0).advance!(2) #=> "0"
    #   Lexer(@buffer = "110.", @index = 0).advance!(4) #=> nil
    #
    # @author August Stokes
    def advance!(n)
        for _ in 1..n
            next_ch!
        end
        return ch
    end

    # Advance `@buffer` one character and return the character at that position.
    #
    # @return [String, nil] the character, nil if we hit end of file
    #
    # @example
    #   Lexer(@buffer = "110.", @index = 1).next_ch! #=> "0"
    #   Lexer(@buffer = "110.", @index = 3).next_ch! #=> nil
    #
    # @author August Stokes
    def next_ch!
        @index += 1
        return @buffer[@index]
    end

    # Returns current character in `@buffer`
    #
    # @return [String, nil] the character, nil if at end of file
    #
    # @example
    #   Lexer(@buffer = "110.", @index = 1).ch #=> "1"
    #   Lexer(@buffer = "110.", @index = 4).ch #=> nil
    #
    # @author August Stokes
    def ch
        return @buffer[@index]
    end
end