# frozen_string_literal: true

require_relative "workflow_draft_patch_action"
require_relative "patch_apply_action"

module Mcp
  class WorkflowDraftApplyAction
    ACTION_ECHO = ActionPolicy::ACTION_WORKFLOW_DRAFT_PATCH

    def initialize(workflow_draft_patch_action:, patch_apply_action:)
      @workflow_draft_patch_action = workflow_draft_patch_action
      @patch_apply_action = patch_apply_action
    end

    def call(instruction:, path:, context: nil, workflow_action_id: nil)
      draft_result = @workflow_draft_patch_action.call_with_patch(
        instruction: instruction,
        path: path,
        context: context,
        workflow_action_id: workflow_action_id
      )
      patch = draft_result.fetch(:patch)
      apply_result = @patch_apply_action.call(patch: patch)
      trace = draft_result.fetch(:trace, {})
      audit = {
        patch: patch,
        provider: trace[:provider],
        model: trace[:model]
      }
      audit[:workflow_action_id] = trace[:workflow_action_id] unless trace[:workflow_action_id].nil?

      apply_result.merge(
        action: ACTION_ECHO,
        audit: audit
      )
    end
  end
end
