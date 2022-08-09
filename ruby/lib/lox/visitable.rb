module Lox
  module Visitable
    def accept(visitor)
      klass = self.class.to_s.split("::").last.downcase
      visitor.send("visit_#{klass}", self)
    end
  end
end
