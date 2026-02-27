# frozen_string_literal: true

require "fileutils"
require "tmpdir"

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
