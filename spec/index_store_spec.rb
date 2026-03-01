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

  it "returns missing status when artifact does not exist" do
    store = described_class.new(notes_root: @notes_root)

    expect(store.status).to eq(
      {
        present: false,
        generated_at: nil,
        notes_indexed: nil,
        chunks_indexed: nil,
        stale: nil,
        artifact_age_seconds: nil,
        notes_present: 0,
        artifact_byte_size: nil,
        chunks_content_bytes_total: nil
      }
    )
  end

  it "returns status metadata when artifact exists" do
    store = described_class.new(notes_root: @notes_root)
    File.write(File.join(@notes_root, "root.md"), "alpha\n")
    File.utime(Time.utc(2026, 2, 28, 11, 0, 0), Time.utc(2026, 2, 28, 11, 0, 0), File.join(@notes_root, "root.md"))
    store.write(
      {
        notes_indexed: 2,
        chunks_indexed: 3,
        chunks: [{path: "root.md", chunk_index: 0, content: "alpha"}]
      },
      generated_at: Time.utc(2026, 2, 28, 12, 0, 0)
    )
    artifact_path = File.join(@notes_root, ".mirai", "index.json")

    expect(store.status(now: Time.utc(2026, 2, 28, 12, 0, 30))).to eq(
      {
        present: true,
        generated_at: "2026-02-28T12:00:00Z",
        notes_indexed: 2,
        chunks_indexed: 3,
        stale: false,
        artifact_age_seconds: 30,
        notes_present: 1,
        artifact_byte_size: File.size(artifact_path),
        chunks_content_bytes_total: "alpha".bytesize
      }
    )
  end

  it "returns stale true when a note is newer than artifact generated_at" do
    store = described_class.new(notes_root: @notes_root)
    File.write(File.join(@notes_root, "root.md"), "alpha\n")
    File.utime(Time.utc(2026, 2, 28, 13, 0, 0), Time.utc(2026, 2, 28, 13, 0, 0), File.join(@notes_root, "root.md"))
    store.write(
      {
        notes_indexed: 1,
        chunks_indexed: 1,
        chunks: [{path: "root.md", chunk_index: 0, content: "alpha"}]
      },
      generated_at: Time.utc(2026, 2, 28, 12, 0, 0)
    )

    expect(store.status(now: Time.utc(2026, 2, 28, 12, 0, 5))).to eq(
      {
        present: true,
        generated_at: "2026-02-28T12:00:00Z",
        notes_indexed: 1,
        chunks_indexed: 1,
        stale: true,
        artifact_age_seconds: 5,
        notes_present: 1,
        artifact_byte_size: File.size(File.join(@notes_root, ".mirai", "index.json")),
        chunks_content_bytes_total: "alpha".bytesize
      }
    )
  end

  it "bounds artifact age at zero when generated_at is in the future" do
    store = described_class.new(notes_root: @notes_root)
    File.write(File.join(@notes_root, "root.md"), "alpha\n")
    store.write(
      {
        notes_indexed: 1,
        chunks_indexed: 1,
        chunks: [{path: "root.md", chunk_index: 0, content: "alpha"}]
      },
      generated_at: Time.utc(2026, 2, 28, 12, 0, 0)
    )

    status = store.status(now: Time.utc(2026, 2, 28, 11, 59, 50))

    expect(status[:artifact_age_seconds]).to eq(0)
    expect(status[:artifact_byte_size]).to be >= 0
    expect(status[:chunks_content_bytes_total]).to eq("alpha".bytesize)
  end

  it "deletes artifact and returns true when artifact exists" do
    store = described_class.new(notes_root: @notes_root)
    store.write(
      {
        notes_indexed: 1,
        chunks_indexed: 1,
        chunks: [{path: "root.md", chunk_index: 0, content: "alpha"}]
      }
    )

    expect(store.delete).to be(true)
    expect(store.read).to be_nil
  end

  it "returns false when deleting a missing artifact" do
    store = described_class.new(notes_root: @notes_root)

    expect(store.delete).to be(false)
  end

  it "raises invalid artifact error for malformed JSON" do
    FileUtils.mkdir_p(File.join(@notes_root, ".mirai"))
    File.write(File.join(@notes_root, ".mirai", "index.json"), "{not-json")

    store = described_class.new(notes_root: @notes_root)

    expect { store.read }.to raise_error(described_class::InvalidArtifactError, "index artifact is invalid")
  end

  it "raises invalid artifact error for stale artifact version" do
    FileUtils.mkdir_p(File.join(@notes_root, ".mirai"))
    File.write(
      File.join(@notes_root, ".mirai", "index.json"),
      JSON.pretty_generate(
        {
          "version" => 2,
          "generated_at" => "2026-02-28T12:00:00Z",
          "notes_indexed" => 1,
          "chunks_indexed" => 1,
          "chunks" => [
            {"path" => "cached.md", "chunk_index" => 0, "content" => "alpha beta"}
          ]
        }
      )
    )

    store = described_class.new(notes_root: @notes_root)

    expect { store.read }.to raise_error(described_class::InvalidArtifactError, "index artifact is invalid")
  end
end
