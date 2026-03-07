# frozen_string_literal: true

require_relative "lexical_retrieval_provider"
require_relative "openai_semantic_client"
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
    openai_api_key: ENV["OPENAI_API_KEY"],
    openai_embedding_model: ENV.fetch("MCP_OPENAI_EMBEDDING_MODEL", OpenAiSemanticClient::DEFAULT_EMBEDDING_MODEL),
    openai_vector_store_id: ENV["MCP_OPENAI_VECTOR_STORE_ID"],
    openai_base_url: ENV.fetch("MCP_OPENAI_BASE_URL", OpenAiSemanticClient::DEFAULT_BASE_URL),
    lexical_provider: LexicalRetrievalProvider.new,
    openai_client: nil,
    semantic_provider: nil
  )
    @mode = self.class.normalize_mode!(mode)
    @semantic_provider_enabled = Mcp::BooleanFlag.enabled?(semantic_provider_enabled)
    @openai_api_key = openai_api_key
    @openai_embedding_model = openai_embedding_model
    @openai_vector_store_id = openai_vector_store_id
    @openai_base_url = openai_base_url
    @lexical_provider = lexical_provider
    @openai_client = openai_client
    @semantic_provider = semantic_provider
  end

  def build
    resolved_semantic_provider = @semantic_provider || SemanticRetrievalProvider.new(
      enabled: @semantic_provider_enabled,
      lexical_provider: @lexical_provider,
      openai_client: @openai_client || OpenAiSemanticClient.new(
        api_key: @openai_api_key,
        embedding_model: @openai_embedding_model,
        vector_store_id: @openai_vector_store_id,
        base_url: @openai_base_url
      )
    )

    primary_provider = if @mode == MODE_SEMANTIC
      resolved_semantic_provider
    else
      @lexical_provider
    end

    {primary_provider: primary_provider, fallback_provider: @lexical_provider}
  end
end
