# frozen_string_literal: true

require_relative "../app/services/runtime_config"

RSpec.describe RuntimeConfig do
  describe ".from_env" do
    it "normalizes semantic provider enabled to true for true-like input" do
      config = described_class.from_env(
        "NOTES_ROOT" => "/notes",
        "MCP_POLICY_MODE" => "allow_all",
        "MCP_RETRIEVAL_MODE" => "lexical",
        "MCP_SEMANTIC_PROVIDER_ENABLED" => " TRUE ",
        "MCP_SEMANTIC_INGESTION_ENABLED" => "true"
      )

      expect(config.mcp_semantic_provider_enabled).to eq(true)
      expect(config.mcp_semantic_ingestion_enabled).to eq(true)
    end

    it "normalizes semantic provider enabled to false for non-true input" do
      config = described_class.from_env(
        "NOTES_ROOT" => "/notes",
        "MCP_POLICY_MODE" => "allow_all",
        "MCP_RETRIEVAL_MODE" => "lexical",
        "MCP_SEMANTIC_PROVIDER_ENABLED" => "false",
        "MCP_SEMANTIC_INGESTION_ENABLED" => "false"
      )

      expect(config.mcp_semantic_provider_enabled).to eq(false)
      expect(config.mcp_semantic_ingestion_enabled).to eq(false)
    end

    it "exposes openai semantic diagnostics without leaking secrets" do
      config = described_class.from_env(
        "NOTES_ROOT" => "/notes",
        "MCP_POLICY_MODE" => "allow_all",
        "MCP_RETRIEVAL_MODE" => "semantic",
        "MCP_SEMANTIC_PROVIDER_ENABLED" => "true",
        "MCP_SEMANTIC_PROVIDER" => "openai",
        "MCP_SEMANTIC_INGESTION_ENABLED" => "true",
        "MCP_OPENAI_EMBEDDING_MODEL" => "text-embedding-3-large",
        "MCP_OPENAI_VECTOR_STORE_ID" => "vs_123",
        "OPENAI_API_KEY" => "sk-secret"
      )

      expect(config.mcp_semantic_provider).to eq("openai")
      expect(config.mcp_semantic_configured).to eq(true)
      expect(config.mcp_semantic_ingestion_enabled).to eq(true)
      expect(config.mcp_openai_embedding_model).to eq("text-embedding-3-large")
      expect(config.mcp_openai_vector_store_id).to eq("vs_123")
      expect(config.mcp_openai_configured).to eq(true)
    end

    it "exposes local semantic diagnostics when local provider is selected" do
      config = described_class.from_env(
        "NOTES_ROOT" => "/notes",
        "MCP_POLICY_MODE" => "allow_all",
        "MCP_RETRIEVAL_MODE" => "semantic",
        "MCP_SEMANTIC_PROVIDER_ENABLED" => "true",
        "MCP_SEMANTIC_PROVIDER" => "local",
        "MCP_LOCAL_SEMANTIC_BASE_URL" => "http://127.0.0.1:4000"
      )

      expect(config.mcp_semantic_provider).to eq("local")
      expect(config.mcp_local_semantic_base_url).to eq("http://127.0.0.1:4000")
      expect(config.mcp_local_semantic_configured).to eq(true)
      expect(config.mcp_semantic_configured).to eq(true)
      expect(config.mcp_openai_configured).to eq(false)
    end

    it "raises on invalid semantic provider values" do
      expect do
        described_class.from_env(
          "NOTES_ROOT" => "/notes",
          "MCP_POLICY_MODE" => "allow_all",
          "MCP_RETRIEVAL_MODE" => "semantic",
          "MCP_SEMANTIC_PROVIDER_ENABLED" => "true",
          "MCP_SEMANTIC_PROVIDER" => "dense"
        )
      end.to raise_error(Mcp::SemanticProvider::InvalidProviderError, "invalid MCP semantic provider: dense")
    end

    it "exposes workflow planner diagnostics without leaking secrets" do
      config = described_class.from_env(
        "NOTES_ROOT" => "/notes",
        "MCP_POLICY_MODE" => "allow_all",
        "MCP_RETRIEVAL_MODE" => "semantic",
        "MCP_SEMANTIC_PROVIDER_ENABLED" => "true",
        "MCP_SEMANTIC_PROVIDER" => "openai",
        "MCP_SEMANTIC_INGESTION_ENABLED" => "false",
        "MCP_OPENAI_EMBEDDING_MODEL" => "text-embedding-3-small",
        "MCP_OPENAI_VECTOR_STORE_ID" => "vs_123",
        "MCP_WORKFLOW_PLANNER_ENABLED" => "true",
        "MCP_WORKFLOW_PLANNER_PROVIDER" => "openai",
        "MCP_OPENAI_WORKFLOW_MODEL" => "gpt-4.1-mini",
        "OPENAI_API_KEY" => "sk-secret"
      )

      expect(config.mcp_workflow_planner_enabled).to eq(true)
      expect(config.mcp_workflow_planner_provider).to eq("openai")
      expect(config.mcp_openai_workflow_model).to eq("gpt-4.1-mini")
      expect(config.mcp_openai_workflow_configured).to eq(true)
      expect(config.mcp_workflow_planner_configured).to eq(true)
    end

    it "exposes local workflow planner diagnostics when local provider is selected" do
      config = described_class.from_env(
        "NOTES_ROOT" => "/notes",
        "MCP_POLICY_MODE" => "allow_all",
        "MCP_RETRIEVAL_MODE" => "lexical",
        "MCP_WORKFLOW_PLANNER_ENABLED" => "true",
        "MCP_WORKFLOW_PLANNER_PROVIDER" => "local",
        "MCP_OPENAI_WORKFLOW_MODEL" => "qwen2.5:7b-instruct",
        "MCP_LOCAL_WORKFLOW_BASE_URL" => "http://127.0.0.1:11434"
      )

      expect(config.mcp_workflow_planner_provider).to eq("local")
      expect(config.mcp_openai_workflow_model).to eq("qwen2.5:7b-instruct")
      expect(config.mcp_local_workflow_base_url).to eq("http://127.0.0.1:11434")
      expect(config.mcp_local_workflow_configured).to eq(true)
      expect(config.mcp_workflow_planner_configured).to eq(true)
      expect(config.mcp_openai_workflow_configured).to eq(false)
    end

    it "exposes local workflow drafter diagnostics when local provider is selected" do
      config = described_class.from_env(
        "NOTES_ROOT" => "/notes",
        "MCP_POLICY_MODE" => "allow_all",
        "MCP_RETRIEVAL_MODE" => "lexical",
        "MCP_WORKFLOW_PLANNER_ENABLED" => "true",
        "MCP_WORKFLOW_DRAFTER_PROVIDER" => "local",
        "MCP_OPENAI_WORKFLOW_MODEL" => "qwen2.5:7b-instruct",
        "MCP_LOCAL_WORKFLOW_BASE_URL" => "http://127.0.0.1:11434"
      )

      expect(config.mcp_workflow_drafter_provider).to eq("local")
      expect(config.mcp_local_workflow_base_url).to eq("http://127.0.0.1:11434")
      expect(config.mcp_local_workflow_configured).to eq(true)
      expect(config.mcp_workflow_drafter_configured).to eq(true)
      expect(config.mcp_openai_workflow_configured).to eq(false)
    end

    it "raises on invalid workflow planner provider values" do
      expect do
        described_class.from_env(
          "NOTES_ROOT" => "/notes",
          "MCP_POLICY_MODE" => "allow_all",
          "MCP_RETRIEVAL_MODE" => "lexical",
          "MCP_WORKFLOW_PLANNER_PROVIDER" => "dense"
        )
      end.to raise_error(Llm::WorkflowPlanner::InvalidProviderError, "invalid workflow planner provider: dense")
    end

    it "raises on invalid workflow drafter provider values" do
      expect do
        described_class.from_env(
          "NOTES_ROOT" => "/notes",
          "MCP_POLICY_MODE" => "allow_all",
          "MCP_RETRIEVAL_MODE" => "lexical",
          "MCP_WORKFLOW_DRAFTER_PROVIDER" => "dense"
        )
      end.to raise_error(Llm::WorkflowPatchDrafter::InvalidProviderError, "invalid workflow patch drafter provider: dense")
    end
  end
end
