# frozen_string_literal: true

require_relative "lexical_retrieval_provider"
require_relative "semantic_retrieval_provider"

class RetrievalProviderFactory
  MODE_LEXICAL = "lexical"
  MODE_SEMANTIC = "semantic"

  def initialize(
    mode: ENV.fetch("MCP_RETRIEVAL_MODE", MODE_LEXICAL),
    semantic_provider_enabled: ENV.fetch("MCP_SEMANTIC_PROVIDER_ENABLED", "false"),
    lexical_provider: LexicalRetrievalProvider.new,
    semantic_provider: nil
  )
    @mode = normalize_mode(mode)
    @semantic_provider_enabled = truthy?(semantic_provider_enabled)
    @lexical_provider = lexical_provider
    @semantic_provider = semantic_provider
  end

  def build
    resolved_semantic_provider = @semantic_provider || SemanticRetrievalProvider.new(
      enabled: @semantic_provider_enabled,
      lexical_provider: @lexical_provider
    )

    {
      primary_provider: @mode == MODE_SEMANTIC ? resolved_semantic_provider : @lexical_provider,
      fallback_provider: @lexical_provider
    }
  end

  private

  def normalize_mode(mode)
    normalized = mode.to_s.strip.downcase
    return MODE_LEXICAL if normalized.empty?
    return MODE_SEMANTIC if normalized == MODE_SEMANTIC

    MODE_LEXICAL
  end

  def truthy?(value)
    value.to_s.strip.downcase == "true"
  end
end
