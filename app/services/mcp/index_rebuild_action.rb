# frozen_string_literal: true

require_relative "../notes_indexer"
require_relative "../index_store"

module Mcp
  class IndexRebuildAction
    def initialize(notes_root:)
      @indexer = NotesIndexer.new(notes_root: notes_root)
      @index_store = IndexStore.new(notes_root: notes_root)
    end

    def call
      index = @indexer.index
      @index_store.write(index)
      index.slice(:notes_indexed, :chunks_indexed)
    end
  end
end
