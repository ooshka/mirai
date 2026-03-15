# frozen_string_literal: true

require "sinatra/base"
require "json"
require "logger"
require_relative "app/services/notes/notes_reader"
require_relative "app/services/notes/safe_notes_path"
require_relative "app/services/patch/patch_validator"
require_relative "app/services/patch/patch_applier"
require_relative "app/services/runtime_config"
require_relative "app/services/indexing/index_store"
require_relative "app/services/indexing/notes_indexer"
require_relative "app/services/notes/notes_chunker"
require_relative "app/services/notes/notes_git_committer"
require_relative "app/services/notes/notes_operation_lock"
require_relative "app/services/retrieval/lexical_chunk_scorer"
require_relative "app/services/retrieval/lexical_retrieval_provider"
require_relative "app/services/retrieval/local_semantic_client"
require_relative "app/services/retrieval/openai_semantic_client"
require_relative "app/services/retrieval/semantic_retrieval_provider"
require_relative "app/services/retrieval/retrieval_provider_factory"
require_relative "app/services/retrieval/retrieval_fallback_policy"
require_relative "app/services/retrieval/notes_retriever"
require_relative "app/services/retrieval/semantic_ingestion_service"
require_relative "app/services/retrieval/openai_semantic_ingestion_processor"
require_relative "app/services/llm/openai_workflow_planner_client"
require_relative "app/services/llm/openai_workflow_patch_client"
require_relative "app/services/llm/workflow_planner"
require_relative "app/services/llm/workflow_patch_drafter"
require_relative "app/services/patch/patch_parser"
require_relative "app/services/mcp/action_policy"
require_relative "app/services/mcp/error_mapper"
require_relative "app/services/mcp/semantic_provider"
require_relative "app/services/mcp/notes_list_action"
require_relative "app/services/mcp/notes_read_action"
require_relative "app/services/mcp/notes_batch_read_action"
require_relative "app/services/mcp/patch_propose_action"
require_relative "app/services/mcp/patch_apply_action"
require_relative "app/services/mcp/index_rebuild_action"
require_relative "app/services/mcp/index_query_action"
require_relative "app/services/mcp/index_status_action"
require_relative "app/services/mcp/index_invalidate_action"
require_relative "app/services/mcp/workflow_plan_context_builder"
require_relative "app/services/mcp/workflow_plan_action"
require_relative "app/services/mcp/workflow_draft_patch_action"
require_relative "app/routes/core_routes"
require_relative "app/routes/mcp_routes"
require_relative "app/routes/mcp_helpers"

class App < Sinatra::Base
  set :bind, "0.0.0.0"
  set :port, (ENV["PORT"] || "4567").to_i

  configure do
    runtime_config = RuntimeConfig.from_env
    set :notes_root, runtime_config.notes_root
    set :mcp_policy_mode, runtime_config.mcp_policy_mode
    set :mcp_retrieval_mode, runtime_config.mcp_retrieval_mode
    set :mcp_semantic_provider_enabled, runtime_config.mcp_semantic_provider_enabled
    set :mcp_semantic_provider, runtime_config.mcp_semantic_provider
    set :mcp_semantic_configured, runtime_config.mcp_semantic_configured
    set :mcp_semantic_ingestion_enabled, runtime_config.mcp_semantic_ingestion_enabled
    set :mcp_openai_embedding_model, runtime_config.mcp_openai_embedding_model
    set :mcp_openai_vector_store_id, runtime_config.mcp_openai_vector_store_id
    set :mcp_openai_configured, runtime_config.mcp_openai_configured
    set :mcp_local_semantic_base_url, runtime_config.mcp_local_semantic_base_url
    set :mcp_local_semantic_configured, runtime_config.mcp_local_semantic_configured
    set :mcp_workflow_planner_enabled, runtime_config.mcp_workflow_planner_enabled
    set :mcp_workflow_planner_provider, runtime_config.mcp_workflow_planner_provider
    set :mcp_openai_workflow_model, runtime_config.mcp_openai_workflow_model
    set :mcp_openai_workflow_configured, runtime_config.mcp_openai_workflow_configured

    semantic_ingestion_service = NullSemanticIngestionService.new
    if runtime_config.mcp_semantic_ingestion_enabled
      openai_client = OpenAiSemanticClient.new(
        api_key: ENV["OPENAI_API_KEY"],
        embedding_model: runtime_config.mcp_openai_embedding_model,
        vector_store_id: runtime_config.mcp_openai_vector_store_id,
        base_url: ENV.fetch("MCP_OPENAI_BASE_URL", OpenAiSemanticClient::DEFAULT_BASE_URL)
      )
      processor = OpenAiSemanticIngestionProcessor.new(
        notes_root: runtime_config.notes_root,
        openai_client: openai_client
      )
      semantic_ingestion_service = AsyncSemanticIngestionService.new(
        enabled: true,
        processor: processor,
        logger: Logger.new($stdout)
      )
    end
    set :semantic_ingestion_service, semantic_ingestion_service
  end

  before do
    content_type :json
  end

  helpers Routes::McpHelpers

  register Routes::Core
  register Routes::Mcp
end
