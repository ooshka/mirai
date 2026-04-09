# frozen_string_literal: true

require_relative "../llm/workflow_edit_intent"

module Mcp
  class WorkflowEditIntentPatchBuilder
    class InvalidEditIntentError < StandardError; end

    def call(edit_intent:, current_content:)
      path = edit_intent.fetch(:path)
      operation = edit_intent.fetch(:operation)
      target_content = edit_intent.fetch(:content)

      unless operation == Llm::WorkflowEditIntent::OPERATION_REPLACE_CONTENT
        raise InvalidEditIntentError, "edit_intent operation is unsupported"
      end

      if current_content == target_content
        raise InvalidEditIntentError, "edit_intent must change note content"
      end

      old_lines = current_content.lines(chomp: true)
      new_lines = target_content.lines(chomp: true)

      [
        "--- a/#{path}",
        "+++ b/#{path}",
        "@@ -1,#{old_lines.length} +1,#{new_lines.length} @@",
        *old_lines.map { |line| "-#{line}" },
        *new_lines.map { |line| "+#{line}" }
      ].join("\n") + "\n"
    end
  end
end
