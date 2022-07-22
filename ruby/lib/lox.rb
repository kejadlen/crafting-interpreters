#!/usr/bin/env ruby -w

require_relative "lox/ast_printer"
require_relative "lox/error"
require_relative "lox/expr"
require_relative "lox/parser"
require_relative "lox/scanner"
require_relative "lox/token"

module Lox
  class Runner
    def initialize(scanner=Scanner.new, parser=Parser.new)
      @scanner, @parser = scanner, parser
    end

    def run(src)
      tokens = @scanner.scan(src)
      expr = @parser.parse(tokens)

      puts AstPrinter.new.print(expr)
    rescue ParseError => e
      puts e.message
    end
  end
end
