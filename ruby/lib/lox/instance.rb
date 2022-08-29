require_relative "error"

module Lox
  class Instance

    def initialize(klass)
      @klass = klass

      @fields = {}
    end

    def get(name)
      raise RuntimeError.new(name, "Undefined property '#{name.lexeme}'.") unless @fields.has_key?(name.lexeme)

      @fields.fetch(name.lexeme)
    end

    def set(name, value)
      @fields[name.lexeme] = value
    end

    def to_s = "#{@klass.name} instance"

  end
end
