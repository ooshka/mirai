# frozen_string_literal: true

require_relative "../patch_validator"

module Mcp
  class PatchProposeAction
    def initialize(notes_root:)
      @validator = PatchValidator.new(notes_root: notes_root)
    end

    def call(patch:)
      @validator.validate(patch).slice(:path, :hunk_count, :net_line_delta)
    end
  end
end
