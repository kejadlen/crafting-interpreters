require_relative "instance"

module Lox
  class LoxClass

    attr_reader :name

    def initialize(name, methods)
      @name, @methods = name, methods
    end

    def find_method(name) = @methods[name]
    def to_s = name

    def call(interpreter, args)
      instance = Instance.new(self)

      if init = find_method("init")
        init.bind(instance).call(interpreter, args)
      end

      instance
    end

    def arity
      init = find_method("init")
      init ? init.arity : 0
    end

  end
end
