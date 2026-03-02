# frozen_string_literal: true

require_relative "mcp/action_policy"
require_relative "mcp/boolean_flag"
require_relative "mcp/retrieval_mode"

class RuntimeConfig
  DEFAULT_NOTES_ROOT = "/notes"

  attr_reader :notes_root, :mcp_policy_mode, :mcp_retrieval_mode, :mcp_semantic_provider_enabled

  def self.from_env(env = ENV)
    new(
      notes_root: env.fetch("NOTES_ROOT", DEFAULT_NOTES_ROOT),
      mcp_policy_mode: env.fetch("MCP_POLICY_MODE", Mcp::ActionPolicy::MODE_ALLOW_ALL),
      mcp_retrieval_mode: env.fetch("MCP_RETRIEVAL_MODE", Mcp::RetrievalMode::MODE_LEXICAL),
      mcp_semantic_provider_enabled: env.fetch("MCP_SEMANTIC_PROVIDER_ENABLED", "false")
    )
  end

  def initialize(notes_root:, mcp_policy_mode:, mcp_retrieval_mode:, mcp_semantic_provider_enabled:)
    @notes_root = notes_root
    @mcp_policy_mode = Mcp::ActionPolicy.normalize_mode(mcp_policy_mode)
    @mcp_retrieval_mode = Mcp::RetrievalMode.normalize_mode!(mcp_retrieval_mode)
    @mcp_semantic_provider_enabled = Mcp::BooleanFlag.enabled?(mcp_semantic_provider_enabled)
  end
end
