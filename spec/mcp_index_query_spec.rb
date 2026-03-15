# frozen_string_literal: true

require "fileutils"
require "tmpdir"

RSpec.describe "MCP index query endpoint" do
  def expected_chunk(path:, chunk_index:, content:, score:, snippet_offset:)
    {
      "content" => content,
      "score" => score,
      "metadata" => {
        "path" => path,
        "chunk_index" => chunk_index,
        "snippet_offset" => snippet_offset
      }
    }
  end

  around do |example|
    original_notes_root = App.settings.notes_root
    original_mcp_policy_mode = App.settings.mcp_policy_mode
    original_mcp_retrieval_mode = App.settings.mcp_retrieval_mode
    original_semantic_enabled = App.settings.mcp_semantic_provider_enabled
    original_semantic_provider = App.settings.mcp_semantic_provider
    original_semantic_configured = App.settings.mcp_semantic_configured
    original_openai_embedding_model = App.settings.mcp_openai_embedding_model
    original_openai_vector_store_id = App.settings.mcp_openai_vector_store_id
    original_openai_configured = App.settings.mcp_openai_configured
    original_local_semantic_base_url = App.settings.mcp_local_semantic_base_url
    original_local_semantic_configured = App.settings.mcp_local_semantic_configured

    Dir.mktmpdir("notes-root") do |notes_root|
      @notes_root = notes_root
      App.set :notes_root, notes_root
      App.set :mcp_policy_mode, Mcp::ActionPolicy::MODE_ALLOW_ALL
      App.set :mcp_retrieval_mode, RetrievalProviderFactory::MODE_LEXICAL
      App.set :mcp_semantic_provider_enabled, false
      App.set :mcp_semantic_provider, "openai"
      App.set :mcp_semantic_configured, false
      App.set :mcp_openai_embedding_model, OpenAiSemanticClient::DEFAULT_EMBEDDING_MODEL
      App.set :mcp_openai_vector_store_id, nil
      App.set :mcp_openai_configured, false
      App.set :mcp_local_semantic_base_url, nil
      App.set :mcp_local_semantic_configured, false
      example.run
    end
  ensure
    App.set :notes_root, original_notes_root
    App.set :mcp_policy_mode, original_mcp_policy_mode
    App.set :mcp_retrieval_mode, original_mcp_retrieval_mode
    App.set :mcp_semantic_provider_enabled, original_semantic_enabled
    App.set :mcp_semantic_provider, original_semantic_provider
    App.set :mcp_semantic_configured, original_semantic_configured
    App.set :mcp_openai_embedding_model, original_openai_embedding_model
    App.set :mcp_openai_vector_store_id, original_openai_vector_store_id
    App.set :mcp_openai_configured, original_openai_configured
    App.set :mcp_local_semantic_base_url, original_local_semantic_base_url
    App.set :mcp_local_semantic_configured, original_local_semantic_configured
  end

  it "returns ranked chunks for a query with an explicit limit" do
    File.write(File.join(@notes_root, "root.md"), "alpha beta\ngamma\n")
    FileUtils.mkdir_p(File.join(@notes_root, "nested"))
    File.write(File.join(@notes_root, "nested/child.md"), "alpha\n")

    get "/mcp/index/query", q: "alpha beta", limit: "2"

    expect(last_response.status).to eq(200)
    body = JSON.parse(last_response.body)
    expect(body).to eq(
      {
        "query" => "alpha beta",
        "limit" => 2,
        "chunks" => [
          expected_chunk(path: "root.md", chunk_index: 0, content: "alpha beta\ngamma", score: 2, snippet_offset: {"start" => 0, "end" => 5}),
          expected_chunk(path: "nested/child.md", chunk_index: 0, content: "alpha", score: 1, snippet_offset: {"start" => 0, "end" => 5})
        ]
      }
    )
    offset = body.fetch("chunks").first.fetch("metadata").fetch("snippet_offset")
    content = body.fetch("chunks").first.fetch("content")
    expect(content[offset.fetch("start")...offset.fetch("end")]).to eq("alpha")
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
    expect(body["chunks"].map { |chunk| chunk.fetch("metadata").fetch("path") }).to eq(
      %w[a.md b.md c.md d.md e.md]
    )
  end

  it "filters results by path_prefix when provided" do
    File.write(File.join(@notes_root, "root.md"), "alpha\n")
    FileUtils.mkdir_p(File.join(@notes_root, "nested"))
    File.write(File.join(@notes_root, "nested/child.md"), "alpha\n")
    File.write(File.join(@notes_root, "nested/second.md"), "alpha\n")

    get "/mcp/index/query", q: "alpha", path_prefix: "nested/"

    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "query" => "alpha",
        "limit" => 5,
        "chunks" => [
          expected_chunk(path: "nested/child.md", chunk_index: 0, content: "alpha", score: 1, snippet_offset: {"start" => 0, "end" => 5}),
          expected_chunk(path: "nested/second.md", chunk_index: 0, content: "alpha", score: 1, snippet_offset: {"start" => 0, "end" => 5})
        ]
      }
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
          expected_chunk(path: "cached.md", chunk_index: 0, content: "alpha beta", score: 1, snippet_offset: {"start" => 0, "end" => 5})
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

  it "returns invalid_query when path_prefix is absolute" do
    get "/mcp/index/query", q: "alpha", path_prefix: "/nested"

    expect(last_response.status).to eq(400)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "error" => {
          "code" => "invalid_query",
          "message" => "absolute paths are not allowed"
        }
      }
    )
  end

  it "returns invalid_query when path_prefix escapes notes root" do
    get "/mcp/index/query", q: "alpha", path_prefix: "../nested"

    expect(last_response.status).to eq(400)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "error" => {
          "code" => "invalid_query",
          "message" => "path_prefix escapes notes root"
        }
      }
    )
  end

  it "returns invalid_query when path_prefix is not a string" do
    get "/mcp/index/query", {"q" => "alpha", "path_prefix[]" => "nested"}

    expect(last_response.status).to eq(400)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "error" => {
          "code" => "invalid_query",
          "message" => "path_prefix must be a string"
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
          expected_chunk(path: "root.md", chunk_index: 0, content: "alpha", score: 1, snippet_offset: {"start" => 0, "end" => 5})
        ]
      }
    )
  end

  it "preserves query contract when semantic mode is enabled" do
    App.set :mcp_retrieval_mode, RetrievalProviderFactory::MODE_SEMANTIC
    App.set :mcp_semantic_provider_enabled, true
    App.set :mcp_semantic_provider, "openai"
    App.set :mcp_semantic_configured, true
    App.set :mcp_openai_vector_store_id, "vs_123"
    App.set :mcp_openai_configured, true
    allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_call_original
    allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_return("sk-test")
    allow(OpenAiSemanticClient).to receive(:new).and_return(
      instance_double(
        "OpenAiSemanticClient",
        search: [{"path" => "root.md", "chunk_index" => 0, "content" => "provider content", "score" => 0.95}]
      )
    )
    File.write(File.join(@notes_root, "root.md"), "alpha beta\ngamma\n")

    get "/mcp/index/query", q: "alpha", limit: "2"

    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "query" => "alpha",
        "limit" => 2,
        "chunks" => [
          expected_chunk(path: "root.md", chunk_index: 0, content: "alpha beta\ngamma", score: 0.95, snippet_offset: {"start" => 0, "end" => 5})
        ]
      }
    )
  end

  it "keeps semantic results within path_prefix-scoped local chunks" do
    App.set :mcp_retrieval_mode, RetrievalProviderFactory::MODE_SEMANTIC
    App.set :mcp_semantic_provider_enabled, true
    App.set :mcp_semantic_provider, "openai"
    App.set :mcp_semantic_configured, true
    App.set :mcp_openai_vector_store_id, "vs_123"
    App.set :mcp_openai_configured, true
    allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_call_original
    allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_return("sk-test")
    allow(OpenAiSemanticClient).to receive(:new).and_return(
      instance_double(
        "OpenAiSemanticClient",
        search: [
          {"path" => "root.md", "chunk_index" => 0, "content" => "outside scope", "score" => 0.99},
          {"path" => "nested/child.md", "chunk_index" => 0, "content" => "provider nested", "score" => 0.80}
        ]
      )
    )
    File.write(File.join(@notes_root, "root.md"), "alpha\n")
    FileUtils.mkdir_p(File.join(@notes_root, "nested"))
    File.write(File.join(@notes_root, "nested/child.md"), "nested alpha\n")

    get "/mcp/index/query", q: "alpha", path_prefix: "nested/", limit: "5"

    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "query" => "alpha",
        "limit" => 5,
        "chunks" => [
          expected_chunk(path: "nested/child.md", chunk_index: 0, content: "nested alpha", score: 0.8, snippet_offset: {"start" => 7, "end" => 12})
        ]
      }
    )
  end

  it "falls back to lexical retrieval when semantic provider is unavailable" do
    App.set :mcp_retrieval_mode, RetrievalProviderFactory::MODE_SEMANTIC
    App.set :mcp_semantic_provider_enabled, true
    App.set :mcp_semantic_provider, "openai"
    App.set :mcp_semantic_configured, true
    App.set :mcp_openai_vector_store_id, "vs_123"
    App.set :mcp_openai_configured, true
    allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_call_original
    allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_return("sk-test")
    failing_client = instance_double("OpenAiSemanticClient")
    allow(failing_client).to receive(:search).and_raise(OpenAiSemanticClient::RequestError, "timeout")
    allow(OpenAiSemanticClient).to receive(:new).and_return(failing_client)
    File.write(File.join(@notes_root, "root.md"), "alpha beta\ngamma\n")

    get "/mcp/index/query", q: "alpha", limit: "2"

    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "query" => "alpha",
        "limit" => 2,
        "chunks" => [
          expected_chunk(path: "root.md", chunk_index: 0, content: "alpha beta\ngamma", score: 1, snippet_offset: {"start" => 0, "end" => 5})
        ]
      }
    )
  end

  it "returns nil snippet_offset when semantic result has no lexical overlap with query" do
    App.set :mcp_retrieval_mode, RetrievalProviderFactory::MODE_SEMANTIC
    App.set :mcp_semantic_provider_enabled, true
    App.set :mcp_semantic_provider, "openai"
    App.set :mcp_semantic_configured, true
    App.set :mcp_openai_vector_store_id, "vs_123"
    App.set :mcp_openai_configured, true
    allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_call_original
    allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_return("sk-test")
    allow(OpenAiSemanticClient).to receive(:new).and_return(
      instance_double(
        "OpenAiSemanticClient",
        search: [{"path" => "root.md", "chunk_index" => 0, "content" => "provider content", "score" => 0.95}]
      )
    )
    File.write(File.join(@notes_root, "root.md"), "tiger\n")

    get "/mcp/index/query", q: "lion", limit: "2"

    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "query" => "lion",
        "limit" => 2,
        "chunks" => [
          expected_chunk(path: "root.md", chunk_index: 0, content: "tiger", score: 0.95, snippet_offset: nil)
        ]
      }
    )
  end

  it "preserves query contract when local semantic provider is enabled" do
    App.set :mcp_retrieval_mode, RetrievalProviderFactory::MODE_SEMANTIC
    App.set :mcp_semantic_provider_enabled, true
    App.set :mcp_semantic_provider, "local"
    App.set :mcp_local_semantic_base_url, "http://127.0.0.1:4000"
    App.set :mcp_local_semantic_configured, true
    App.set :mcp_semantic_configured, true
    allow(LocalSemanticClient).to receive(:new).and_return(
      instance_double(
        "LocalSemanticClient",
        search: [{"path" => "root.md", "chunk_index" => 0, "content" => "provider content", "score" => 0.95}]
      )
    )
    File.write(File.join(@notes_root, "root.md"), "alpha beta\ngamma\n")

    get "/mcp/index/query", q: "alpha", limit: "2"

    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "query" => "alpha",
        "limit" => 2,
        "chunks" => [
          expected_chunk(path: "root.md", chunk_index: 0, content: "alpha beta\ngamma", score: 0.95, snippet_offset: {"start" => 0, "end" => 5})
        ]
      }
    )
  end

  it "echoes public metadata from normalized chunk fields" do
    File.write(File.join(@notes_root, "root.md"), "alpha beta\ngamma\n")

    get "/mcp/index/query", q: "alpha", limit: "1"

    expect(last_response.status).to eq(200)
    chunk = JSON.parse(last_response.body).fetch("chunks").first
    expect(chunk.keys).to contain_exactly("content", "score", "metadata")
    expect(chunk.fetch("metadata")).to eq({"path" => "root.md", "chunk_index" => 0, "snippet_offset" => {"start" => 0, "end" => 5}})
  end
end
