require_relative "environment"

module Lox
  class Function
    def initialize(decl, closure, is_initializer)
      @decl, @closure, @is_initializer = decl, closure, is_initializer
    end

    def bind(instance)
      env = Environment.new(@closure)
      env.define("this", instance)
      Function.new(@decl, env, @is_initializer)
    end

    def arity = @decl.params.size

    def call(interpreter, args)
      env = Environment.new(@closure)
      @decl.params.map(&:lexeme).zip(args).each do |name, value|
        env.define(name, value)
      end

      return_value = catch(:return) {
        interpreter.execute_block(@decl.body, env)
      }

      return @closure.get_at(0, "this") if @is_initializer

      return_value
    end

    def to_s = "<fn #{@decl.name.lexeme}>"
  end
end
