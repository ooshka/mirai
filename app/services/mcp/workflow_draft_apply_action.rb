# frozen_string_literal: true

require_relative "workflow_draft_patch_action"
require_relative "patch_apply_action"

module Mcp
  class WorkflowDraftApplyAction
    def initialize(workflow_draft_patch_action:, patch_apply_action:)
      @workflow_draft_patch_action = workflow_draft_patch_action
      @patch_apply_action = patch_apply_action
    end

    def call(instruction:, path:, context: nil)
      draft_result = @workflow_draft_patch_action.call(
        instruction: instruction,
        path: path,
        context: context
      )
      patch = draft_result.fetch(:patch)
      apply_result = @patch_apply_action.call(patch: patch)

      apply_result.merge(audit: {patch: patch})
    end
  end
end
