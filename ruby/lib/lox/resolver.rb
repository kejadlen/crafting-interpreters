require_relative "error"

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

    def visit_variable(expr)
      if !@scopes.empty? && @scopes.last[expr.name.lexeme] == false
        raise ResolverError.new(expr.name, "Can't read local variable in its own initializer.")
      end

      resolve_local(expr, expr.name)
      nil
    end

    private

    def with_block
      @scopes.unshift({})
      yield
      @scopes.shift
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

    def resolve_local(expr, name)
      scope_and_depth = @scopes.each.with_index.find {|scope, depth| scope.has_key?(name.lexeme) }
      return unless scope_and_depth

      scope, depth = scope_and_depth
      @interpreter.resolve(expr, depth)
    end

  end
end
