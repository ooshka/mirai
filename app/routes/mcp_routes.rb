# frozen_string_literal: true

module Routes
  module Mcp
    def self.registered(app)
      app.get "/mcp/notes" do
        with_mcp_error_handling do
          enforce_mcp_action!(::Mcp::ActionPolicy::ACTION_NOTES_LIST)
          ::Mcp::NotesListAction.new(notes_root: settings.notes_root).call.to_json
        end
      end

      app.get "/mcp/notes/read" do
        with_mcp_error_handling do
          enforce_mcp_action!(::Mcp::ActionPolicy::ACTION_NOTES_READ)
          ::Mcp::NotesReadAction.new(notes_root: settings.notes_root).call(path: params["path"]).to_json
        end
      end

      app.post "/mcp/notes/read_batch" do
        with_mcp_error_handling do
          enforce_mcp_action!(::Mcp::ActionPolicy::ACTION_NOTES_READ)
          payload = parsed_notes_batch_read_payload
          ::Mcp::NotesBatchReadAction.new(notes_root: settings.notes_root).call(paths: payload["paths"]).to_json
        end
      end

      app.post "/mcp/patch/propose" do
        with_mcp_error_handling do
          enforce_mcp_action!(::Mcp::ActionPolicy::ACTION_PATCH_PROPOSE)
          payload = parsed_patch_payload
          ::Mcp::PatchProposeAction.new(notes_root: settings.notes_root).call(patch: payload["patch"]).to_json
        end
      end

      app.post "/mcp/patch/apply" do
        with_mcp_error_handling do
          enforce_mcp_action!(::Mcp::ActionPolicy::ACTION_PATCH_APPLY)
          payload = parsed_patch_payload
          ::Mcp::PatchApplyAction.new(
            notes_root: settings.notes_root,
            semantic_ingestion_service: settings.semantic_ingestion_service
          ).call(patch: payload["patch"]).to_json
        end
      end

      app.post "/mcp/index/rebuild" do
        with_mcp_error_handling do
          enforce_mcp_action!(::Mcp::ActionPolicy::ACTION_INDEX_REBUILD)
          ::Mcp::IndexRebuildAction.new(notes_root: settings.notes_root).call.to_json
        end
      end

      app.get "/mcp/index/status" do
        with_mcp_error_handling do
          enforce_mcp_action!(::Mcp::ActionPolicy::ACTION_INDEX_STATUS)
          ::Mcp::IndexStatusAction.new(notes_root: settings.notes_root).call.to_json
        end
      end

      app.post "/mcp/index/invalidate" do
        with_mcp_error_handling do
          enforce_mcp_action!(::Mcp::ActionPolicy::ACTION_INDEX_INVALIDATE)
          ::Mcp::IndexInvalidateAction.new(notes_root: settings.notes_root).call.to_json
        end
      end

      app.get "/mcp/index/query" do
        with_mcp_error_handling do
          enforce_mcp_action!(::Mcp::ActionPolicy::ACTION_INDEX_QUERY)
          ::Mcp::IndexQueryAction.new(
            notes_root: settings.notes_root,
            retrieval_mode: settings.mcp_retrieval_mode,
            semantic_provider_enabled: settings.mcp_semantic_provider_enabled,
            semantic_provider: settings.mcp_semantic_provider,
            openai_api_key: ENV["OPENAI_API_KEY"],
            openai_embedding_model: settings.mcp_openai_embedding_model,
            openai_vector_store_id: settings.mcp_openai_vector_store_id,
            openai_base_url: ENV.fetch("MCP_OPENAI_BASE_URL", OpenAiSemanticClient::DEFAULT_BASE_URL),
            local_base_url: settings.mcp_local_semantic_base_url
          )
            .call(query: params["q"], limit: params["limit"], path_prefix: params["path_prefix"])
            .to_json
        end
      end

      app.post "/mcp/workflow/plan" do
        with_mcp_error_handling do
          enforce_mcp_action!(::Mcp::ActionPolicy::ACTION_WORKFLOW_PLAN)
          payload = parsed_workflow_plan_payload
          profile = workflow_model_profile(
            payload["profile"],
            error_code: "invalid_workflow_intent",
            error_message: "workflow model profile must be hosted, local, or auto"
          )
          planner_client = Llm::WorkflowPlannerClientFactory.new(
            provider: profile.planner_provider,
            openai_api_key: ENV["OPENAI_API_KEY"],
            workflow_model: settings.mcp_openai_workflow_model,
            openai_base_url: ENV.fetch("MCP_OPENAI_BASE_URL", Llm::OpenAiWorkflowPlannerClient::DEFAULT_BASE_URL),
            local_base_url: settings.mcp_local_workflow_base_url
          ).build
          planner = Llm::WorkflowPlanner.new(
            enabled: settings.mcp_workflow_planner_enabled,
            provider: profile.planner_provider,
            openai_client: planner_client,
            local_client: planner_client
          )

          context_builder = ::Mcp::WorkflowPlanContextBuilder.new(
            notes_root: settings.notes_root,
            retrieval_mode: settings.mcp_retrieval_mode,
            semantic_provider_enabled: settings.mcp_semantic_provider_enabled,
            semantic_provider: settings.mcp_semantic_provider,
            semantic_ingestion_enabled: settings.mcp_semantic_ingestion_enabled,
            semantic_configured: settings.mcp_semantic_configured
          )

          ::Mcp::WorkflowPlanAction.new(
            planner: planner,
            context_builder: context_builder,
            profile: profile.profile
          ).call(
            intent: payload["intent"],
            context: payload["context"]
          ).to_json
        end
      end

      app.post "/mcp/workflow/draft_patch" do
        with_mcp_error_handling do
          enforce_mcp_action!(::Mcp::ActionPolicy::ACTION_WORKFLOW_DRAFT_PATCH)
          payload = parsed_workflow_draft_patch_payload

          build_workflow_draft_patch_action(profile: payload["profile"]).call(
            instruction: payload["instruction"],
            path: payload["path"],
            context: payload["context"]
          ).to_json
        end
      end

      app.post "/mcp/workflow/execute" do
        with_mcp_error_handling do
          enforce_mcp_action!(::Mcp::ActionPolicy::ACTION_PATCH_APPLY)
          payload = parsed_workflow_execute_payload

          ::Mcp::WorkflowExecuteAction.new(
            workflow_draft_apply_action: build_workflow_draft_apply_action(
              profile: payload["profile"],
              error_code: "invalid_workflow_execute"
            )
          ).call(
            params: payload
          ).to_json
        end
      end

      app.post "/mcp/workflow/apply_patch" do
        with_mcp_error_handling do
          enforce_mcp_action!(::Mcp::ActionPolicy::ACTION_PATCH_APPLY)
          payload = parsed_workflow_draft_patch_payload
          build_workflow_draft_apply_action(profile: payload["profile"]).call(
            instruction: payload["instruction"],
            path: payload["path"],
            context: payload["context"]
          ).to_json
        end
      end
    end
  end
end
