#!/usr/bin/env ruby -w

require_relative "lox/ast_printer"
require_relative "lox/error"
require_relative "lox/expr"
require_relative "lox/interpreter"
require_relative "lox/parser"
require_relative "lox/scanner"
require_relative "lox/token"

module Lox
  class Runner
    def initialize(scanner: Scanner.new, interpreter: Interpreter.new)
      @scanner, @interpreter = scanner, interpreter
    end

    def run(src) = interpret(parse(scan(src)))

    def scan(src) = @scanner.scan(src)
    def parse(tokens) = Parser.new(tokens).parse!
    def resolve(stmts) = Resolver.new(@interpreter).resolve(*stmts)
    def interpret(stmts) = @interpreter.interpret(stmts)
  end

  class FileRunner < Runner
    def run(src)
      super
    rescue Lox::ParseError => e
      STDERR.puts e.message
      exit 65
    rescue Lox::RuntimeError => e
      STDERR.puts e.message, "[line #{e.token.line}]"
      exit 70
    end
  end

  class PromptRunner < Runner
    def initialize
      super(interpreter: Interpreter.new(Environment.new))
    end

    def run(src)
      super
    rescue Lox::ParseError, Lox::RuntimeError => e
      STDERR.puts e.message
    end

    def parse(tokens)
      stmts = Parser.new(tokens).parse!
      if stmts.last.instance_of?(Stmt::Expr)
        stmts << Stmt::Print.new(stmts.pop.expr)
      end
      stmts
    end
  end
end
