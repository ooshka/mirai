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
          ::Mcp::IndexQueryAction.new(notes_root: settings.notes_root)
            .call(query: params["q"], limit: params["limit"])
            .to_json
        end
      end
    end
  end
end
