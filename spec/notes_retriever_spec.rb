# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require_relative "../app/services/notes_retriever"
require_relative "../app/services/notes_chunker"

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
end
