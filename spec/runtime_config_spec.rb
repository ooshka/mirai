# frozen_string_literal: true

require_relative "../app/services/runtime_config"

RSpec.describe RuntimeConfig do
  describe ".from_env" do
    it "normalizes semantic provider enabled to true for true-like input" do
      config = described_class.from_env(
        "NOTES_ROOT" => "/notes",
        "MCP_POLICY_MODE" => "allow_all",
        "MCP_RETRIEVAL_MODE" => "lexical",
        "MCP_SEMANTIC_PROVIDER_ENABLED" => " TRUE "
      )

      expect(config.mcp_semantic_provider_enabled).to eq(true)
    end

    it "normalizes semantic provider enabled to false for non-true input" do
      config = described_class.from_env(
        "NOTES_ROOT" => "/notes",
        "MCP_POLICY_MODE" => "allow_all",
        "MCP_RETRIEVAL_MODE" => "lexical",
        "MCP_SEMANTIC_PROVIDER_ENABLED" => "false"
      )

      expect(config.mcp_semantic_provider_enabled).to eq(false)
    end
  end
end
