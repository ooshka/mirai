# frozen_string_literal: true

require_relative "../patch_applier"

module Mcp
  class PatchApplyAction
    def initialize(notes_root:)
      @applier = PatchApplier.new(notes_root: notes_root)
    end

    def call(patch:)
      @applier.apply(patch)
    end
  end
end
