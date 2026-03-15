# frozen_string_literal: true

require_relative "mcp/action_policy"
require_relative "mcp/boolean_flag"
require_relative "mcp/retrieval_mode"
require_relative "mcp/semantic_provider"
require_relative "llm/workflow_planner"
require_relative "retrieval/local_semantic_client"
require_relative "retrieval/openai_semantic_client"

class RuntimeConfig
  DEFAULT_NOTES_ROOT = "/notes"

  attr_reader :notes_root, :mcp_policy_mode, :mcp_retrieval_mode, :mcp_semantic_provider_enabled,
    :mcp_semantic_provider, :mcp_semantic_configured, :mcp_semantic_ingestion_enabled, :mcp_openai_embedding_model,
    :mcp_openai_vector_store_id, :mcp_openai_configured, :mcp_local_semantic_base_url, :mcp_local_semantic_configured,
    :mcp_workflow_planner_enabled, :mcp_workflow_planner_provider, :mcp_openai_workflow_model,
    :mcp_openai_workflow_configured

  def self.from_env(env = ENV)
    new(
      notes_root: env.fetch("NOTES_ROOT", DEFAULT_NOTES_ROOT),
      mcp_policy_mode: env.fetch("MCP_POLICY_MODE", Mcp::ActionPolicy::MODE_ALLOW_ALL),
      mcp_retrieval_mode: env.fetch("MCP_RETRIEVAL_MODE", Mcp::RetrievalMode::MODE_LEXICAL),
      mcp_semantic_provider_enabled: env.fetch("MCP_SEMANTIC_PROVIDER_ENABLED", "false"),
      mcp_semantic_provider: env.fetch("MCP_SEMANTIC_PROVIDER", Mcp::SemanticProvider::DEFAULT_PROVIDER),
      mcp_semantic_ingestion_enabled: env.fetch("MCP_SEMANTIC_INGESTION_ENABLED", "false"),
      mcp_openai_embedding_model: env.fetch("MCP_OPENAI_EMBEDDING_MODEL", OpenAiSemanticClient::DEFAULT_EMBEDDING_MODEL),
      mcp_openai_vector_store_id: env["MCP_OPENAI_VECTOR_STORE_ID"],
      mcp_local_semantic_base_url: env["MCP_LOCAL_SEMANTIC_BASE_URL"],
      mcp_workflow_planner_enabled: env.fetch("MCP_WORKFLOW_PLANNER_ENABLED", "false"),
      mcp_workflow_planner_provider: env.fetch("MCP_WORKFLOW_PLANNER_PROVIDER", Llm::WorkflowPlanner::DEFAULT_PROVIDER),
      mcp_openai_workflow_model: env.fetch("MCP_OPENAI_WORKFLOW_MODEL", Llm::OpenAiWorkflowPlannerClient::DEFAULT_MODEL),
      openai_api_key: env["OPENAI_API_KEY"]
    )
  end

  def initialize(
    notes_root:,
    mcp_policy_mode:,
    mcp_retrieval_mode:,
    mcp_semantic_provider_enabled:,
    mcp_semantic_provider:,
    mcp_semantic_ingestion_enabled:,
    mcp_openai_embedding_model:,
    mcp_openai_vector_store_id:,
    mcp_local_semantic_base_url:,
    mcp_workflow_planner_enabled:,
    mcp_workflow_planner_provider:,
    mcp_openai_workflow_model:,
    openai_api_key:
  )
    @notes_root = notes_root
    @mcp_policy_mode = Mcp::ActionPolicy.normalize_mode(mcp_policy_mode)
    @mcp_retrieval_mode = Mcp::RetrievalMode.normalize_mode!(mcp_retrieval_mode)
    @mcp_semantic_provider_enabled = Mcp::BooleanFlag.enabled?(mcp_semantic_provider_enabled)
    @mcp_semantic_provider = Mcp::SemanticProvider.normalize_provider!(mcp_semantic_provider)
    @mcp_semantic_ingestion_enabled = Mcp::BooleanFlag.enabled?(mcp_semantic_ingestion_enabled)
    @mcp_openai_embedding_model = normalize_string(mcp_openai_embedding_model) || OpenAiSemanticClient::DEFAULT_EMBEDDING_MODEL
    @mcp_openai_vector_store_id = normalize_string(mcp_openai_vector_store_id)
    @mcp_local_semantic_base_url = normalize_string(mcp_local_semantic_base_url)
    @mcp_workflow_planner_enabled = Mcp::BooleanFlag.enabled?(mcp_workflow_planner_enabled)
    @mcp_workflow_planner_provider = normalize_string(mcp_workflow_planner_provider) || Llm::WorkflowPlanner::DEFAULT_PROVIDER
    @mcp_openai_workflow_model = normalize_string(mcp_openai_workflow_model) || Llm::OpenAiWorkflowPlannerClient::DEFAULT_MODEL
    @mcp_openai_configured = !normalize_string(openai_api_key).nil? && !@mcp_openai_vector_store_id.nil?
    @mcp_local_semantic_configured = !@mcp_local_semantic_base_url.nil?
    @mcp_semantic_configured = if @mcp_semantic_provider == Mcp::SemanticProvider::LOCAL_PROVIDER
      @mcp_local_semantic_configured
    else
      @mcp_openai_configured
    end
    @mcp_openai_workflow_configured = !normalize_string(openai_api_key).nil? && !@mcp_openai_workflow_model.nil?
  end

  private

  def normalize_string(value)
    return nil if value.nil?

    normalized = value.to_s.strip
    return nil if normalized.empty?

    normalized
  end
end
