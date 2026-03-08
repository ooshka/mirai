# frozen_string_literal: true

require_relative "../notes/notes_reader"
require_relative "../indexing/index_store"

module Mcp
  class WorkflowPlanContextBuilder
    NOTE_PREVIEW_LIMIT = 600

    def initialize(
      notes_root:,
      retrieval_mode:,
      semantic_provider_enabled:,
      semantic_provider:,
      semantic_ingestion_enabled:,
      semantic_configured:
    )
      @notes_reader = NotesReader.new(notes_root: notes_root)
      @index_store = IndexStore.new(notes_root: notes_root)
      @retrieval_mode = retrieval_mode
      @semantic_provider_enabled = semantic_provider_enabled
      @semantic_provider = semantic_provider
      @semantic_ingestion_enabled = semantic_ingestion_enabled
      @semantic_configured = semantic_configured
    end

    def build(input_context:, path_hint:)
      {
        input: input_context,
        hints: build_hints(path_hint: path_hint),
        note_snapshot: build_note_snapshot(path_hint: path_hint),
        retrieval_status: build_retrieval_status
      }
    end

    private

    def build_hints(path_hint:)
      {path: path_hint}
    end

    def build_note_snapshot(path_hint:)
      return nil if path_hint.nil?

      content = @notes_reader.read_note(path_hint)
      truncated = content.length > NOTE_PREVIEW_LIMIT

      {
        path: path_hint,
        bytes: content.bytesize,
        preview: content[0, NOTE_PREVIEW_LIMIT],
        preview_truncated: truncated
      }
    end

    def build_retrieval_status
      {
        retrieval_mode: @retrieval_mode,
        semantic_provider_enabled: @semantic_provider_enabled,
        semantic_provider: @semantic_provider,
        semantic_ingestion_enabled: @semantic_ingestion_enabled,
        semantic_configured: @semantic_configured,
        index_status: @index_store.status
      }
    end
  end
end
