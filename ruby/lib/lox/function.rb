require_relative "environment"

module Lox
  class Function
    def initialize(decl, closure)
      @decl, @closure = decl, closure
    end

    def arity = @decl.params.size

    def call(interpreter, args)
      env = Environment.new(@closure)
      @decl.params.map(&:lexeme).zip(args).each do |name, value|
        env.define(name, value)
      end

      catch(:return) {
        interpreter.execute_block(@decl.body, env)
      }
    end

    def to_s = "<fn #{@decl.name.lexeme}>"
  end
end
