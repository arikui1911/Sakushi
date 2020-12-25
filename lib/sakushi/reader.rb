module Sakushi
  class Reader
    def initialize(engine, tokenizer)
      @engine = engine
      @tokenizer = tokenizer
    end

    def read
      t = @tokenizer.next_token
      case t.kind
      when :EOF
        nil
      when '('
        read_list
      when :IDENT_BEGIN
        read_ident t
      when :STRING_BEGIN
        read_string t
      when :ATOM
        parse_atom t
      else
        read_error t, "unexpected token: #{t}"
      end
    end

    private

    def read_error(cause, msg)
      raise "#{cause.lineno}:#{cause.column}: #{msg}"
    end

    def parse_atom(t)
      case
      when x = Kernel.Float(t.value, exception: false)
        @engine.float x
      when n = Kernel.Integer(t.value, exception: false)
        @engine.integer n
      when t.value == '#t'
        @engine.true
      when t.value == '#f'
        @engine.false
      else
        @engine.intern t.value
      end
    end

    def read_ident(beg)
    end

    def read_string(beg)
    end

    def read_token_sequence(beg, content, fin)
      buf = []
      while t = @tokenizer.next_token
        case t.kind
        when :EOF
          return nil
        when content
          buf << t.value
        when fin
          break
        else
          read_error t, "unexpected token: #{t}"
        end
      end
      buf.join
    end

    def read_list
    end
  end
end

