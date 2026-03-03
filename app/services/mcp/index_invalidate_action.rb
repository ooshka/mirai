# frozen_string_literal: true

require_relative "../indexing/index_store"
require_relative "../notes/notes_operation_lock"

module Mcp
  class IndexInvalidateAction
    def initialize(
      notes_root:,
      index_store: IndexStore.new(notes_root: notes_root),
      operation_lock: NotesOperationLock.new(notes_root: notes_root)
    )
      @index_store = index_store
      @operation_lock = operation_lock
    end

    def call
      @operation_lock.with_exclusive_lock do
        {invalidated: @index_store.delete}
      end
    end
  end
end
