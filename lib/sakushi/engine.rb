require 'weakref'

module Sakushi
  class Engine
    def initialize
      @true = Sakushi::True.new
      @false = Sakushi::False.new
      @nil = Sakushi::Nil.new
    end

    def repr(value)
      value.repr_itself self
    end

    attr_reader :true, :false, :nil

    def integer(n)
      Sakushi::Integer.new(n)
    end

    def float(x)
      Sakushi::Float.new(x)
    end

    def char(n)
      Sakushi::Char.new(n)
    end

    def string(s)
      Sakushi::String.new(s.freeze)
    end

    def intern(name)
      Sakushi::Symbol.new(name.intern)
    end

    def cons(car, cdr)
      Sakushi::Cell.new(car, cdr)
    end

    def list(*elements)
      elements.reverse_each.inject(nil()){|r, i| cons(i, r) }
    end

    def quote(exp)
      list intern(:quote), exp
    end
  end
end
