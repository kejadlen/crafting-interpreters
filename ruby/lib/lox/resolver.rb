module Lox
  class Resolver

    def initialize(interpreter)
      @interpreter = interpreter

      @scopes = []
    end

    def resolve(*values)
      values.each do
        value.accept(self)
      end
    end

    def visit_block(stmt)
      with_scope do
        resolve(*stmt.stmts)
      end
      nil
    end

    def visit_var(stmt)
      declare(stmt.name)
      resolve(stmt.initializer) if stmt.initializer
      define(stmt.name)
      nil
    end

    private

    def with_block
      @scopes.push({})
      yield
      @scopes.pop
    end

    def declare(name)
      scope = @scopes.last
      return if scope.nil?

      scope[name.lexeme] = false
    end

    def define(name)
      scope = @scopes.last
      return if scope.nil?

      scopes[name.lexeme] = true
    end

  end
end
