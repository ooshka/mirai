# frozen_string_literal: true

module Routes
  module McpHelpers
    def render_error(status, code, message)
      halt status, {error: {code: code, message: message}}.to_json
    end

    def parsed_patch_payload
      request.body.rewind
      payload = JSON.parse(request.body.read)
      render_error(400, "invalid_patch", "patch is required") unless payload.is_a?(Hash)

      payload
    rescue JSON::ParserError
      render_error(400, "invalid_patch", "patch is required")
    end

    def with_mcp_error_handling
      yield
    rescue => e
      mapped = ::Mcp::ErrorMapper.map(e)
      raise unless mapped

      render_error(mapped[:status], mapped[:code], mapped[:message])
    end

    def enforce_mcp_action!(action)
      mcp_action_policy.enforce!(action)
    end

    def mcp_action_policy
      @mcp_action_policy ||= ::Mcp::ActionPolicy.new(mode: settings.mcp_policy_mode)
    end
  end
end
