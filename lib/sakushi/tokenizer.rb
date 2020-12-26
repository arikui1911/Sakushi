require 'strscan'
require 'stringio'

module Sakushi
  Token = Struct.new(:kind, :value, :lineno, :column)

  class Tokenizer
    def self.for_string(src)
      new StringIO.new(src)
    end

    def initialize(io)
      @src = io
      @fib = Fiber.new(&method(:scan))
    end

    def next_token
      @fib.resume
    end

    private

    def emit(kind, value, lineno = @lineno, column = @column)
      emit_direct Token.new(kind, value, lineno, column).freeze
    end

    def emit_direct(token)
      Fiber.yield token
    end

    def scan
      scanner = :scan_default
      @lineno = 1
      @src.each_line do |line|
        s = StringScanner.new(line.chomp+"\n")
        @column = 1
        until s.eos?
          scanner = __send__(scanner, s)
          @column = s.pos + 1
        end
        @lineno += 1
      end
      emit_direct Token.new(:EOF, nil, @lineno, 1).freeze
    end

    def scan_default(s)
      case
      when s.scan(/\s+/)
        ;
      when s.scan(/;.*/)
        ;
      when s.scan(/#\|/)
        return :scan_comment
      when s.scan(/[.()']/)
        emit s[0], s[0]
      when s.scan(/\|/)
        emit :IDENT_BEGIN, s[0]
        return :scan_ident
      when s.scan(/"/)
        emit :STRING_BEGIN, s[0]
        return :scan_string
      when s.scan(/[^();"\|]+/)
        emit :ATOM, s[0]
      else
        raise Exception, "must not happen: #{s.rest.inspect}"
      end
      __method__
    end

    def scan_comment(s)
      s.scan_until(/\|#/) and return :scan_default
      __method__
    end

    ESC = {
      'n' => "\n",
      'r' => "\r",
      't' => "\n",
    }

    # [TODO] other escape sequences
    def scan_ident(s)
      case
      when s.scan(/\|/)
        emit :IDENT_END, s[0]
        return :scan_default
      when s.scan(/\\([ntr])/)
        emit :IDENT_CONTENT, ESC.fetch(s[1])
      when s.scan(/[^\|]+/)
        emit :IDENT_CONTENT, s[0]
      else
        raise Exception, "must not happen: #{s.rest.inspect}"
      end
      __method__
    end

    # [TODO] other escape sequences
    def scan_string(s, lineno)
      case
      when s.scan(/"/)
        emit :STRING_END, s[0]
        return :scan_default
      when s.scan(/\\([ntr])/)
        emit :STRING_CONTENT, ESC.fetch(s[1])
      when s.scan(/[^"]+/)
        emit :STRING_CONTENT, s[0]
      else
        raise Exception, "must not happen: #{s.rest.inspect}"
      end
      __method__
    end
  end
end

