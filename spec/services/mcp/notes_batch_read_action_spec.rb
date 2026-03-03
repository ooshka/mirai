# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require_relative "../../../app/services/mcp/notes_batch_read_action"

RSpec.describe Mcp::NotesBatchReadAction do
  around do |example|
    Dir.mktmpdir("notes-root") do |notes_root|
      @notes_root = notes_root
      example.run
    end
  end

  it "returns ordered path/content notes" do
    File.write(File.join(@notes_root, "first.md"), "first")
    File.write(File.join(@notes_root, "second.md"), "second")
    action = described_class.new(notes_root: @notes_root)

    result = action.call(paths: ["second.md", "first.md"])

    expect(result).to eq(
      {
        notes: [
          {path: "second.md", content: "second"},
          {path: "first.md", content: "first"}
        ]
      }
    )
  end

  it "raises when paths is not an array" do
    action = described_class.new(notes_root: @notes_root)

    expect { action.call(paths: "first.md") }
      .to raise_error(described_class::InvalidPathsError, "paths must be an array")
  end

  it "raises when paths exceeds the max batch size" do
    action = described_class.new(notes_root: @notes_root)
    oversized_paths = Array.new(described_class::MAX_BATCH_SIZE + 1, "note.md")

    expect { action.call(paths: oversized_paths) }
      .to raise_error(
        described_class::InvalidPathsError,
        "paths exceeds max batch size of #{described_class::MAX_BATCH_SIZE}"
      )
  end

  it "raises when paths contains non-string entries" do
    action = described_class.new(notes_root: @notes_root)

    expect { action.call(paths: ["valid.md", 1]) }
      .to raise_error(described_class::InvalidPathsError, "each path must be a string")
  end
end
