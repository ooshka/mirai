# frozen_string_literal: true

require_relative "mcp/action_policy"
require_relative "mcp/boolean_flag"
require_relative "mcp/retrieval_mode"
require_relative "retrieval/openai_semantic_client"

class RuntimeConfig
  DEFAULT_NOTES_ROOT = "/notes"

  attr_reader :notes_root, :mcp_policy_mode, :mcp_retrieval_mode, :mcp_semantic_provider_enabled,
    :mcp_semantic_provider, :mcp_openai_embedding_model, :mcp_openai_vector_store_id, :mcp_openai_configured

  def self.from_env(env = ENV)
    new(
      notes_root: env.fetch("NOTES_ROOT", DEFAULT_NOTES_ROOT),
      mcp_policy_mode: env.fetch("MCP_POLICY_MODE", Mcp::ActionPolicy::MODE_ALLOW_ALL),
      mcp_retrieval_mode: env.fetch("MCP_RETRIEVAL_MODE", Mcp::RetrievalMode::MODE_LEXICAL),
      mcp_semantic_provider_enabled: env.fetch("MCP_SEMANTIC_PROVIDER_ENABLED", "false"),
      mcp_semantic_provider: env.fetch("MCP_SEMANTIC_PROVIDER", "openai"),
      mcp_openai_embedding_model: env.fetch("MCP_OPENAI_EMBEDDING_MODEL", OpenAiSemanticClient::DEFAULT_EMBEDDING_MODEL),
      mcp_openai_vector_store_id: env["MCP_OPENAI_VECTOR_STORE_ID"],
      openai_api_key: env["OPENAI_API_KEY"]
    )
  end

  def initialize(
    notes_root:,
    mcp_policy_mode:,
    mcp_retrieval_mode:,
    mcp_semantic_provider_enabled:,
    mcp_semantic_provider:,
    mcp_openai_embedding_model:,
    mcp_openai_vector_store_id:,
    openai_api_key:
  )
    @notes_root = notes_root
    @mcp_policy_mode = Mcp::ActionPolicy.normalize_mode(mcp_policy_mode)
    @mcp_retrieval_mode = Mcp::RetrievalMode.normalize_mode!(mcp_retrieval_mode)
    @mcp_semantic_provider_enabled = Mcp::BooleanFlag.enabled?(mcp_semantic_provider_enabled)
    @mcp_semantic_provider = normalize_string(mcp_semantic_provider) || "openai"
    @mcp_openai_embedding_model = normalize_string(mcp_openai_embedding_model) || OpenAiSemanticClient::DEFAULT_EMBEDDING_MODEL
    @mcp_openai_vector_store_id = normalize_string(mcp_openai_vector_store_id)
    @mcp_openai_configured = !normalize_string(openai_api_key).nil? && !@mcp_openai_vector_store_id.nil?
  end

  private

  def normalize_string(value)
    return nil if value.nil?

    normalized = value.to_s.strip
    return nil if normalized.empty?

    normalized
  end
end
