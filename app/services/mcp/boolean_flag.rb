# frozen_string_literal: true

module Mcp
  module BooleanFlag
    module_function

    def enabled?(value)
      value.to_s.strip.downcase == "true"
    end
  end
end
