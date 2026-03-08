# frozen_string_literal: true

require_relative "../services/mcp/identity_context"

module Routes
  module McpHelpers
    def parsed_json_payload(error_code:, error_message:)
      request.body.rewind
      payload = JSON.parse(request.body.read)
      render_error(400, error_code, error_message) unless payload.is_a?(Hash)

      payload
    rescue JSON::ParserError
      render_error(400, error_code, error_message)
    end

    def render_error(status, code, message)
      halt status, {error: {code: code, message: message}}.to_json
    end

    def parsed_patch_payload
      parsed_json_payload(error_code: "invalid_patch", error_message: "patch is required")
    end

    def parsed_notes_batch_read_payload
      parsed_json_payload(error_code: "invalid_path", error_message: "paths must be an array")
    end

    def parsed_workflow_plan_payload
      parsed_json_payload(error_code: "invalid_workflow_intent", error_message: "intent is required")
    end

    def with_mcp_error_handling
      yield
    rescue => e
      mapped = ::Mcp::ErrorMapper.map(e)
      raise unless mapped

      render_error(mapped[:status], mapped[:code], mapped[:message])
    end

    def enforce_mcp_action!(action)
      mcp_action_policy.enforce!(action, identity_context: mcp_identity_context)
    end

    def mcp_action_policy
      @mcp_action_policy ||= ::Mcp::ActionPolicy.new(mode: settings.mcp_policy_mode)
    end

    def mcp_identity_context
      @mcp_identity_context ||= ::Mcp::IdentityContext.runtime_agent
    end
  end
end
