require_relative "../test_helper"

require "lox/ast_printer"
require "lox/parser"
require "lox/resolver"
require "lox/scanner"

class TestResolver < Lox::Test

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

  def test_same_var_name_in_scope
    assert_raises Lox::ResolverError do
      resolve(<<~SRC)
        fun bad() {
          var a = "first";
          var a = "second";
        }
      SRC
    end
  end

  def test_returning_from_top_level
    assert_raises Lox::ResolverError do
      resolve(<<~SRC)
        return;
      SRC
    end
  end

  private

  def assert_resolved(expected, src)
    resolves = resolve(src)

    ast_printer = Lox::AstPrinter.new
    assert_equal expected, resolves.map {|expr, depth|
      [ast_printer.print(expr), depth]
    }
  end

  def resolve(src)
    stmts = Lox::Parser.new(Lox::Scanner.new.scan(src)).parse!

    interpreter = Interpreter.new
    Lox::Resolver.new(interpreter).resolve(*stmts)

    interpreter.resolves
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
