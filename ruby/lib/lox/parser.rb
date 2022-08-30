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
    rescue ParseError => e
      $stderr.puts e.message
      synchronize!
    end

    private

    def declaration
      return class_decl if match?(:CLASS)
      return function("function") if match?(:FUN)
      return var_declaration if match?(:VAR)

      statement
    end

    def class_decl
      name = consume!(:IDENTIFIER, "Expect class name.")

      superclass = if match?(:LESS)
                     consume!(:IDENTIFIER, "Expect superclass name.")
                     Expr::Variable.new(prev)
                   else
                     nil
                   end

      consume!(:LEFT_BRACE, "Expect '{' before class body.")

      methods = []
      until check?(:RIGHT_BRACE) || eot?
        methods << function("method")
      end

      consume!(:RIGHT_BRACE, "Expect '}' after class body.")

      Stmt::Class.new(name, superclass, methods)
    end

    def var_declaration
      name = consume!(:IDENTIFIER, "Expect variable name.")
      initializer = match?(:EQUAL) ? expression : nil
      consume!(:SEMICOLON, "Expect ';' after variable declaration.")

      Stmt::Var.new(name, initializer)
    end

    def while_stmt
      consume!(:LEFT_PAREN, "Expect '(' after 'if'.")
      cond = expression
      consume!(:RIGHT_PAREN, "Expect ')' after 'if'.")
      body = statement

      Stmt::While.new(cond, body)
    end

    def statement
      return for_stmt if match?(:FOR)
      return if_stmt if match?(:IF)
      return print if match?(:PRINT)
      return return_stmt if match?(:RETURN)
      return while_stmt if match?(:WHILE)
      return Stmt::Block.new(block) if match?(:LEFT_BRACE)

      expression_stmt
    end

    def for_stmt
      consume!(:LEFT_PAREN, "Expect '(' after 'if'.")

      initializer = if match?(:SEMICOLON)
                      nil
                    elsif match?(:VAR)
                      var_declaration
                    else
                      expression_stmt
                    end

      condition = check?(:SEMICOLON) ? Expr::Literal.new(true) : expression
      consume!(:SEMICOLON, "Expect ';' after loop condition.")

      increment = check?(:RIGHT_PAREN) ? nil : expression
      consume!(:RIGHT_PAREN, "Expect ')' after for clauses.")

      body = statement

      if increment
        body = Stmt::Block.new([
          body,
          Stmt::Expr.new(increment),
        ])
      end

      body = Stmt::While.new(condition, body);

      if initializer
        body = Stmt::Block.new([
          initializer,
          body,
        ])
      end

      body
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

    def return_stmt
      keyword = prev
      value = check?(:SEMICOLON) ? nil : expression
      consume!(:SEMICOLON, "Expect ';' after return value.")
      Stmt::Return.new(keyword, value)
    end

    def expression_stmt
      value = expression
      consume!(:SEMICOLON, "Expect ';' after value.")
      Stmt::Expr.new(value)
    end

    def function(kind)
      name = consume!(:IDENTIFIER, "Expect #{kind} name.")
      consume!(:LEFT_PAREN, "Expect '(' after #{kind} name.")
      params = []
      unless check?(:RIGHT_PAREN)
        loop do
          raise ParseError.new(peek, "Can't have more than 255 parameters.") if params.size >= 255

          params << consume!(:IDENTIFIER, "Expect parameter name.")
          break unless match?(:COMMA)
        end
      end
      consume!(:RIGHT_PAREN, "Expect ')' after parameters.")

      consume!(:LEFT_BRACE, "Expect '{' before #{kind} body.")
      body = block

      Stmt::Function.new(name, params, body)
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

      return expr unless match?(:EQUAL)

      eq = prev
      value = assignment

      case expr
      when Expr::Variable
        Expr::Assign.new(expr.name, value)
      when Expr::Get
        Expr::Set.new(expr.object, expr.name, value)
      else
        raise ParseError.new(eq, "Invalid assignment target.")
      end
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
      return call unless match?(:BANG, :MINUS)

      op = prev
      right = unary
      Expr::Unary.new(op, right)
    end

    def call
      expr = primary

      loop do
        if match?(:LEFT_PAREN)
          expr = finish_call(expr)
        elsif match?(:DOT)
          name = consume!(:IDENTIFIER, "Expect property name after '.'.")
          expr = Expr::Get.new(expr, name)
        else
          break
        end
      end

      expr
    end

    def finish_call(callee)
      args = []
      if !check?(:RIGHT_PAREN)
        loop do
          raise ParseError.new(peek,  "Can't have more than 255 arguments.") if args.size >= 255

          args << expression
          break unless match?(:COMMA)
        end
      end

      paren = consume!(:RIGHT_PAREN, "Expect ')' after arguments.")

      Expr::Call.new(callee, paren, args)
    end

    def primary
      return Expr::Literal.new(false) if match?(:FALSE)
      return Expr::Literal.new(true) if match?(:TRUE)
      return Expr::Literal.new(nil) if match?(:NIL)
      return Expr::Literal.new(prev.literal) if match?(:NUMBER, :STRING)
      return Expr::This.new(prev) if match?(:THIS)
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
