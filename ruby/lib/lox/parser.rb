require_relative "error"
require_relative "expr"
require_relative "stmt"

module Lox
  class Parser

    def initialize(tokens)
      @tokens = tokens
      @current = 0
    end

    def parse!
      statements = []
      until eot?
        statements << statement
      end
      statements
    end

    private

    def statement
      return print if match?(:PRINT)

      expressionStmt
    end

    def print
      value = expression
      consume!(:SEMICOLON, "Expect ';' after value.")
      Stmt::Print.new(value)
    end

    def expressionStmt
      value = expression
      consume!(:SEMICOLON, "Expect ';' after value.")
      Stmt::Expr.new(value)
    end

    def expression = equality

    def equality
      expr = comparison

      while match?(:BANG_EQUAL, :EQUAL_EQUAL)
        op = prev
        right = comparison
        expr = Expr::Binary.new(expr, op, right)
      end

      expr
    end

    def comparison
      expr = term

      while match?(:GREATER, :GREATER_EQUAL, :LESS, :LESS_EQUAL)
        op = prev
        right = term
        expr = Expr::Binary.new(expr, op, right)
      end

      expr
    end

    def term
      expr = factor

      while match?(:MINUS, :PLUS)
        op = prev
        right = factor
        expr = Expr::Binary.new(expr, op, right)
      end

      expr
    end

    def factor
      expr = unary

      while match?(:SLASH, :STAR)
        op = prev
        right = unary
        expr = Expr::Binary.new(expr, op, right)
      end

      expr
    end

    def unary
      return primary unless match?(:BANG, :MINUS)

      op = prev
      right = unary
      Expr::Unary.new(op, right)
    end

    def primary
      return Expr::Literal.new(false) if match?(:FALSE)
      return Expr::Literal.new(true) if match?(:TRUE)
      return Expr::Literal.new(nil) if match?(:NIL)
      return Expr::Literal.new(prev.literal) if match?(:NUMBER, :STRING)

      if match?(:LEFT_PAREN)
        expr = expression
        consume!(:RIGHT_PAREN, "Expect ')' after expression.")
        return Expr::Grouping.new(expr)
      end

      raise ParseError.new(peek, "Expect expression.")
    end

    private

    def match?(*types)
      return false unless check?(*types)

      advance!
      return true
    end

    def consume!(type, message)
      raise ParseError.new(peek, message) unless check?(type)

      advance!
    end

    def check?(*types)
      return false if eot?

      types.include?(peek.type)
    end

    def advance!
      @current += 1 unless eot?
      prev
    end

    def eot? = peek.type === :EOF
    def peek = @tokens.fetch(@current)
    def prev = @tokens.fetch(@current - 1)

    def synchronize!
      advance!

      until eot?
        return if prev.type == :SEMICOLON
        return if %i[CLASS FUN VAR FOR IF WHILE PRINT RETURN].include?(peek.type)

        advance!
      end
    end
  end

end
