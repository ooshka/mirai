# frozen_string_literal: true

require_relative "action_policy"

module Mcp
  class WorkflowExecuteAction
    class InvalidExecuteRequestError < StandardError; end

    def initialize(workflow_draft_apply_action:)
      @workflow_draft_apply_action = workflow_draft_apply_action
    end

    def call(action:, params:)
      normalized_action = validate_action(action)
      normalized_params = validate_params(params)

      case normalized_action
      when ActionPolicy::ACTION_WORKFLOW_DRAFT_PATCH
        @workflow_draft_apply_action.call(
          instruction: normalized_params["instruction"],
          path: normalized_params["path"],
          context: normalized_params["context"]
        )
      else
        raise InvalidExecuteRequestError, "workflow execute action must be workflow.draft_patch"
      end
    end

    private

    def validate_action(action)
      normalized = action.to_s.strip
      raise InvalidExecuteRequestError, "workflow execute action must be workflow.draft_patch" unless normalized == ActionPolicy::ACTION_WORKFLOW_DRAFT_PATCH

      normalized
    end

    def validate_params(params)
      raise InvalidExecuteRequestError, "workflow execute params must be an object" unless params.is_a?(Hash)

      params
    end
  end
end
