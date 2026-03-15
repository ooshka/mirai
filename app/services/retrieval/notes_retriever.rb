# frozen_string_literal: true

require_relative "../indexing/notes_indexer"
require_relative "../indexing/index_store"
require_relative "query_metadata_echo_annotator"
require_relative "query_snippet_annotator"
require_relative "retrieval_provider_factory"
require_relative "retrieval_fallback_policy"

class NotesRetriever
  DEFAULT_LIMIT = 5
  MAX_LIMIT = 50

  def initialize(
    notes_root:,
    indexer: NotesIndexer.new(notes_root: notes_root),
    index_store: IndexStore.new(notes_root: notes_root),
    provider: nil,
    snippet_annotator: QuerySnippetAnnotator.new,
    metadata_echo_annotator: QueryMetadataEchoAnnotator.new,
    provider_factory: RetrievalProviderFactory.new,
    fallback_policy: RetrievalFallbackPolicy.new
  )
    @indexer = indexer
    @index_store = index_store
    @snippet_annotator = snippet_annotator
    @metadata_echo_annotator = metadata_echo_annotator
    @fallback_policy = fallback_policy
    if provider
      @provider = provider
      @fallback_provider = provider
    else
      provider_setup = provider_factory.build
      @provider = provider_setup.fetch(:primary_provider)
      @fallback_provider = provider_setup.fetch(:fallback_provider)
    end
  end

  def query(text:, limit: DEFAULT_LIMIT, path_prefix: nil)
    chunks = chunks_for_query(path_prefix: path_prefix)
    ranked_chunks = @fallback_policy.rank(
      primary_provider: @provider,
      fallback_provider: @fallback_provider,
      query_text: text,
      chunks: chunks,
      limit: limit
    )

    annotated_chunks = @snippet_annotator.annotate(query_text: text, chunks: ranked_chunks)

    @metadata_echo_annotator.annotate(chunks: annotated_chunks)
  end

  private

  def chunks_for_query(path_prefix:)
    stored_index = @index_store.read
    chunks = if stored_index
      stored_index.fetch(:chunks, [])
    else
      @indexer.index.fetch(:chunks, [])
    end

    return chunks if path_prefix.nil?

    chunks.select { |chunk| chunk.fetch(:path, "").start_with?(path_prefix) }
  end
end
