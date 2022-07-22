module Lox
  class Error < StandardError
    def initialize(line, where="", message)
      error = "Error"
      error << " #{where}" unless where.empty?

      super("[line #{line}] #{error}: #{message}")
    end
  end
end
