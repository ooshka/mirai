# frozen_string_literal: true

require_relative "../../../app/services/retrieval/retrieval_fallback_policy"
require_relative "../../../app/services/retrieval/semantic_retrieval_provider"

RSpec.describe RetrievalFallbackPolicy do
  it "returns primary provider results when primary succeeds" do
    primary_provider = instance_double("SemanticRetrievalProvider")
    fallback_provider = instance_double("LexicalRetrievalProvider")
    chunks = [{path: "note.md", chunk_index: 0, content: "alpha"}]
    ranked_chunks = [{path: "note.md", chunk_index: 0, content: "alpha", score: 2}]
    allow(primary_provider).to receive(:rank).and_return(ranked_chunks)
    allow(fallback_provider).to receive(:rank)

    result = described_class.new.rank(
      primary_provider: primary_provider,
      fallback_provider: fallback_provider,
      query_text: "alpha",
      chunks: chunks,
      limit: 3
    )

    expect(result).to eq(ranked_chunks)
    expect(fallback_provider).not_to have_received(:rank)
  end

  it "falls back when primary provider raises unavailable error" do
    primary_provider = instance_double("SemanticRetrievalProvider")
    fallback_provider = instance_double("LexicalRetrievalProvider")
    chunks = [{path: "note.md", chunk_index: 0, content: "alpha"}]
    ranked_chunks = [{path: "note.md", chunk_index: 0, content: "alpha", score: 1}]
    allow(primary_provider).to receive(:rank).and_raise(
      SemanticRetrievalProvider::UnavailableError, "semantic retrieval provider is unavailable"
    )
    allow(fallback_provider).to receive(:rank).and_return(ranked_chunks)

    result = described_class.new.rank(
      primary_provider: primary_provider,
      fallback_provider: fallback_provider,
      query_text: "alpha",
      chunks: chunks,
      limit: 3
    )

    expect(result).to eq(ranked_chunks)
    expect(fallback_provider).to have_received(:rank).with(
      query_text: "alpha",
      chunks: chunks,
      limit: 3
    )
  end

  it "re-raises non-fallback errors" do
    primary_provider = instance_double("SemanticRetrievalProvider")
    fallback_provider = instance_double("LexicalRetrievalProvider")
    allow(primary_provider).to receive(:rank).and_raise(StandardError, "boom")
    allow(fallback_provider).to receive(:rank)

    expect do
      described_class.new.rank(
        primary_provider: primary_provider,
        fallback_provider: fallback_provider,
        query_text: "alpha",
        chunks: [],
        limit: 1
      )
    end.to raise_error(StandardError, "boom")

    expect(fallback_provider).not_to have_received(:rank)
  end
end
