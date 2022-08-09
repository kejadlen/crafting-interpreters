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

      @values.fetch(name) {
        raise RuntimeError.new(token, "Undefined variable '#{name}'.") if @enclosing.nil?

        @enclosing.get(token)
      }
    end

    def assign(name, value)
      lexeme = name.lexeme

      if @values.has_key?(lexeme)
        @values[lexeme] = value
        return
      end

      unless @enclosing.nil?
        @enclosing.assign(name, value)
        return
      end

      raise RuntimeError.new(name, "Undefined variable '#{lexeme}'.")
    end
  end
end
