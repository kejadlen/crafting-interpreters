require_relative "test_helper"

require "lox"

require "open3"

require "mocktail"

class TestLox < Lox::Test
  def test_error_on_more_than_one_arg
    lox_path = File.expand_path("../bin/lox", __dir__)
    o, s = Open3.capture2(lox_path, "foo", "bar")
    assert_equal 64, s.exitstatus
    assert_equal "Usage: #{lox_path} [script]\n", o
  end
end

class TestRunner < Lox::Test
  include Mocktail::DSL

  def teardown
    Mocktail.reset
  end

  # This test sucks, but we'll live with it just not
  # exploding our runner for now.
  def test_prints
    scanner = Mocktail.of(Lox::Scanner)
    parser = Mocktail.of(Lox::Parser)
    runner = Lox::Runner.new(scanner, parser)
    stubs { scanner.scan("src") }.with { %w[ some tokens ] }
    stubs { parser.parse(%w[ some tokens ]) }.with { Lox::Expr::Literal.new("foo") }

    runner.run("src")
  end
end
