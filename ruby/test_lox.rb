require "lox"

require "open3"

require "minitest/autorun"
require "mocktail"
require "pry"

class TestLox < Minitest::Test
  def test_error_on_more_than_one_arg
    o, s = Open3.capture2("./lox.rb foo bar")
    assert_equal 64, s.exitstatus
    assert_equal "Usage: ./lox.rb [script]\n", o
  end
end

class TestRunner < Minitest::Test
  include Mocktail::DSL

  def teardown
    Mocktail.reset
  end

  def test_returns_tokens
    scanner = Mocktail.of(Lox::Scanner)
    runner = Lox::Runner.new(scanner:)
    stubs { scanner.scan("src") }.with { %w[ some tokens ] }

    tokens = runner.run("src")

    assert_equal %w[ some tokens ], tokens
  end
end
