require 'set'

module Sakushi
  class Value
    def repr_itself(engine)
      to_s
    end
  end

  class True < Value
    def repr_itself(_)
      '#t'
    end
  end

  class False < Value
    def repr_itself(_)
      '#f'
    end
  end

  class Nil < Value
    def repr_itself(_)
      '()'
    end
  end

  class Integer < Value
    def initialize(n)
      @value = n
    end

    def repr_itself(_)
      @value.to_s 10
    end
  end

  class Float < Value
    def initialize(x)
      @value = x
    end

    def repr_itself(_)
      @value.to_s
    end
  end

  class Char < Value
    def initialize(c)
      @value = c
    end

    def repr_itself(_)
      "#\\#{@value.chr}"
    end
  end

  class String < Value
    def initialize(content)
      @content = content
    end

    def repr_itself(_)
      @content.inspect
    end
  end

  class Symbol < Value
    def initialize(name)
      @name = name
    end

    def repr_itself(_)
      @name.to_s
    end
  end

  class Cell < Value
    def initialize(car, cdr)
      @car = car
      @cdr = cdr
    end

    def repr_itself(engine, )
      "(#{repr_list_inner(engine, self, 5, Set.new).join(' ')})"
    end

    private

    def repr_list_inner(engine, cell, rec_rest, memo)
      if memo.include?(cell)
        rec_rest -= 1
        return ['...'] unless rec_rest > 0
      end
      memo << cell
      car = engine.repr(cell.car)
      case
      when cell.cdr.nil?
        [car]
      when cell.cdr.cell?
        [car, *repr_list_inner(engine, cell.cdr, rec_rest, memo)]
      else
        [car, '.', engine.repr(cell.cdr)]
      end
    end
  end
end

