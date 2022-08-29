require_relative "environment"
require_relative "function"
require_relative "lox_class"

module Lox
  class Interpreter

    attr_reader :globals

    def initialize(env=Environment.new)
      @globals = env
      @env = @globals
      @locals = {}

      # We do **NOT** want struct equality for getting the depth of a local
      # since we can have multiple locals referencing the same variable in
      # different scopes on a single line.
      @locals.compare_by_identity

      @globals.define("clock", Class.new {
        def arity = 0
        def call(*) = Time.now.to_f
        def to_s = "<native fn>"
      })
    end

    # The book does printing and error catching here, but
    # we're going to do it in the runner instead.
    def interpret(stmts)
      stmts.each do |stmt|
        execute(stmt)
      end
    end

    def evaluate(expr) = expr.accept(self)
    def execute(stmt) = stmt.accept(self)

    def resolve(expr, depth)
      @locals[expr] = depth
    end

    def visit_block(stmt)
      execute_block(stmt.stmts, Environment.new(@env))
      nil
    end

    def visit_class(stmt)
      @env.define(stmt.name.lexeme, nil)
      klass = LoxClass.new(stmt.name.lexeme)
      @env.assign(stmt.name, klass)
      nil
    end

    def execute_block(stmts, env)
      prev_env = @env
      @env = env

      stmts.each do |stmt|
        execute(stmt)
      end
    ensure
      @env = prev_env
    end

    def visit_expr(expr)
      evaluate(expr.expr)
      nil
    end

    def visit_function(stmt)
      function = Function.new(stmt, @env)
      @env.define(stmt.name.lexeme, function)
      nil
    end

    def visit_if(stmt)
      if truthy?(evaluate(stmt.cond))
        evaluate(stmt.then)
      elsif stmt.else
        evaluate(stmt.else)
      end
      nil
    end

    def visit_print(expr)
      puts stringify(evaluate(expr.expr))
      nil
    end

    def visit_return(stmt)
      value = stmt.value ? evaluate(stmt.value) : nil

      throw(:return, value)
    end

    def visit_var(stmt)
      value = stmt.initializer&.yield_self { evaluate(_1) }
      @env.define(stmt.name.lexeme, value)
      nil
    end

    def visit_while(stmt)
      while truthy?(evaluate(stmt.cond))
        execute(stmt.body)
      end
      nil
    end

    def visit_grouping(expr) = evaluate(expr.expr)
    def visit_literal(expr)  = expr.value

    def visit_logical(expr)
      left = evaluate(expr.left)

      if expr.op.type == :OR
        return left if truthy?(left)
      else
        return left unless truthy?(left)
      end

      evaluate(expr.right)
    end

    def visit_unary(expr)
      right = evaluate(expr.right)

      case expr.op.type
      when :MINUS
        check_number_operand!(expr.op, right)
        -right
      when :BANG  then !truthy?(right)
      else fail
      end
    end

    def visit_variable(expr)
      lookup_var(expr.name, expr)
    end

    def lookup_var(name, expr)
      if @locals.has_key?(expr)
        distance = @locals.fetch(expr)
        @env.get_at(distance, name.lexeme)
      else
        @globals.get(name)
      end
    end

    def visit_assign(expr)
      value = evaluate(expr.value)

      if @locals.has_key?(expr)
        distance = @locals.fetch(expr)
        @env.assign_at(distance, expr.name, value)
      else
        @globals.assign(expr.name, value)
      end

      value
    end

    def visit_binary(expr)
      left = evaluate(expr.left)
      right = evaluate(expr.right)

      case expr.op.type
      when :GREATER
        check_number_operands!(expr.op, left, right)
        left > right
      when :GREATER_EQUAL
        check_number_operands!(expr.op, left, right)
        left >= right
      when :LESS
        check_number_operands!(expr.op, left, right)
        left < right
      when :LESS_EQUAL
        check_number_operands!(expr.op, left, right)
        left <= right
      when :BANG_EQUAL    then left != right
      when :EQUAL_EQUAL   then left == right
      when :MINUS
        check_number_operands!(expr.op, left, right)
        left - right
      when :PLUS
        unless left.is_a?(Float) && right.is_a?(Float) || left.is_a?(String) && right.is_a?(String)
          raise RuntimeError.new(expr.op, "Operands must be two numbers or two strings.")
        end
        left + right
      when :SLASH
        check_number_operands!(expr.op, left, right)
        left / right
      when :STAR
        check_number_operands!(expr.op, left, right)
        left * right
      else fail
      end
    end

    def visit_call(expr)
      func = evaluate(expr.callee)
      args = expr.args.map { evaluate(_1) }

      raise RuntimeError.new(expr.paren, "Can only call functions and classes.") unless func.respond_to?(:call)
      raise RuntimeError.new(expr.paren, "Expected #{func.arity} arguments but got #{args.size}.") unless args.size == func.arity

      func.call(self, args)
    end

    private

    def truthy?(value) = !!value

    def check_number_operand!(token, operand)
      return if operand.is_a?(Float)

      raise RuntimeError.new(token, "Operand must be a number.")
    end

    def check_number_operands!(token, left, right)
      return if left.is_a?(Float) && right.is_a?(Float)

      raise RuntimeError.new(token, "Operands must be numbers.")
    end

    def stringify(value)
      return "nil" if value.nil?
      return value.to_s.sub(/\.0$/, "") if value.is_a?(Float)
      value.to_s
    end
  end
end
