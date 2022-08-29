require_relative "instance"

module Lox
  class LoxClass

    attr_reader :name

    def initialize(name, methods)
      @name, @methods = name, methods
    end

    def find_method(name) = @methods[name]
    def to_s = name
    def call(interpreter, args) = Instance.new(self)
    def arity = 0

  end
end
