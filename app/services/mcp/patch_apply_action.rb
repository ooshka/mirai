# frozen_string_literal: true

require_relative "../patch_applier"
require_relative "../index_store"

module Mcp
  class PatchApplyAction
    def initialize(notes_root:)
      @applier = PatchApplier.new(notes_root: notes_root)
      @index_store = IndexStore.new(notes_root: notes_root)
    end

    def call(patch:)
      result = @applier.apply(patch)
      @index_store.delete
      result
    end
  end
end
