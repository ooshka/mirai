# frozen_string_literal: true

require "json"
require_relative "../../../app/services/retrieval/openai_semantic_client"

RSpec.describe OpenAiSemanticClient do
  def ok_response(body)
    response = double("response", body: JSON.generate(body), code: "200")
    allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
    response
  end

  it "uses query text for vector search payload and normalizes documented response fields" do
    client = described_class.new(
      api_key: "sk-test",
      embedding_model: "text-embedding-3-small",
      vector_store_id: "vs_123"
    )
    requests = []
    embedding_response = ok_response("data" => [{"embedding" => [0.1, 0.2]}])
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
        requests.length == 1 ? embedding_response : search_response
      end
      block.call(fake_http)
    end

    results = client.search(query_text: "alpha", limit: 3)

    expect(requests).to eq(
      [
        {"model" => "text-embedding-3-small", "input" => "alpha"},
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
    embedding_response = ok_response("data" => [{"embedding" => [0.1, 0.2]}])
    search_response = ok_response(
      "data" => [{"filename" => "root.md", "score" => 0.4, "attributes" => {"path" => "root.md"}}]
    )
    call_count = 0
    allow(Net::HTTP).to receive(:start) do |_host, _port, use_ssl:, &block|
      expect(use_ssl).to eq(true)
      fake_http = double("http")
      allow(fake_http).to receive(:request) do |_request|
        call_count += 1
        call_count == 1 ? embedding_response : search_response
      end
      block.call(fake_http)
    end

    expect do
      client.search(query_text: "alpha", limit: 3)
    end.to raise_error(OpenAiSemanticClient::ResponseError, "openai vector search candidate missing chunk_index metadata")
  end
end
