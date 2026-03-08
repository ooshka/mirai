# frozen_string_literal: true

require_relative "../patch/patch_applier"
require_relative "../indexing/index_store"
require_relative "../notes/notes_operation_lock"
require_relative "../retrieval/semantic_ingestion_service"

module Mcp
  class PatchApplyAction
    def initialize(
      notes_root:,
      applier: PatchApplier.new(notes_root: notes_root),
      index_store: IndexStore.new(notes_root: notes_root),
      operation_lock: NotesOperationLock.new(notes_root: notes_root),
      semantic_ingestion_service: NullSemanticIngestionService.new
    )
      @applier = applier
      @index_store = index_store
      @operation_lock = operation_lock
      @semantic_ingestion_service = semantic_ingestion_service
    end

    def call(patch:)
      @operation_lock.with_exclusive_lock do
        result = @applier.apply(patch)
        @index_store.delete
        enqueue_semantic_ingestion(path: result.fetch(:path))
        result
      end
    end

    private

    def enqueue_semantic_ingestion(path:)
      @semantic_ingestion_service.enqueue_for_paths(paths: [path])
    rescue StandardError
      nil
    end
  end
end
