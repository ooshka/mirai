# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require_relative "../app/services/notes_indexer"
require_relative "../app/services/notes_chunker"

RSpec.describe NotesIndexer do
  around do |example|
    Dir.mktmpdir("notes-root") do |notes_root|
      @notes_root = notes_root
      example.run
    end
  end

  it "returns zero counts for an empty notes root" do
    result = described_class.new(notes_root: @notes_root).index

    expect(result).to eq(
      {
        notes_indexed: 0,
        chunks_indexed: 0,
        chunks: []
      }
    )
  end

  it "indexes markdown notes with deterministic chunk ordering" do
    File.write(File.join(@notes_root, "root.md"), "one\ntwo\nthree\n")
    FileUtils.mkdir_p(File.join(@notes_root, "nested"))
    File.write(File.join(@notes_root, "nested/child.md"), "alpha\nbeta\n")

    indexer = described_class.new(
      notes_root: @notes_root,
      chunker: NotesChunker.new(max_lines: 2)
    )

    result = indexer.index

    expect(result).to eq(
      {
        notes_indexed: 2,
        chunks_indexed: 3,
        chunks: [
          {path: "nested/child.md", chunk_index: 0, content: "alpha\nbeta"},
          {path: "root.md", chunk_index: 0, content: "one\ntwo"},
          {path: "root.md", chunk_index: 1, content: "three"}
        ]
      }
    )
  end
end
