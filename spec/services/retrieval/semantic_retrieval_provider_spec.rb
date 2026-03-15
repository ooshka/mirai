# frozen_string_literal: true

require_relative "../../../app/services/retrieval/semantic_retrieval_provider"

RSpec.describe SemanticRetrievalProvider do
  it "raises unavailable when disabled" do
    provider = described_class.new(enabled: false, semantic_client: instance_double("OpenAiSemanticClient"))

    expect do
      provider.rank(query_text: "alpha", chunks: [], limit: 3)
    end.to raise_error(described_class::UnavailableError, "semantic retrieval provider is unavailable")
  end

  it "returns normalized semantic results with deterministic tie ordering" do
    openai_client = instance_double("OpenAiSemanticClient")
    allow(openai_client).to receive(:search).and_return(
      [
        {"path" => "b.md", "chunk_index" => 0, "content" => "beta", "score" => 0.75},
        {"path" => "a.md", "chunk_index" => 0, "score" => 0.75}
      ]
    )
    provider = described_class.new(enabled: true, semantic_client: openai_client)
    fallback_chunks = [
      {path: "a.md", chunk_index: 0, content: "alpha"},
      {path: "b.md", chunk_index: 0, content: "beta"}
    ]

    result = provider.rank(query_text: "alpha", chunks: fallback_chunks, limit: 2)

    expect(result).to eq(
      [
        {path: "a.md", chunk_index: 0, content: "alpha", score: 0.75},
        {path: "b.md", chunk_index: 0, content: "beta", score: 0.75}
      ]
    )
    expect(openai_client).to have_received(:search).with(query_text: "alpha", limit: 2)
  end

  it "drops semantic candidates that are not present in local fallback chunks" do
    openai_client = instance_double("OpenAiSemanticClient")
    allow(openai_client).to receive(:search).and_return(
      [
        {"path" => "outside.md", "chunk_index" => 0, "content" => "outside", "score" => 0.99},
        {"path" => "a.md", "chunk_index" => 0, "content" => "provider alpha", "score" => 0.80}
      ]
    )
    provider = described_class.new(enabled: true, semantic_client: openai_client)

    result = provider.rank(
      query_text: "alpha",
      chunks: [{path: "a.md", chunk_index: 0, content: "canonical alpha"}],
      limit: 5
    )

    expect(result).to eq(
      [
        {path: "a.md", chunk_index: 0, content: "canonical alpha", score: 0.8}
      ]
    )
  end

  it "maps openai request failures to unavailable for lexical fallback" do
    openai_client = instance_double("OpenAiSemanticClient")
    allow(openai_client).to receive(:search).and_raise(OpenAiSemanticClient::RequestError, "timeout")
    provider = described_class.new(enabled: true, semantic_client: openai_client)

    expect do
      provider.rank(query_text: "alpha", chunks: [], limit: 1)
    end.to raise_error(described_class::UnavailableError, "semantic retrieval provider is unavailable")
  end

  it "maps malformed semantic results to unavailable for lexical fallback" do
    openai_client = instance_double("OpenAiSemanticClient")
    allow(openai_client).to receive(:search).and_return([{"path" => "a.md", "chunk_index" => 0, "score" => "bad"}])
    provider = described_class.new(enabled: true, semantic_client: openai_client)

    expect do
      provider.rank(query_text: "alpha", chunks: [{path: "a.md", chunk_index: 0, content: "alpha"}], limit: 1)
    end.to raise_error(described_class::UnavailableError, "semantic retrieval provider is unavailable")
  end

  it "maps local client failures to unavailable for lexical fallback" do
    local_client = instance_double("LocalSemanticClient")
    allow(local_client).to receive(:search).and_raise(LocalSemanticClient::RequestError, "timeout")
    provider = described_class.new(enabled: true, semantic_client: local_client)

    expect do
      provider.rank(query_text: "alpha", chunks: [], limit: 1)
    end.to raise_error(described_class::UnavailableError, "semantic retrieval provider is unavailable")
  end
end
