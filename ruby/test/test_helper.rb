require "minitest"

module Lox
  class Test < Minitest::Test
    LOX_BIN = File.expand_path("../bin/lox", __dir__)

    def assert_lox(path)
      src = File.read(path)

      # https://github.com/munificent/craftinginterpreters/blob/master/tool/bin/test.dart#L12-L18
      expected_out = src.scan(/(?<=\/\/ expect: )(?~\n)/).join("\n")
      expected_err = src[/(?<=\/\/ expect runtime error: )(?~\n)/]

      out, err, _status = Open3.capture3(LOX_BIN, path)

      assert_equal expected_out, out
      assert_equal expected_err, err.lines(chomp: true)[0]
    end
  end

  if ENV.has_key?("LOX_TEST")
    book_src = File.expand_path(ENV.fetch("CRAFTING_INTERPRETERS_SRC"))
    Dir.chdir(book_src) do
      lox_tests = Dir["./test/**/*.lox"]
        .group_by {|path| path.rpartition(?/).first.sub(/\.\/test\/?/, "") }

      lox_tests.each do |dir, paths|
        klass = Class.new(Test) do
          paths.each do |path|
            name = File.basename(path, ".lox")
            define_method("test_#{name}") do
              assert_lox File.expand_path(path, book_src)
            end
          end
        end

        suite = dir.split(?/).map(&:capitalize).join
        suite = "Root" if suite.empty?
        Object.const_set("Test#{suite}", klass)
      end
    end
  end
end
