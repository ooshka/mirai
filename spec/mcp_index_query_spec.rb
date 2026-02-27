# frozen_string_literal: true

require "fileutils"
require "tmpdir"

RSpec.describe "MCP index query endpoint" do
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

  it "returns ranked chunks for a query with an explicit limit" do
    File.write(File.join(@notes_root, "root.md"), "alpha beta\ngamma\n")
    FileUtils.mkdir_p(File.join(@notes_root, "nested"))
    File.write(File.join(@notes_root, "nested/child.md"), "alpha\n")

    get "/mcp/index/query", q: "alpha beta", limit: "2"

    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "query" => "alpha beta",
        "limit" => 2,
        "chunks" => [
          {"path" => "root.md", "chunk_index" => 0, "content" => "alpha beta\ngamma", "score" => 2},
          {"path" => "nested/child.md", "chunk_index" => 0, "content" => "alpha", "score" => 1}
        ]
      }
    )
  end

  it "returns invalid_query when query is missing" do
    get "/mcp/index/query"

    expect(last_response.status).to eq(400)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "error" => {
          "code" => "invalid_query",
          "message" => "query is required"
        }
      }
    )
  end

  it "returns invalid_query when query is blank" do
    get "/mcp/index/query", q: "   "

    expect(last_response.status).to eq(400)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "error" => {
          "code" => "invalid_query",
          "message" => "query is required"
        }
      }
    )
  end

  it "returns invalid_limit when limit is non-integer" do
    get "/mcp/index/query", q: "alpha", limit: "abc"

    expect(last_response.status).to eq(400)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "error" => {
          "code" => "invalid_limit",
          "message" => "limit must be an integer"
        }
      }
    )
  end

  it "returns invalid_limit when limit is out of bounds" do
    get "/mcp/index/query", q: "alpha", limit: "0"

    expect(last_response.status).to eq(400)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "error" => {
          "code" => "invalid_limit",
          "message" => "limit must be between 1 and 50"
        }
      }
    )
  end
end
