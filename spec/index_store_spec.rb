# frozen_string_literal: true

require "tmpdir"
require "json"
require "time"
require "fileutils"
require_relative "../app/services/index_store"

RSpec.describe IndexStore do
  around do |example|
    Dir.mktmpdir("notes-root") do |notes_root|
      @notes_root = notes_root
      example.run
    end
  end

  it "writes and reads a deterministic artifact payload" do
    store = described_class.new(notes_root: @notes_root)
    generated_at = Time.utc(2026, 2, 28, 12, 0, 0)
    index_data = {
      notes_indexed: 1,
      chunks_indexed: 1,
      chunks: [{path: "root.md", chunk_index: 0, content: "alpha"}]
    }

    store.write(index_data, generated_at: generated_at)

    artifact_path = File.join(@notes_root, ".mirai", "index.json")
    expect(File.exist?(artifact_path)).to be(true)

    raw_payload = JSON.parse(File.read(artifact_path))
    expect(raw_payload).to eq(
      {
        "version" => 1,
        "generated_at" => "2026-02-28T12:00:00Z",
        "notes_indexed" => 1,
        "chunks_indexed" => 1,
        "chunks" => [
          {"path" => "root.md", "chunk_index" => 0, "content" => "alpha"}
        ]
      }
    )

    expect(store.read).to eq(
      {
        version: 1,
        generated_at: "2026-02-28T12:00:00Z",
        notes_indexed: 1,
        chunks_indexed: 1,
        chunks: [
          {path: "root.md", chunk_index: 0, content: "alpha"}
        ]
      }
    )
  end

  it "returns nil when artifact does not exist" do
    store = described_class.new(notes_root: @notes_root)

    expect(store.read).to be_nil
  end

  it "raises invalid artifact error for malformed JSON" do
    FileUtils.mkdir_p(File.join(@notes_root, ".mirai"))
    File.write(File.join(@notes_root, ".mirai", "index.json"), "{not-json")

    store = described_class.new(notes_root: @notes_root)

    expect { store.read }.to raise_error(described_class::InvalidArtifactError, "index artifact is invalid")
  end
end
