# frozen_string_literal: true

require "json"
require_relative "../../../app/services/retrieval/openai_semantic_client"

RSpec.describe OpenAiSemanticClient do
  def ok_response(body)
    response = double("response", body: JSON.generate(body), code: "200")
    allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
    response
  end

  it "uses only vector search query payload and normalizes documented response fields" do
    client = described_class.new(
      api_key: "sk-test",
      embedding_model: "text-embedding-3-small",
      vector_store_id: "vs_123"
    )
    requests = []
    search_response = ok_response(
      "data" => [
        {
          "filename" => "root.md",
          "score" => 0.91,
          "attributes" => {"path" => "nested/root.md", "chunk_index" => 2},
          "content" => [{"type" => "text", "text" => "provider snippet"}]
        }
      ]
    )
    allow(Net::HTTP).to receive(:start) do |_host, _port, use_ssl:, &block|
      expect(use_ssl).to eq(true)
      fake_http = double("http")
      allow(fake_http).to receive(:request) do |request|
        requests << JSON.parse(request.body)
        search_response
      end
      block.call(fake_http)
    end

    results = client.search(query_text: "alpha", limit: 3)

    expect(requests).to eq(
      [
        {"query" => "alpha", "max_num_results" => 3}
      ]
    )
    expect(results).to eq(
      [
        {
          "path" => "nested/root.md",
          "chunk_index" => 2,
          "score" => 0.91,
          "content" => "provider snippet",
          "metadata" => {"path" => "nested/root.md", "chunk_index" => 2}
        }
      ]
    )
  end

  it "raises response error when candidate metadata lacks chunk_index" do
    client = described_class.new(
      api_key: "sk-test",
      embedding_model: "text-embedding-3-small",
      vector_store_id: "vs_123"
    )
    search_response = ok_response(
      "data" => [{"filename" => "root.md", "score" => 0.4, "attributes" => {"path" => "root.md"}}]
    )
    allow(Net::HTTP).to receive(:start) do |_host, _port, use_ssl:, &block|
      expect(use_ssl).to eq(true)
      fake_http = double("http")
      allow(fake_http).to receive(:request).and_return(search_response)
      block.call(fake_http)
    end

    expect do
      client.search(query_text: "alpha", limit: 3)
    end.to raise_error(OpenAiSemanticClient::ResponseError, "openai vector search candidate missing chunk_index metadata")
  end

  it "upserts path chunks by deleting all paginated prior path files and attaching uploaded chunk metadata" do
    client = described_class.new(
      api_key: "sk-test",
      embedding_model: "text-embedding-3-small",
      vector_store_id: "vs_123"
    )
    requests = []

    list_response_page_1 = ok_response(
      "data" => [
        {"id" => "vsf_keep", "attributes" => {"path" => "notes/other.md"}},
        {"id" => "vsf_drop", "attributes" => {"path" => "notes/today.md"}}
      ],
      "has_more" => true,
      "last_id" => "vsf_drop"
    )
    list_response_page_2 = ok_response(
      "data" => [
        {"id" => "vsf_drop_2", "attributes" => {"path" => "notes/today.md"}}
      ],
      "has_more" => false,
      "last_id" => "vsf_drop_2"
    )
    delete_response = ok_response({"id" => "vsf_drop", "deleted" => true})
    delete_response_2 = ok_response({"id" => "vsf_drop_2", "deleted" => true})
    upload_response = ok_response({"id" => "file_123"})
    attach_response = ok_response({"id" => "vsf_new"})
    responses = [
      list_response_page_1,
      list_response_page_2,
      delete_response,
      delete_response_2,
      upload_response,
      attach_response
    ]

    allow(Net::HTTP).to receive(:start) do |_host, _port, use_ssl:, &block|
      expect(use_ssl).to eq(true)
      fake_http = double("http")
      allow(fake_http).to receive(:request) do |request|
        requests << request
        responses.shift
      end
      block.call(fake_http)
    end

    client.upsert_path_chunks(
      path: "notes/today.md",
      chunks: [{chunk_index: 0, content: "hello"}]
    )

    expect(requests.map { |request| request.method }).to eq(%w[GET GET DELETE DELETE POST POST])
    expect(requests[0].uri.path).to eq("/v1/vector_stores/vs_123/files")
    expect(requests[0].uri.query).to eq("limit=100")
    expect(requests[1].uri.path).to eq("/v1/vector_stores/vs_123/files")
    expect(requests[1].uri.query).to eq("limit=100&after=vsf_drop")
    expect(requests[2].uri.path).to eq("/v1/vector_stores/vs_123/files/vsf_drop")
    expect(requests[3].uri.path).to eq("/v1/vector_stores/vs_123/files/vsf_drop_2")
    expect(requests[4].uri.path).to eq("/v1/files")
    expect(requests[5].uri.path).to eq("/v1/vector_stores/vs_123/files")
    expect(JSON.parse(requests[5].body)).to eq(
      {
        "file_id" => "file_123",
        "attributes" => {"path" => "notes/today.md", "chunk_index" => 0}
      }
    )
  end

  it "raises response error when paginated vector store list omits last_id" do
    client = described_class.new(
      api_key: "sk-test",
      embedding_model: "text-embedding-3-small",
      vector_store_id: "vs_123"
    )
    list_response = ok_response(
      "data" => [{"id" => "vsf_drop", "attributes" => {"path" => "notes/today.md"}}],
      "has_more" => true
    )

    allow(Net::HTTP).to receive(:start) do |_host, _port, use_ssl:, &block|
      expect(use_ssl).to eq(true)
      fake_http = double("http")
      allow(fake_http).to receive(:request).and_return(list_response)
      block.call(fake_http)
    end

    expect do
      client.upsert_path_chunks(path: "notes/today.md", chunks: [])
    end.to raise_error(OpenAiSemanticClient::ResponseError, "openai vector store file list response missing last_id for pagination")
  end
end
