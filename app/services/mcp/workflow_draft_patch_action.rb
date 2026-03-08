# frozen_string_literal: true

require_relative "../llm/workflow_patch_drafter"
require_relative "../notes/notes_reader"
require_relative "patch_propose_action"

module Mcp
  class WorkflowDraftPatchAction
    class InvalidDraftRequestError < StandardError; end

    def initialize(notes_root:, drafter:)
      @drafter = drafter
      @reader = NotesReader.new(notes_root: notes_root)
      @patch_propose_action = PatchProposeAction.new(notes_root: notes_root)
    end

    def call(instruction:, path:, context: nil)
      normalized_instruction = validate_instruction(instruction)
      normalized_path = validate_path(path)
      normalized_context = validate_context(context)
      content = @reader.read_note(normalized_path)

      patch = @drafter.draft_patch(
        instruction: normalized_instruction,
        path: normalized_path,
        content: content,
        context: normalized_context
      )

      proposal = @patch_propose_action.call(patch: patch)
      if proposal.fetch(:path) != normalized_path
        raise InvalidDraftRequestError, "draft patch path must match requested path"
      end

      {patch: patch}
    end

    private

    def validate_instruction(instruction)
      normalized = instruction.to_s.strip
      raise InvalidDraftRequestError, "instruction is required" if normalized.empty?

      normalized
    end

    def validate_path(path)
      raise InvalidDraftRequestError, "path must be a string" unless path.is_a?(String)

      normalized = path.strip
      raise InvalidDraftRequestError, "path is required" if normalized.empty?

      normalized
    end

    def validate_context(context)
      return {} if context.nil?
      raise InvalidDraftRequestError, "context must be an object" unless context.is_a?(Hash)

      context
    end
  end
end
