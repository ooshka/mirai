# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require "time"

RSpec.describe "MCP index rebuild endpoint" do
  around do |example|
    original_notes_root = App.settings.notes_root

    Dir.mktmpdir("notes-root") do |notes_root|
      @notes_root = notes_root
      App.set :notes_root, notes_root
      example.run
    end
  ensure
    App.set :notes_root, original_notes_root
  end

  it "rebuilds the index and returns summary metadata" do
    lines = (1..21).map { |n| "line #{n}" }.join("\n")
    File.write(File.join(@notes_root, "root.md"), "#{lines}\n")
    FileUtils.mkdir_p(File.join(@notes_root, "nested"))
    File.write(File.join(@notes_root, "nested/child.md"), "alpha\n")

    post "/mcp/index/rebuild"

    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "notes_indexed" => 2,
        "chunks_indexed" => 3
      }
    )

    artifact_path = File.join(@notes_root, ".mirai", "index.json")
    expect(File.exist?(artifact_path)).to be(true)

    artifact = JSON.parse(File.read(artifact_path))
    expect(artifact["version"]).to eq(1)
    expect { Time.iso8601(artifact["generated_at"]) }.not_to raise_error
    expect(artifact["notes_indexed"]).to eq(2)
    expect(artifact["chunks_indexed"]).to eq(3)
    expect(artifact["chunks"].map { |chunk| chunk["path"] }).to eq(
      ["nested/child.md", "root.md", "root.md"]
    )
  end

  it "returns not_found when notes root does not exist" do
    App.set :notes_root, File.join(@notes_root, "missing")

    post "/mcp/index/rebuild"

    expect(last_response.status).to eq(404)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "error" => {
          "code" => "not_found",
          "message" => "note was not found"
        }
      }
    )
  end
end
