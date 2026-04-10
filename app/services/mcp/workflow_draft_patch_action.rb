# frozen_string_literal: true

require_relative "../llm/workflow_patch_drafter"
require_relative "../llm/workflow_edit_intent"
require_relative "../notes/notes_reader"
require_relative "patch_propose_action"
require_relative "workflow_edit_intent_patch_builder"

module Mcp
  class WorkflowDraftPatchAction
    class InvalidDraftRequestError < StandardError; end

    def initialize(notes_root:, drafter:, trace_metadata: {})
      @drafter = drafter
      @trace_metadata = trace_metadata
      @reader = NotesReader.new(notes_root: notes_root)
      @patch_propose_action = PatchProposeAction.new(notes_root: notes_root)
      @patch_builder = WorkflowEditIntentPatchBuilder.new
    end

    def call(instruction:, path:, context: nil)
      draft_result(instruction:, path:, context:).slice(:edit_intent, :trace)
    end

    def call_with_patch(instruction:, path:, context: nil)
      draft_result(instruction:, path:, context:)
    end

    private

    def draft_result(instruction:, path:, context:)
      normalized_instruction = validate_instruction(instruction)
      normalized_path = validate_path(path)
      normalized_context = validate_context(context)
      content = @reader.read_note(normalized_path)

      edit_intent = @drafter.draft_patch(
        instruction: normalized_instruction,
        path: normalized_path,
        content: content,
        context: normalized_context
      )

      if edit_intent.fetch(:path) != normalized_path
        raise InvalidDraftRequestError, "edit_intent path must match requested path"
      end

      patch = @patch_builder.call(edit_intent: edit_intent, current_content: content)
      proposal = @patch_propose_action.call(patch: patch)
      raise InvalidDraftRequestError, "draft patch path must match requested path" if proposal.fetch(:path) != normalized_path

      {
        edit_intent: Llm::WorkflowEditIntent.as_json(edit_intent).fetch(:edit_intent),
        patch: patch,
        trace: build_trace(
          path: normalized_path,
          content: content,
          context: normalized_context,
          proposal: proposal,
          patch: patch
        )
      }
    rescue WorkflowEditIntentPatchBuilder::InvalidEditIntentError => e
      raise InvalidDraftRequestError, e.message
    end

    def build_trace(path:, content:, context:, proposal:, patch:)
      {
        provider: @trace_metadata.fetch(:provider, nil),
        model: @trace_metadata.fetch(:model, nil),
        target: {
          path: path,
          content_bytes: content.bytesize
        },
        context: context,
        validation: {
          status: "valid",
          path: proposal.fetch(:path),
          hunk_count: proposal.fetch(:hunk_count),
          net_line_delta: proposal.fetch(:net_line_delta)
        },
        apply_ready: true,
        audit: {
          patch: patch
        }
      }
    end

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
