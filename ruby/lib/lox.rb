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
    def initialize
      @scanner = Scanner.new
      @parser = Parser.new
      @interpreter = Interpreter.new
    end

    def run(src)
      tokens = @scanner.scan(src)
      expr = @parser.parse(tokens)
      value = @interpreter.interpret(expr)

      puts value
    end
  end
end
