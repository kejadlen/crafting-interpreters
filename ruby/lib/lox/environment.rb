require_relative "error"

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

    def assign(name, value)
      raise RuntimeError.new(name, "Undefined variable '#{name.lexeme}'.") unless @values.has_key?(name.lexeme)

      @values[name.lexeme] = value
    end
  end
end
