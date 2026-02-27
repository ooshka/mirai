# frozen_string_literal: true

require_relative "../notes_indexer"

module Mcp
  class IndexRebuildAction
    def initialize(notes_root:)
      @indexer = NotesIndexer.new(notes_root: notes_root)
    end

    def call
      @indexer.index.slice(:notes_indexed, :chunks_indexed)
    end
  end
end
