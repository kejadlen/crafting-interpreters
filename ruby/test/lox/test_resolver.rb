require_relative "../test_helper"

require "lox/ast_printer"
require "lox/parser"
require "lox/resolver"
require "lox/scanner"

class TestResolver < Lox::Test

  def setup
    @ast_printer = Lox::AstPrinter.new
    @scanner = Lox::Scanner.new
    @interpreter = Interpreter.new
    @resolver = Lox::Resolver.new(@interpreter)
  end

  def test_resolver
    assert_resolved [
      ["(var j)", 0],
      ["(var j)", 2],
      ["(var j)", 1],
      ["(assign j (+ (var j) 1.0))", 1],
      ["(var k)", 0],
      ["(var k)", 2],
      ["(var k)", 1],
      ["(assign k (+ (var k) 1.0))", 1],
    ], <<~SRC
      var i = 0;
      while (i < 3) {
        print i;
        i = i + 1;
      }

      for(var j=0; j<3; j=j+1) {
        print j;
      }

      {
        var k = 0;
        while (k < 3) {
          {
            print k;
          }
          k = k + 1;
        }
      }
    SRC
  end

  private

  def assert_resolved(expected, src)
    stmts = Lox::Parser.new(@scanner.scan(src)).parse!
    @resolver.resolve(*stmts);

    assert_equal expected, @interpreter.resolves.map {|expr, depth|
      [@ast_printer.print(expr), depth]
    }
  end

  class Interpreter
    attr_reader :resolves

    def initialize
      @resolves = []
    end

    def resolve(expr, depth)
      resolves << [expr, depth]
    end
  end

end
