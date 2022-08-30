require_relative "../test_helper"

require "lox/interpreter"
require "lox/parser"
require "lox/resolver"
require "lox/scanner"

class TestInterpreter < Lox::Test
  def setup
    @scanner = Lox::Scanner.new
  end

  # def test_literal
  #   assert_evaluated(42.0, "42")
  # end

  def test_grouping
    assert_evaluated "42", "(42)"
  end

  def test_unary
    assert_evaluated "-42", "-42"
    assert_evaluated "false", "!42"
    assert_evaluated "false", "!true"
    assert_evaluated "true", "!false"
    assert_evaluated "true", "!nil"
  end

  def test_binary
    assert_evaluated "42", "100 - 58"
    assert_evaluated "42", "84 / 2"
    assert_evaluated "42", "21 * 2"

    # precedence
    assert_evaluated "42", "2 * 25 - 8"

    assert_evaluated "42", "40 + 2"
    assert_evaluated "42", "\"4\" + \"2\""

    assert_evaluated "true", "1 > 0"
    assert_evaluated "false", "0 > 0"
    assert_evaluated "false", "0 > 1"

    assert_evaluated "true", "1 >= 0"
    assert_evaluated "true", "0 >= 0"
    assert_evaluated "false", "0 >= 1"

    assert_evaluated "false", "1 < 0"
    assert_evaluated "false", "0 < 0"
    assert_evaluated "true", "0 < 1"

    assert_evaluated "false", "1 <= 0"
    assert_evaluated "true", "0 <= 0"
    assert_evaluated "true", "0 <= 1"

    assert_evaluated "true", "0 != 1"
    assert_evaluated "false", "0 != 0"
    assert_evaluated "false", "nil != nil"
    assert_evaluated "true", "nil != 1"

    assert_evaluated "false", "0 == 1"
    assert_evaluated "true", "0 == 0"
    assert_evaluated "true", "nil == nil"
    assert_evaluated "false", "nil == 1"
  end

  def test_errors
    [
      "-true",
      "12 > true",
      "true < 23",
      "false * 23",
      "false + 23",
    ].each do |src|
      assert_raises Lox::RuntimeError do
        assert_evaluated nil, src
      end
    end
  end

  def test_stringify
    assert_evaluated "nil", "nil"
    assert_evaluated "42", "42"
    assert_evaluated "42.1", "42.1"
    assert_evaluated "foo", "\"foo\""
  end

  def test_multiple_statements
    assert_interpreted <<~EXPECTED.chomp, <<~SRC
      one
      true
      3
    EXPECTED
      print "one";
      print true;
      print 2 + 1;
    SRC
  end

  def test_environment
    assert_interpreted <<~EXPECTED.chomp, <<~SRC
      3
    EXPECTED
      var a = 1;
      var b = 2;
      print a + b;
    SRC
  end

  def test_assignment
    assert_interpreted <<~EXPECTED.chomp, <<~SRC
      2
    EXPECTED
      var a = 1;
      print a = 2;
    SRC
  end

  def test_block
    assert_interpreted <<~EXPECTED.chomp, <<~SRC
      inner a
      outer b
      global c
      outer a
      outer b
      global c
      global a
      global b
      global c
    EXPECTED
      var a = "global a";
      var b = "global b";
      var c = "global c";
      {
        var a = "outer a";
        var b = "outer b";
        {
          var a = "inner a";
          print a;
          print b;
          print c;
        }
        print a;
        print b;
        print c;
      }
      print a;
      print b;
      print c;
    SRC
  end

  def test_uninitialized_vars_are_nil
    assert_interpreted <<~EXPECTED.chomp, <<~SRC
      nil
    EXPECTED
      var a;
      print a;
    SRC
  end

  def test_if
    assert_interpreted <<~EXPECTED.chomp, <<~SRC
      true
      false
    EXPECTED
      if (true)
        print "true";
      else
        print "false";

      if (false)
        print "true";
      else
        print "false";
    SRC
  end

  def test_logical
    assert_interpreted <<~EXPECTED.chomp, <<~SRC
      hi
      yes
    EXPECTED
      print "hi" or 2; // "hi".
      print nil or "yes"; // "yes".
    SRC
  end

  def test_while
    assert_interpreted <<~EXPECTED.chomp, <<~SRC
      0
      1
      2
    EXPECTED
      var a = 0;
      while (a < 3) {
        print a;
        a = a + 1;
      }
    SRC
  end

  def test_for
    assert_interpreted <<~EXPECTED.chomp, <<~SRC
      0
      1
      1
      2
      3
      5
      8
      13
      21
      34
    EXPECTED
      var a = 0;
      var temp;

      for (var b = 1; a < 50; b = temp + b) {
        print a;
        temp = a;
        a = b;
      }
    SRC
  end

  def test_function
    assert_interpreted <<~EXPECTED.chomp, <<~SRC
      Hi, Dear Reader!
    EXPECTED
      fun sayHi(first, last) {
        print "Hi, " + first + " " + last + "!";
      }

      sayHi("Dear", "Reader");
    SRC

    assert_interpreted <<~EXPECTED.chomp, <<~SRC
      0
      1
      2
    EXPECTED
      {
        var i = 0; while (i < 3) { { print i; } i = i + 1; }
      }
    SRC

    assert_interpreted <<~EXPECTED.chomp, <<~SRC
      0
      1
      2
    EXPECTED
      for (var i = 0; i < 3; i = i + 1) print i;
    SRC

    assert_interpreted <<~EXPECTED.chomp, <<~SRC
      0
      1
      1
      2
      3
      5
      8
    EXPECTED
      fun fib(n) {
        if (n <= 1) return n;
        return fib(n - 2) + fib(n - 1);
      }

      for (var i = 0; i < 7; i = i + 1) {
        print fib(i);
      }
    SRC
  end

  def test_local_functions_and_closures
    assert_interpreted <<~EXPECTED.chomp, <<~SRC
      1
      2
    EXPECTED
      fun makeCounter() {
        var i = 0;
        fun count() {
          i = i + 1;
          print i;
        }

        return count;
      }

      var counter = makeCounter();
      counter(); // "1".
      counter(); // "2".
    SRC
  end

  def test_resolver
    assert_interpreted <<~EXPECTED.chomp, <<~SRC
      1
    EXPECTED
      var foo = 1;
      {
        print foo;
        var foo = 2;
      }
    SRC
  end

  def test_class
    assert_interpreted "", <<~SRC
      class Breakfast {
        cook() {
          print "Eggs a-fryin'!";
        }

        serve(who) {
          print "Enjoy your breakfast, " + who + ".";
        }
      }
    SRC

    assert_interpreted "DevonshireCream", <<~SRC
      class DevonshireCream {
        serveOn() {
          return "Scones";
        }
      }

      print DevonshireCream; // Prints "DevonshireCream".
    SRC

    assert_interpreted "Bagel instance", <<~SRC
      class Bagel {}
      var bagel = Bagel();
      print bagel; // Prints "Bagel instance".
    SRC
  end

  def test_set
    assert_interpreted "bar", <<~SRC
      class Bagel {}
      var bagel = Bagel();
      bagel.foo = "bar";
      print bagel.foo;
    SRC
  end

  def test_class_methods
    assert_interpreted "Crunch crunch crunch!", <<~SRC
      class Bacon {
        eat() {
          print "Crunch crunch crunch!";
        }
      }

      Bacon().eat(); // Prints "Crunch crunch crunch!".
    SRC

    assert_interpreted "The German chocolate cake is delicious!", <<~SRC
      class Cake {
        taste() {
          var adjective = "delicious";
          print "The " + this.flavor + " cake is " + adjective + "!";
        }
      }

      var cake = Cake();
      cake.flavor = "German chocolate";
      cake.taste(); // Prints "The German chocolate cake is delicious!".
    SRC

    assert_interpreted "Thing instance", <<~SRC
      class Thing {
        getCallback() {
          fun localFunction() {
            print this;
          }

          return localFunction;
        }
      }

      var callback = Thing().getCallback();
      callback();
    SRC

    assert_interpreted "Jane", <<~SRC
      class Person {
        sayName() {
          print this.name;
        }
      }

      var jane = Person();
      jane.name = "Jane";

      var bill = Person();
      bill.name = "Bill";

      bill.sayName = jane.sayName;
      bill.sayName(); // "Jane"
    SRC
  end

  def test_invalid_this
    assert_raises Lox::ResolverError, "Can't use 'this' outside of a class." do
      interpret("print this;")
    end

    assert_raises Lox::ResolverError, "Can't use 'this' outside of a class." do
      interpret(<<~SRC)
        fun notAMethod() {
          print this;
        }
      SRC
    end
  end

  def test_init
    assert_interpreted <<~EXPECTED.chomp, <<~SRC
      Foo instance
      Foo instance
      Foo instance
    EXPECTED
      class Foo {
        init() {
          print this;
        }
      }

      var foo = Foo();
      print foo.init();
    SRC

    assert_raises Lox::ResolverError do
      interpret(<<~SRC)
        class Foo {
          init() {
            return "something else";
          }
        }
      SRC
    end

    assert_interpreted "", <<~SRC
      class Foo {
        init() {
          return;
        }
      }
    SRC
  end

  def test_inheritance
    assert_interpreted "", <<~SRC
      class Doughnut {}
      class BostonCream < Doughnut {}
    SRC

    assert_raises Lox::ResolverError do
      interpret("class Oops < Oops {}")
    end

    assert_raises Lox::RuntimeError do
      interpret(<<~SRC)
        var NotAClass = "I am totally not a class";

        class Subclass < NotAClass {} // ?!
      SRC
    end
  end

  private

  def assert_interpreted(expected, src)
    output = interpret(src)
    assert_equal expected, output
  end

  def assert_evaluated(expected, src)
    assert_interpreted(expected, "print #{src};")
  end

  def with_stdout
    original = $stdout
    $stdout = StringIO.new

    yield

    output = $stdout.string.chomp
    $stdout = original
    output
  end

  def interpret(src)
    with_stdout {
      stmts = Lox::Parser.new(@scanner.scan(src)).parse!
      interpreter = Lox::Interpreter.new

      resolver = Lox::Resolver.new(interpreter);
      resolver.resolve(*stmts);

      interpreter.interpret(stmts)
    }
  end

end
