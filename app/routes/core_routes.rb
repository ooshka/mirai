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
          mcp_retrieval_modes_supported: ::Mcp::RetrievalMode.supported_modes
        }.to_json
      end
    end
  end
end
