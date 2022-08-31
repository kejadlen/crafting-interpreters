require_relative "instance"

module Lox
  class LoxClass

    attr_reader :name

    def initialize(name, superclass, methods)
      @name, @superclass, @methods = name, superclass, methods
    end

    def find_method(name)
      @methods.fetch(name) { @superclass&.find_method(name) }
    end

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
