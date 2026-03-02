# frozen_string_literal: true

require_relative "../patch_applier"
require_relative "../index_store"
require_relative "../notes_operation_lock"

module Mcp
  class PatchApplyAction
    def initialize(
      notes_root:,
      applier: PatchApplier.new(notes_root: notes_root),
      index_store: IndexStore.new(notes_root: notes_root),
      operation_lock: NotesOperationLock.new(notes_root: notes_root)
    )
      @applier = applier
      @index_store = index_store
      @operation_lock = operation_lock
    end

    def call(patch:)
      @operation_lock.with_exclusive_lock do
        result = @applier.apply(patch)
        @index_store.delete
        result
      end
    end
  end
end
