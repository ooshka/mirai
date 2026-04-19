# frozen_string_literal: true

require_relative "../services/mcp/identity_context"
require_relative "../services/mcp/workflow_draft_request_validator"

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

    def parsed_workflow_draft_patch_payload
      parsed_workflow_draft_action_payload(
        error_code: "invalid_workflow_draft",
        error_message: "instruction and path are required",
        action_error_message: "workflow draft action must be workflow.draft_patch",
        params_error_message: "workflow draft params must be an object"
      )
    end

    def parsed_workflow_execute_payload
      parsed_workflow_draft_action_payload(
        error_code: "invalid_workflow_execute",
        error_message: "action and params are required",
        action_error_message: "workflow execute action must be workflow.draft_patch",
        params_error_message: "workflow execute params must be an object"
      )
    end

    def workflow_model_profile(profile, error_code:, error_message:)
      Llm::WorkflowModelProfile.resolve!(
        profile: profile,
        default_planner_provider: settings.mcp_workflow_planner_provider,
        default_drafter_provider: settings.mcp_workflow_drafter_provider
      )
    rescue Llm::WorkflowModelProfile::InvalidProfileError => e
      render_error(400, error_code, e.message || error_message)
    end

    def workflow_draft_profile(profile, error_code: "invalid_workflow_draft")
      workflow_model_profile(
        profile,
        error_code: error_code,
        error_message: "workflow model profile must be hosted, local, or auto"
      )
    end

    def build_workflow_drafter(resolved_profile:)
      Llm::WorkflowPatchClientFactory.new(
        provider: resolved_profile.drafter_provider,
        openai_api_key: ENV["OPENAI_API_KEY"],
        workflow_model: settings.mcp_openai_workflow_model,
        openai_base_url: ENV.fetch("MCP_OPENAI_BASE_URL", Llm::OpenAiWorkflowPatchClient::DEFAULT_BASE_URL),
        local_base_url: settings.mcp_local_workflow_base_url
      ).build_drafter(enabled: settings.mcp_workflow_planner_enabled)
    end

    def workflow_draft_trace_metadata(resolved_profile:)
      {
        provider: resolved_profile.drafter_provider,
        model: settings.mcp_openai_workflow_model
      }
    end

    def build_workflow_draft_patch_action(profile: nil, resolved_profile: nil, error_code: "invalid_workflow_draft")
      resolved_profile ||= workflow_draft_profile(profile, error_code: error_code)
      ::Mcp::WorkflowDraftPatchAction.new(
        notes_root: settings.notes_root,
        drafter: build_workflow_drafter(resolved_profile: resolved_profile),
        trace_metadata: workflow_draft_trace_metadata(resolved_profile: resolved_profile)
      )
    end

    def build_workflow_draft_apply_action(profile: nil, resolved_profile: nil, error_code: "invalid_workflow_draft")
      ::Mcp::WorkflowDraftApplyAction.new(
        workflow_draft_patch_action: build_workflow_draft_patch_action(
          profile: profile,
          resolved_profile: resolved_profile,
          error_code: error_code
        ),
        patch_apply_action: ::Mcp::PatchApplyAction.new(
          notes_root: settings.notes_root,
          semantic_ingestion_service: settings.semantic_ingestion_service
        )
      )
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

    def parsed_workflow_draft_action_payload(error_code:, error_message:, action_error_message:, params_error_message:)
      payload = parsed_json_payload(error_code: error_code, error_message: error_message)
      normalized_action = payload["action"].to_s.strip
      render_error(400, error_code, action_error_message) unless normalized_action == ::Mcp::ActionPolicy::ACTION_WORKFLOW_DRAFT_PATCH

      params = payload["params"]
      render_error(400, error_code, params_error_message) unless params.is_a?(Hash)

      validate_workflow_draft_action_params(params, error_code: error_code)
    end

    def validate_workflow_draft_action_params(params, error_code:)
      resolved_profile = workflow_draft_profile(params["profile"], error_code: error_code)

      {
        "instruction" => ::Mcp::WorkflowDraftRequestValidator.validate_instruction(params["instruction"]),
        "path" => ::Mcp::WorkflowDraftRequestValidator.validate_path(params["path"]),
        "context" => ::Mcp::WorkflowDraftRequestValidator.validate_context(params["context"]),
        "workflow_action_id" => validate_workflow_action_id(params["workflow_action_id"], error_code: error_code),
        "profile" => resolved_profile.profile,
        "resolved_profile" => resolved_profile
      }
    rescue ::Mcp::WorkflowDraftRequestValidator::InvalidRequestError => e
      render_error(400, error_code, e.message)
    end

    def validate_workflow_action_id(value, error_code:)
      return nil if value.nil?

      unless value.is_a?(String)
        render_error(400, error_code, "workflow_action_id must be a string")
      end

      normalized = value.strip
      return nil if normalized.empty?

      normalized
    end

    def mcp_action_policy
      @mcp_action_policy ||= ::Mcp::ActionPolicy.new(mode: settings.mcp_policy_mode)
    end

    def mcp_identity_context
      @mcp_identity_context ||= ::Mcp::IdentityContext.runtime_agent
    end
  end
end
