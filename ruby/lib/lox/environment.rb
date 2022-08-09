module Lox
  class Environment
    def initialize
      @values = {}
    end

    def define(name, value)
      @values[name] = value
    end

    def get(token)
      name = token.lexeme

      @values.fetch(name) { raise RuntimeError.new(token, "Undefined variable '#{name}'.") }
    end
  end
end
