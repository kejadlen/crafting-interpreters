require_relative "environment"

module Lox
  class Function
    def initialize(decl)
      @decl = decl
    end

    def arity = @decl.params.size

    def call(interpreter, args)
      env = Environment.new(interpreter.globals)
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
