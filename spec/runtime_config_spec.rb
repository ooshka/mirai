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

    it "exposes openai semantic diagnostics without leaking secrets" do
      config = described_class.from_env(
        "NOTES_ROOT" => "/notes",
        "MCP_POLICY_MODE" => "allow_all",
        "MCP_RETRIEVAL_MODE" => "semantic",
        "MCP_SEMANTIC_PROVIDER_ENABLED" => "true",
        "MCP_SEMANTIC_PROVIDER" => "openai",
        "MCP_OPENAI_EMBEDDING_MODEL" => "text-embedding-3-large",
        "MCP_OPENAI_VECTOR_STORE_ID" => "vs_123",
        "OPENAI_API_KEY" => "sk-secret"
      )

      expect(config.mcp_semantic_provider).to eq("openai")
      expect(config.mcp_openai_embedding_model).to eq("text-embedding-3-large")
      expect(config.mcp_openai_vector_store_id).to eq("vs_123")
      expect(config.mcp_openai_configured).to eq(true)
    end
  end
end
