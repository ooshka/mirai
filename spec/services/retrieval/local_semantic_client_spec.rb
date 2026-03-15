# frozen_string_literal: true

require "json"
require_relative "../../../app/services/retrieval/local_semantic_client"

RSpec.describe LocalSemanticClient do
  def ok_response(body)
    response = double("response", body: JSON.generate(body), code: "200")
    allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
    response
  end

  it "posts a retrieval query and normalizes ranked chunk records" do
    client = described_class.new(base_url: "http://127.0.0.1:4000")
    requests = []
    search_response = ok_response(
      "chunks" => [
        {
          "path" => "notes/root.md",
          "chunk_index" => 2,
          "content" => "provider content",
          "score" => 0.91,
          "snippet_offset" => {"start" => 0, "end" => 8}
        }
      ]
    )
    allow(Net::HTTP).to receive(:start) do |_host, _port, use_ssl:, &block|
      expect(use_ssl).to eq(false)
      fake_http = double("http")
      allow(fake_http).to receive(:request) do |request|
        requests << request
        search_response
      end
      block.call(fake_http)
    end

    results = client.search(query_text: "alpha", limit: 3)

    expect(requests.length).to eq(1)
    expect(requests.first.uri.path).to eq("/retrieval/query")
    expect(JSON.parse(requests.first.body)).to eq({"query" => "alpha", "limit" => 3})
    expect(results).to eq(
      [
        {
          "path" => "notes/root.md",
          "chunk_index" => 2,
          "score" => 0.91,
          "content" => "provider content",
          "metadata" => {"snippet_offset" => {"start" => 0, "end" => 8}}
        }
      ]
    )
  end

  it "raises response error for malformed ranked chunk records" do
    client = described_class.new(base_url: "http://127.0.0.1:4000")
    search_response = ok_response(
      "chunks" => [
        {"path" => "notes/root.md", "chunk_index" => "bad", "content" => "provider content", "score" => 0.91}
      ]
    )
    allow(Net::HTTP).to receive(:start) do |_host, _port, use_ssl:, &block|
      expect(use_ssl).to eq(false)
      fake_http = double("http")
      allow(fake_http).to receive(:request).and_return(search_response)
      block.call(fake_http)
    end

    expect do
      client.search(query_text: "alpha", limit: 3)
    end.to raise_error(LocalSemanticClient::ResponseError, "local semantic retrieval candidate chunk_index is invalid")
  end
end
