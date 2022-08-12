require_relative "environment"

module Lox
  class Interpreter

    def initialize(env=Environment.new)
      @env = env
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

    def visit_block(stmt)
      execute_block(stmt.stmts, Environment.new(@env))
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

    def visit_var(stmt)
      value = stmt.initializer&.yield_self { evaluate(_1) }
      @env.define(stmt.name.lexeme, value)
      nil
    end

    def visit_grouping(expr) = evaluate(expr.expr)
    def visit_literal(expr)  = expr.value

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
      @env.get(expr.name)
    end

    def visit_assign(expr)
      value = evaluate(expr.value)
      @env.assign(expr.name, value)
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
