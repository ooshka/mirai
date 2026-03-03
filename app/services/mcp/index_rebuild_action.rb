# frozen_string_literal: true

require_relative "../indexing/notes_indexer"
require_relative "../indexing/index_store"
require_relative "../notes/notes_operation_lock"

module Mcp
  class IndexRebuildAction
    def initialize(
      notes_root:,
      indexer: NotesIndexer.new(notes_root: notes_root),
      index_store: IndexStore.new(notes_root: notes_root),
      operation_lock: NotesOperationLock.new(notes_root: notes_root)
    )
      @indexer = indexer
      @index_store = index_store
      @operation_lock = operation_lock
    end

    def call
      @operation_lock.with_exclusive_lock do
        index = @indexer.index
        @index_store.write(index)
        index.slice(:notes_indexed, :chunks_indexed)
      end
    end
  end
end
