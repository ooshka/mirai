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
          ::Mcp::PatchApplyAction.new(notes_root: settings.notes_root).call(patch: payload["patch"]).to_json
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
            openai_api_key: ENV["OPENAI_API_KEY"],
            openai_embedding_model: settings.mcp_openai_embedding_model,
            openai_vector_store_id: settings.mcp_openai_vector_store_id,
            openai_base_url: ENV.fetch("MCP_OPENAI_BASE_URL", OpenAiSemanticClient::DEFAULT_BASE_URL)
          )
            .call(query: params["q"], limit: params["limit"], path_prefix: params["path_prefix"])
            .to_json
        end
      end
    end
  end
end
