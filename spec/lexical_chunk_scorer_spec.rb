# frozen_string_literal: true

require_relative "../app/services/lexical_chunk_scorer"

RSpec.describe LexicalChunkScorer do
  it "counts how many query tokens are present in content tokens" do
    scorer = described_class.new

    score = scorer.score(query_tokens: %w[alpha beta], content: "alpha gamma beta")

    expect(score).to eq(2)
  end

  it "normalizes content tokens to lowercase and splits on punctuation" do
    scorer = described_class.new

    score = scorer.score(query_tokens: ["alpha", "beta1"], content: "ALPHA, beta-1!")

    expect(score).to eq(1)
  end

  it "tokenizes query text with normalized alphanumeric tokens" do
    scorer = described_class.new

    tokens = scorer.tokenize("ALPHA, beta-1!")

    expect(tokens).to eq(%w[alpha beta 1])
  end
end
