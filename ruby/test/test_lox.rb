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

  def test_returns_tokens
    scanner = Mocktail.of(Lox::Scanner)
    runner = Lox::Runner.new(scanner:)
    stubs { scanner.scan("src") }.with { %w[ some tokens ] }

    tokens = runner.run("src")

    assert_equal %w[ some tokens ], tokens
  end
end

