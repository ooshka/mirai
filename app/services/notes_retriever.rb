# frozen_string_literal: true

require_relative "notes_indexer"
require_relative "index_store"
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
    provider_factory: RetrievalProviderFactory.new,
    fallback_policy: RetrievalFallbackPolicy.new
  )
    @indexer = indexer
    @index_store = index_store
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

  def query(text:, limit: DEFAULT_LIMIT)
    chunks = chunks_for_query
    @fallback_policy.rank(
      primary_provider: @provider,
      fallback_provider: @fallback_provider,
      query_text: text,
      chunks: chunks,
      limit: limit
    )
  end

  private

  def chunks_for_query
    stored_index = @index_store.read
    return stored_index.fetch(:chunks, []) if stored_index

    @indexer.index.fetch(:chunks, [])
  end
end
