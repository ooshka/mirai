# frozen_string_literal: true

require_relative "../app/services/retrieval_provider_factory"

RSpec.describe RetrievalProviderFactory do
  it "selects lexical provider by default" do
    lexical_provider = instance_double("LexicalRetrievalProvider")
    semantic_provider = instance_double("SemanticRetrievalProvider")

    result = described_class.new(
      lexical_provider: lexical_provider,
      semantic_provider: semantic_provider
    ).build

    expect(result).to eq(
      {
        primary_provider: lexical_provider,
        fallback_provider: lexical_provider
      }
    )
  end

  it "selects semantic provider when mode is semantic" do
    lexical_provider = instance_double("LexicalRetrievalProvider")
    semantic_provider = instance_double("SemanticRetrievalProvider")

    result = described_class.new(
      mode: described_class::MODE_SEMANTIC,
      lexical_provider: lexical_provider,
      semantic_provider: semantic_provider
    ).build

    expect(result).to eq(
      {
        primary_provider: semantic_provider,
        fallback_provider: lexical_provider
      }
    )
  end

  it "falls back to lexical mode for unknown mode values" do
    lexical_provider = instance_double("LexicalRetrievalProvider")
    semantic_provider = instance_double("SemanticRetrievalProvider")

    result = described_class.new(
      mode: "unknown-mode",
      lexical_provider: lexical_provider,
      semantic_provider: semantic_provider
    ).build

    expect(result).to eq(
      {
        primary_provider: lexical_provider,
        fallback_provider: lexical_provider
      }
    )
  end
end
