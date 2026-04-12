# frozen_string_literal: true

module Mcp
  class WorkflowExecuteAction
    class InvalidExecuteRequestError < StandardError; end

    def initialize(workflow_draft_apply_action:)
      @workflow_draft_apply_action = workflow_draft_apply_action
    end

    def call(params:)
      normalized_params = validate_params(params)

      @workflow_draft_apply_action.call(
        instruction: normalized_params["instruction"],
        path: normalized_params["path"],
        context: normalized_params["context"]
      )
    end

    private

    def validate_params(params)
      raise InvalidExecuteRequestError, "workflow execute params must be an object" unless params.is_a?(Hash)

      params
    end
  end
end
