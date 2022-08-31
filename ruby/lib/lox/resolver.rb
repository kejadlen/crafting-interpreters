require_relative "error"

module Lox
  class Resolver

    def initialize(interpreter)
      @interpreter = interpreter

      @scopes = []
      @current_func = :NONE
      @current_class = :NONE
    end

    def resolve(*resolvees)
      resolvees.each do |resolvee|
        resolvee.accept(self)
      end
      nil
    end

    def visit_block(stmt)
      with_scope do
        resolve(*stmt.stmts)
      end
      nil
    end

    def visit_class(stmt)
      with_current_class(:CLASS) do
        declare(stmt.name)
        define(stmt.name)

        with_superclass_scope = if stmt.superclass
                                  raise ResolverError.new(stmt.superclass.name, "A class can't inherit from itself.") if stmt.name.lexeme == stmt.superclass.name.lexeme
                                  resolve(stmt.superclass)
                                  ->(&block) { with_scope(super: true) { block.call } }
                                else
                                  ->(&block) { block.call }
                                end

        with_superclass_scope.call do
          with_scope(this: true) do
            stmt.methods.each do |method|
              decl = method.name.lexeme == "init" ? :INIT : :METHOD
              resolve_function(method, decl)
            end
          end
        end
      end

      nil
    end

    def visit_expr(stmt) = resolve(stmt.expr)

    def visit_function(stmt)
      declare(stmt.name)
      define(stmt.name)

      resolve_function(stmt, :FUNCTION)
      nil
    end

    def visit_if(stmt)
      resolve(stmt.cond, stmt.then)
      resolve(stmt.else) if stmt.else
    end

    def visit_print(stmt) = resolve(stmt.expr)

    def visit_return(stmt)
      raise ResolverError.new(stmt.keyword, "Can't return from top-level code.") if @current_func == :NONE

      return unless stmt.value

      raise ResolverError.new(stmt.keyword, "Can't return a value from an initializer.") if @current_func == :INIT

      resolve(stmt.value)
    end

    def visit_var(stmt)
      declare(stmt.name)
      resolve(stmt.initializer) if stmt.initializer
      define(stmt.name)
      nil
    end

    def visit_while(stmt) = resolve(stmt.cond, stmt.body)

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

    def visit_binary(expr) = resolve(expr.left, expr.right)
    def visit_call(expr) = resolve(expr.callee, *expr.args)

    def visit_get(expr)
      resolve(expr.object)
      nil
    end

    def visit_grouping(expr) = resolve(expr.expr)
    def visit_literal(expr) = nil
    def visit_logical(expr) = resolve(expr.left, expr.right)

    def visit_set(expr)
      resolve(expr.value)
      resolve(expr.object)
      nil
    end

    def visit_super(expr)
      resolve_local(expr, expr.keyword)
      nil
    end

    def visit_this(expr)
      raise ResolverError.new(expr.keyword, "Can't use 'this' outside of a class.") if @current_class == :NONE

      resolve_local(expr, expr.keyword)
      nil
    end

    def visit_unary(expr) = resolve(expr.right)

    private

    def with_scope(scope={})
      @scopes.push(scope.transform_keys(&:to_s))
      yield
      @scopes.pop
    end

    def declare(name)
      scope = @scopes.last
      return if scope.nil?

      raise ResolverError.new(name, "Already a variable with this name in this scope") if scope.has_key?(name.lexeme)

      scope[name.lexeme] = false
    end

    def define(name)
      scope = @scopes.last
      return if scope.nil?

      scope[name.lexeme] = true
    end

    def resolve_local(expr, name)
      scope_and_depth = @scopes.reverse.each.with_index.find {|scope, depth| scope.has_key?(name.lexeme) }
      return unless scope_and_depth

      scope, depth = scope_and_depth
      @interpreter.resolve(expr, depth)
    end

    def resolve_function(fn, type)
      with_func_type(type) do
        with_scope do
          fn.params.each do |param|
            declare(param)
            define(param)
          end
          resolve(*fn.body)
        end
      end
    end

    def with_func_type(type)
      enclosing_func = @current_func
      @current_func = type

      yield

      @current_func = enclosing_func
    end

    def with_current_class(type)
      enclosing_class = @current_class
      @current_class = type

      yield

      @current_class = enclosing_class
    end

  end
end
