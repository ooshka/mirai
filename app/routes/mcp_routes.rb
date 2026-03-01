# frozen_string_literal: true

module Routes
  module Mcp
    def self.registered(app)
      app.get "/mcp/notes" do
        with_mcp_error_handling do
          ::Mcp::NotesListAction.new(notes_root: settings.notes_root).call.to_json
        end
      end

      app.get "/mcp/notes/read" do
        with_mcp_error_handling do
          ::Mcp::NotesReadAction.new(notes_root: settings.notes_root).call(path: params["path"]).to_json
        end
      end

      app.post "/mcp/patch/propose" do
        payload = parsed_patch_payload
        with_mcp_error_handling do
          ::Mcp::PatchProposeAction.new(notes_root: settings.notes_root).call(patch: payload["patch"]).to_json
        end
      end

      app.post "/mcp/patch/apply" do
        payload = parsed_patch_payload
        with_mcp_error_handling do
          ::Mcp::PatchApplyAction.new(notes_root: settings.notes_root).call(patch: payload["patch"]).to_json
        end
      end

      app.post "/mcp/index/rebuild" do
        with_mcp_error_handling do
          ::Mcp::IndexRebuildAction.new(notes_root: settings.notes_root).call.to_json
        end
      end

      app.get "/mcp/index/status" do
        with_mcp_error_handling do
          ::Mcp::IndexStatusAction.new(notes_root: settings.notes_root).call.to_json
        end
      end

      app.post "/mcp/index/invalidate" do
        with_mcp_error_handling do
          ::Mcp::IndexInvalidateAction.new(notes_root: settings.notes_root).call.to_json
        end
      end

      app.get "/mcp/index/query" do
        with_mcp_error_handling do
          ::Mcp::IndexQueryAction.new(notes_root: settings.notes_root)
            .call(query: params["q"], limit: params["limit"])
            .to_json
        end
      end
    end
  end
end
