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
        statements << declaration
      end
      statements
    end

    private

    def declaration
      return var_declaration if match?(:VAR)

      statement
    rescue ParseError
      synchronize!
    end

    def var_declaration
      name = consume!(:IDENTIFIER, "Expect variable name.")
      initializer = match?(:EQUAL) ? expression : nil
      consume!(:SEMICOLON, "Expect ';' after variable declaration.")

      Stmt::Var.new(name, initializer)
    end

    def statement
      return if_stmt if match?(:IF)
      return print if match?(:PRINT)
      return Stmt::Block.new(block) if match?(:LEFT_BRACE)

      expression_stmt
    end

    def if_stmt
      consume!(:LEFT_PAREN, "Expect '(' after 'if'.")
      cond = expression
      consume!(:RIGHT_PAREN, "Expect ')' after 'if'.")

      then_stmt = statement
      else_stmt = match?(:ELSE) ? statement : nil

      Stmt::If.new(cond, then_stmt, else_stmt)
    end

    def print
      value = expression
      consume!(:SEMICOLON, "Expect ';' after value.")
      Stmt::Print.new(value)
    end

    def expression_stmt
      value = expression
      consume!(:SEMICOLON, "Expect ';' after value.")
      Stmt::Expr.new(value)
    end

    def block
      statements = []
      until check?(:RIGHT_BRACE) || eot?
        statements << declaration
      end
      consume!(:RIGHT_BRACE, "Expect '}' after block.")
      statements
    end

    def assignment
      expr = or_

      if match?(:EQUAL)
        eq = prev
        value = assignment

        raise ParseError.new(eq, "Invalid assignment target.") unless expr.instance_of?(Expr::Variable)

        return Expr::Assign.new(expr.name, value)
      end

      expr
    end

    def or_
      expr = and_

      while match?(:OR)
        op = prev
        right = and_
        expr = Expr::Logical.new(expr, op, right)
      end

      expr
    end

    def and_
      expr = equality

      while match?(:AND)
        op = prev
        right = equality
        expr = Expr::Logical.new(expr, op, right)
      end

      expr
    end

    def expression = assignment

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
      return Expr::Variable.new(prev) if match?(:IDENTIFIER)

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
