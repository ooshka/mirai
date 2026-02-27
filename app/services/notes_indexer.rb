# frozen_string_literal: true

require_relative "notes_reader"
require_relative "notes_chunker"

class NotesIndexer
  def initialize(notes_root:, chunker: NotesChunker.new)
    @reader = NotesReader.new(notes_root: notes_root)
    @chunker = chunker
  end

  def index
    note_paths = @reader.list_notes
    chunks = []

    note_paths.each do |path|
      @chunker.chunk(@reader.read_note(path)).each_with_index do |content, chunk_index|
        chunks << {path: path, chunk_index: chunk_index, content: content}
      end
    end

    {
      notes_indexed: note_paths.size,
      chunks_indexed: chunks.size,
      chunks: chunks
    }
  end
end
