require "minitest/autorun"

require "lox"

require "open3"
require "pry"

class TestLox < Minitest::Test
  def test_error_on_more_than_one_arg
    o, s = Open3.capture2("./lox.rb foo bar")
    assert_equal 64, s.exitstatus
    assert_equal "Usage: ./lox.rb [script]\n", o
  end
end
