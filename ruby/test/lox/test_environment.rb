require_relative "../test_helper"

require "lox/environment"
require "lox/error"
require "lox/token"

class TestEnvironment < Lox::Test
  NAME_TOKEN = Lox::Token.new(:IDENTIFIER, "name", "name", 0)

  def setup
    @env = Lox::Environment.new
  end

  def test_define
    @env.define("name", "value")

    assert_equal "value", @env.get(NAME_TOKEN)
  end

  def test_get
    assert_raises Lox::RuntimeError, "Undefined variable name 'name'." do
      @env.get(NAME_TOKEN)
    end
  end

  def test_enclosing_define
    @env.define("name", "value")
    enclosed = Lox::Environment.new(@env)
    assert_equal "value", enclosed.get(NAME_TOKEN)

    enclosed.define("name", "foo")
    assert_equal "foo", enclosed.get(NAME_TOKEN)
  end

  def test_enclosing_assign
    @env.define("name", "foo")
    enclosed = Lox::Environment.new(@env)
    enclosed.assign(NAME_TOKEN, "bar")
    assert_equal "bar", enclosed.get(NAME_TOKEN)
    assert_equal "bar", @env.get(NAME_TOKEN)

    enclosed.define("name", "baz")
    enclosed.assign(NAME_TOKEN, "qux")
    assert_equal "qux", enclosed.get(NAME_TOKEN)
    assert_equal "bar", @env.get(NAME_TOKEN)
  end

  def test_get_at
    @env.define("name", "foo")
    enclosed = Lox::Environment.new(@env)
    enclosed.define("name", "bar")

    assert_equal "foo", enclosed.get_at(1, "name")
    assert_equal "bar", enclosed.get_at(0, "name")

    assert_equal "foo", @env.get_at(0, "name")
  end

end
