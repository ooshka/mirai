# frozen_string_literal: true

require_relative "../../../app/services/retrieval/retrieval_provider_factory"

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

  it "raises on unknown mode values" do
    lexical_provider = instance_double("LexicalRetrievalProvider")
    semantic_provider = instance_double("SemanticRetrievalProvider")

    expect do
      described_class.new(
        mode: "unknown-mode",
        lexical_provider: lexical_provider,
        semantic_provider: semantic_provider
      ).build
    end.to raise_error(described_class::InvalidModeError, "invalid MCP retrieval mode: unknown-mode")
  end

  it "normalizes semantic provider enabled true-like values" do
    lexical_provider = instance_double("LexicalRetrievalProvider")
    semantic_provider = instance_double("SemanticRetrievalProvider")
    openai_client = instance_double("OpenAiSemanticClient")

    expect(OpenAiSemanticClient).to receive(:new).with(
      api_key: nil,
      embedding_model: OpenAiSemanticClient::DEFAULT_EMBEDDING_MODEL,
      vector_store_id: nil,
      base_url: OpenAiSemanticClient::DEFAULT_BASE_URL
    ).and_return(openai_client)

    expect(SemanticRetrievalProvider).to receive(:new).with(
      enabled: true,
      lexical_provider: lexical_provider,
      openai_client: openai_client
    ).and_return(semantic_provider)

    described_class.new(
      semantic_provider_enabled: " TRUE ",
      lexical_provider: lexical_provider
    ).build
  end

  it "normalizes semantic provider enabled false-like values" do
    lexical_provider = instance_double("LexicalRetrievalProvider")
    semantic_provider = instance_double("SemanticRetrievalProvider")
    openai_client = instance_double("OpenAiSemanticClient")

    expect(OpenAiSemanticClient).to receive(:new).with(
      api_key: nil,
      embedding_model: OpenAiSemanticClient::DEFAULT_EMBEDDING_MODEL,
      vector_store_id: nil,
      base_url: OpenAiSemanticClient::DEFAULT_BASE_URL
    ).and_return(openai_client)

    expect(SemanticRetrievalProvider).to receive(:new).with(
      enabled: false,
      lexical_provider: lexical_provider,
      openai_client: openai_client
    ).and_return(semantic_provider)

    described_class.new(
      semantic_provider_enabled: "",
      lexical_provider: lexical_provider
    ).build
  end

  it "passes openai retrieval config through to the semantic client" do
    lexical_provider = instance_double("LexicalRetrievalProvider")
    semantic_provider = instance_double("SemanticRetrievalProvider")
    openai_client = instance_double("OpenAiSemanticClient")

    expect(OpenAiSemanticClient).to receive(:new).with(
      api_key: "sk-test",
      embedding_model: "text-embedding-3-large",
      vector_store_id: "vs_123",
      base_url: "https://example.test"
    ).and_return(openai_client)
    expect(SemanticRetrievalProvider).to receive(:new).with(
      enabled: true,
      lexical_provider: lexical_provider,
      openai_client: openai_client
    ).and_return(semantic_provider)

    described_class.new(
      mode: described_class::MODE_SEMANTIC,
      semantic_provider_enabled: true,
      openai_api_key: "sk-test",
      openai_embedding_model: "text-embedding-3-large",
      openai_vector_store_id: "vs_123",
      openai_base_url: "https://example.test",
      lexical_provider: lexical_provider
    ).build
  end
end
