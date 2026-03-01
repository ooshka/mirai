# frozen_string_literal: true

require "fileutils"
require "tmpdir"

RSpec.describe "MCP index query endpoint" do
  around do |example|
    original_notes_root = App.settings.notes_root
    original_mcp_policy_mode = App.settings.mcp_policy_mode

    Dir.mktmpdir("notes-root") do |notes_root|
      @notes_root = notes_root
      App.set :notes_root, notes_root
      App.set :mcp_policy_mode, Mcp::ActionPolicy::MODE_ALLOW_ALL
      example.run
    end
  ensure
    App.set :notes_root, original_notes_root
    App.set :mcp_policy_mode, original_mcp_policy_mode
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

  it "uses default limit when limit is omitted" do
    %w[a.md b.md c.md d.md e.md f.md].each do |filename|
      File.write(File.join(@notes_root, filename), "alpha\n")
    end

    get "/mcp/index/query", q: "alpha"

    expect(last_response.status).to eq(200)

    body = JSON.parse(last_response.body)
    expect(body["limit"]).to eq(5)
    expect(body["chunks"].length).to eq(5)
    expect(body["chunks"].map { |chunk| chunk["path"] }).to eq(
      %w[a.md b.md c.md d.md e.md]
    )
  end

  it "uses persisted artifact chunks when available" do
    FileUtils.mkdir_p(File.join(@notes_root, ".mirai"))
    File.write(
      File.join(@notes_root, ".mirai", "index.json"),
      JSON.pretty_generate(
        {
          "version" => 1,
          "generated_at" => "2026-02-28T12:00:00Z",
          "notes_indexed" => 1,
          "chunks_indexed" => 1,
          "chunks" => [
            {"path" => "cached.md", "chunk_index" => 0, "content" => "alpha beta"}
          ]
        }
      )
    )

    get "/mcp/index/query", q: "alpha"

    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "query" => "alpha",
        "limit" => 5,
        "chunks" => [
          {"path" => "cached.md", "chunk_index" => 0, "content" => "alpha beta", "score" => 1}
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

  it "returns invalid_index_artifact when artifact payload is malformed" do
    FileUtils.mkdir_p(File.join(@notes_root, ".mirai"))
    File.write(File.join(@notes_root, ".mirai", "index.json"), "{\"version\":1")

    get "/mcp/index/query", q: "alpha"

    expect(last_response.status).to eq(500)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "error" => {
          "code" => "invalid_index_artifact",
          "message" => "index artifact is invalid"
        }
      }
    )
  end

  it "returns invalid_index_artifact when artifact version is stale" do
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

    get "/mcp/index/query", q: "alpha"

    expect(last_response.status).to eq(500)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "error" => {
          "code" => "invalid_index_artifact",
          "message" => "index artifact is invalid"
        }
      }
    )
  end

  it "allows index query in read_only policy mode" do
    App.set :mcp_policy_mode, Mcp::ActionPolicy::MODE_READ_ONLY
    File.write(File.join(@notes_root, "root.md"), "alpha\n")

    get "/mcp/index/query", q: "alpha"

    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "query" => "alpha",
        "limit" => 5,
        "chunks" => [
          {"path" => "root.md", "chunk_index" => 0, "content" => "alpha", "score" => 1}
        ]
      }
    )
  end
end
