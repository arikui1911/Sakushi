module Sakushi
  class Reader
    def initialize(engine, tokenizer)
      @engine = engine
      @tokenizer = tokenizer
      @buf = []
    end

    def read
      t = next_token()
      case t.kind
      when :EOF
        nil
      when "'"
        @engine.quote(read())
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

    def next_token
      @buf.empty? ? @tokenizer.next_token : @buf.pop
    end

    def pushback_token(t)
      @buf.push t
      nil
    end

    def read_error(cause, msg)
      raise "#{cause.lineno}:#{cause.column}: #{msg}"
    end

    CHARS = {
      'space' => ' '.ord,
      'tab'   => "\t".ord,
      'newline' => "\n".ord,
    }

    def parse_atom(t)
      case
      when x = Kernel.Float(t.value, exception: false)
        @engine.float x
      when n = Kernel.Integer(t.value, exception: false)
        @engine.integer n
      when t.value == '#t' || t.value == '#T'
        @engine.true
      when t.value == '#f' || t.value == '#F'
        @engine.false
      when t.value.start_with?('#\\')
        c = t.value.delete_prefix('#\\')
        return @engine.char(c.ord) if c.length == 1
        @engine.char CHARS.fetch(c.downcase){
          read_error t, "invalid charactor literal: #{t.value.inspect}"
        }
      else
        @engine.intern t.value.downcase
      end
    end

    def read_ident(beg)
      name = read_token_sequence(:IDENT_CONTENT, :IDENT_END)
      read_error(beg, "unterminated symbol literal") unless name
      @engine.intern name
    end

    def read_string(beg)
      content = read_token_sequence(:STRING_CONTENT, :STRING_END)
      read_error(beg, "unterminated string literal") unless content
      @engine.string content
    end

    def read_token_sequence(content, fin)
      buf = []
      while t = next_token()
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
      t = next_token()
      return @engine.nil if t.kind == ')'   # a) empty list
      pushback_token t

      car = read()
      t = next_token()
      if t.kind == '.'
        cdr = read()
        t = next_token()
        read_error(t, "expect end of list, unexpected token: #{t}") unless t.kind == ')'
        return @engine.cons(car, cdr)   # b) dot pair
      end
      pushback_token t

      @engine.cons(car, read_list())  # c) read rest list recursively
    end
  end
end

