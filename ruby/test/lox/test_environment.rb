require_relative "../test_helper"

require "lox/environment"
require "lox/error"
require "lox/token"

class TestEnvironment < Lox::Test
  def setup
    @env = Lox::Environment.new
  end

  def test_define
    @env.define("name", "value")

    assert_equal "value", @env.get(Lox::Token.new(:IDENTIFIER, "name", "name", 0))
  end

  def test_get
    assert_raises Lox::RuntimeError, "Undefined variable name 'name'." do
      @env.get(Lox::Token.new(:IDENTIFIER, "name", "name", 0))
    end
  end
end
