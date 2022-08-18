require_relative "error"

module Lox
  class Environment
    attr_reader :values, :enclosing

    def initialize(enclosing = nil)
      @enclosing = enclosing
      @values = {}
    end

    def define(name, value)
      @values[name] = value
    end

    def ancestor(distance)
      env = self
      distance.times { env = env.enclosing }
      env
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

    def get_at(distance, name)
      ancestor(distance).values.fetch(name)
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
