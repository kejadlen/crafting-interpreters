module Lox
  class Resolver

    def initialize(interpreter)
      @interpreter = interpreter

      @scopes = []
    end

    def resolve(values)
      values.each do
        value.accept(self)
      end
    end

    def visit_block(stmt)
      with_scope do
        resolve(stmt.stmts)
      end
      nil
    end

    private

    def with_block
      @scopes.push({})
      yield
      @scopes.pop
    end


  end
end
