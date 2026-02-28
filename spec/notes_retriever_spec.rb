# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require "time"
require_relative "../app/services/notes_retriever"
require_relative "../app/services/notes_chunker"
require_relative "../app/services/index_store"

RSpec.describe NotesRetriever do
  around do |example|
    Dir.mktmpdir("notes-root") do |notes_root|
      @notes_root = notes_root
      example.run
    end
  end

  it "returns deterministic ranking with stable tie-breakers" do
    File.write(File.join(@notes_root, "root.md"), "apple\napple\n")
    FileUtils.mkdir_p(File.join(@notes_root, "nested"))
    File.write(File.join(@notes_root, "nested/child.md"), "apple\n")

    retriever = described_class.new(
      notes_root: @notes_root,
      indexer: NotesIndexer.new(notes_root: @notes_root, chunker: NotesChunker.new(max_lines: 1))
    )

    result = retriever.query(text: "apple", limit: 10)

    expect(result).to eq(
      [
        {path: "nested/child.md", chunk_index: 0, content: "apple", score: 1},
        {path: "root.md", chunk_index: 0, content: "apple", score: 1},
        {path: "root.md", chunk_index: 1, content: "apple", score: 1}
      ]
    )
  end

  it "applies limit and excludes zero-score chunks" do
    File.write(File.join(@notes_root, "root.md"), "alpha beta\ngamma\n")
    File.write(File.join(@notes_root, "other.md"), "alpha delta\n")

    retriever = described_class.new(notes_root: @notes_root)
    result = retriever.query(text: "alpha beta", limit: 1)

    expect(result).to eq(
      [
        {path: "root.md", chunk_index: 0, content: "alpha beta\ngamma", score: 2}
      ]
    )
  end

  it "uses persisted artifact chunks before falling back to indexer" do
    store = IndexStore.new(notes_root: @notes_root)
    store.write(
      {
        notes_indexed: 1,
        chunks_indexed: 1,
        chunks: [{path: "cached.md", chunk_index: 0, content: "alpha beta"}]
      },
      generated_at: Time.utc(2026, 2, 28, 12, 0, 0)
    )

    indexer = instance_double(NotesIndexer)
    allow(indexer).to receive(:index).and_raise("should not call indexer")

    retriever = described_class.new(notes_root: @notes_root, indexer: indexer)
    result = retriever.query(text: "alpha", limit: 5)

    expect(result).to eq(
      [
        {path: "cached.md", chunk_index: 0, content: "alpha beta", score: 1}
      ]
    )
  end

  it "falls back to indexer when persisted artifact is missing" do
    indexer = instance_double(NotesIndexer)
    allow(indexer).to receive(:index).and_return(
      {
        notes_indexed: 1,
        chunks_indexed: 1,
        chunks: [{path: "fallback.md", chunk_index: 0, content: "alpha"}]
      }
    )

    retriever = described_class.new(notes_root: @notes_root, indexer: indexer)
    result = retriever.query(text: "alpha", limit: 5)

    expect(result).to eq(
      [
        {path: "fallback.md", chunk_index: 0, content: "alpha", score: 1}
      ]
    )
  end
end
