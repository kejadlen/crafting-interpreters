require_relative "error"

module Lox
  class Instance

    def initialize(klass)
      @klass = klass

      @fields = {}
    end

    def get(name)
      return @fields.fetch(name.lexeme) if @fields.has_key?(name.lexeme)

      method = @klass.find_method(name.lexeme)
      return method unless method.nil?

      raise RuntimeError.new(name, "Undefined property '#{name.lexeme}'.")
    end

    def set(name, value)
      @fields[name.lexeme] = value
    end

    def to_s = "#{@klass.name} instance"

  end
end
