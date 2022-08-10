require_relative "error"

module Lox
  class Environment
    def initialize(enclosing = nil)
      @enclosing = enclosing
      @values = {}
    end

    def define(name, value)
      @values[name] = value
    end

    def get(token)
      name = token.lexeme

      if @values.has_key?(name)
        @values[name]
      elsif @enclosing
        @enclosing.get(token)
      else
        raise RuntimeError.new(token, "Undefined variable '#{name}'.")
      end
    end

    def assign(name, value)
      lexeme = name.lexeme

      if @values.has_key?(lexeme)
        @values[lexeme] = value
      elsif @enclosing
        @enclosing.assign(name, value)
      else
        raise RuntimeError.new(name, "Undefined variable '#{lexeme}'.")
      end
    end
  end
end
