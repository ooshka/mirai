# frozen_string_literal: true

require_relative "../services/mcp/retrieval_mode"

module Routes
  module Core
    def self.registered(app)
      app.get "/health" do
        {ok: true}.to_json
      end

      app.get "/config" do
        {
          notes_root: settings.notes_root,
          mcp_policy_mode: settings.mcp_policy_mode,
          mcp_policy_modes_supported: ::Mcp::ActionPolicy.supported_modes,
          mcp_retrieval_mode: settings.mcp_retrieval_mode,
          mcp_retrieval_modes_supported: ::Mcp::RetrievalMode.supported_modes,
          mcp_semantic_provider_enabled: settings.mcp_semantic_provider_enabled,
          mcp_semantic_provider: settings.mcp_semantic_provider,
          mcp_semantic_configured: settings.mcp_semantic_configured,
          mcp_semantic_ingestion_enabled: settings.mcp_semantic_ingestion_enabled,
          mcp_openai_embedding_model: settings.mcp_openai_embedding_model,
          mcp_openai_vector_store_id: settings.mcp_openai_vector_store_id,
          mcp_openai_configured: settings.mcp_openai_configured,
          mcp_local_semantic_base_url: settings.mcp_local_semantic_base_url,
          mcp_local_semantic_configured: settings.mcp_local_semantic_configured,
          mcp_workflow_planner_enabled: settings.mcp_workflow_planner_enabled,
          mcp_workflow_planner_provider: settings.mcp_workflow_planner_provider,
          mcp_workflow_drafter_provider: settings.mcp_workflow_drafter_provider,
          mcp_openai_workflow_model: settings.mcp_openai_workflow_model,
          mcp_openai_workflow_configured: settings.mcp_openai_workflow_configured,
          mcp_local_workflow_base_url: settings.mcp_local_workflow_base_url,
          mcp_local_workflow_configured: settings.mcp_local_workflow_configured,
          mcp_workflow_planner_configured: settings.mcp_workflow_planner_configured,
          mcp_workflow_drafter_configured: settings.mcp_workflow_drafter_configured
        }.to_json
      end
    end
  end
end
