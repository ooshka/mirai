# frozen_string_literal: true

require_relative "lexical_retrieval_provider"
require_relative "semantic_retrieval_provider"
require_relative "../mcp/boolean_flag"
require_relative "../mcp/retrieval_mode"

class RetrievalProviderFactory
  MODE_LEXICAL = Mcp::RetrievalMode::MODE_LEXICAL
  MODE_SEMANTIC = Mcp::RetrievalMode::MODE_SEMANTIC
  SUPPORTED_MODES = Mcp::RetrievalMode::SUPPORTED_MODES
  InvalidModeError = Mcp::RetrievalMode::InvalidModeError

  def self.supported_modes
    Mcp::RetrievalMode.supported_modes
  end

  def self.normalize_mode!(mode)
    Mcp::RetrievalMode.normalize_mode!(mode)
  end

  def initialize(
    mode: ENV.fetch("MCP_RETRIEVAL_MODE", MODE_LEXICAL),
    semantic_provider_enabled: ENV.fetch("MCP_SEMANTIC_PROVIDER_ENABLED", "false"),
    lexical_provider: LexicalRetrievalProvider.new,
    semantic_provider: nil
  )
    @mode = self.class.normalize_mode!(mode)
    @semantic_provider_enabled = Mcp::BooleanFlag.enabled?(semantic_provider_enabled)
    @lexical_provider = lexical_provider
    @semantic_provider = semantic_provider
  end

  def build
    resolved_semantic_provider = @semantic_provider || SemanticRetrievalProvider.new(
      enabled: @semantic_provider_enabled,
      lexical_provider: @lexical_provider
    )

    primary_provider = if @mode == MODE_SEMANTIC
      resolved_semantic_provider
    else
      @lexical_provider
    end

    {primary_provider: primary_provider, fallback_provider: @lexical_provider}
  end
end
