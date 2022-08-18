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

    def visit_expr(stmt)
      resolve(stmt.expr)
      nil
    end

    def visit_function(stmt)
      declare(stmt.name)
      define(stmt.name)

      resolve_function(stmt)
      nil
    end

    def visit_if(stmt)
      resolve(stmt.condition)
      resolve(stmt.then)
      resolve(stmt.else) if stmt.else
      nil
    end

    def visit_print(stmt)
      resolve(stmt.expr)
      nil
    end

    def visit_return(stmt)
      resolve(stmt.value) if stmt.value
      nil
    end

    def visit_var(stmt)
      declare(stmt.name)
      resolve(stmt.initializer) if stmt.initializer
      define(stmt.name)
      nil
    end

    def visit_while(stmt)
      resolve(stmt.condition)
      resolve(stmt.body)
      nil
    end

    def visit_variable(expr)
      if !@scopes.empty? && @scopes.last[expr.name.lexeme] == false
        raise ResolverError.new(expr.name, "Can't read local variable in its own initializer.")
      end

      resolve_local(expr, expr.name)
      nil
    end

    def visit_assign(expr)
      resolve(expr.value)
      resolve_local(expr, expr.name)
      nil
    end

    def visit_binary(expr)
      resolve(expr.left)
      resolve(expr.right)
      nil
    end

    def visit_call(expr)
      resolve(expr.callee, *expr.args)
      nil
    end

    def visit_grouping(expr)
      resolve(expr.expr)
      nil
    end

    def visit_literal(expr)
      nil
    end

    def visit_logical(expr)
      resolve(expr.left, expr.right)
      nil
    end

    def visit_unary(expr)
      resolve(expr.right)
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

    def resolve_function(fn)
      with_scope do
        fn.params.each do |param|
          declare(param)
          define(param)
        end
        resolve(fn.body)
      end
    end

  end
end
