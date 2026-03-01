# frozen_string_literal: true

require_relative "notes_indexer"
require_relative "index_store"
require_relative "lexical_chunk_scorer"
require_relative "lexical_retrieval_provider"

class NotesRetriever
  DEFAULT_LIMIT = 5
  MAX_LIMIT = 50

  def initialize(
    notes_root:,
    indexer: NotesIndexer.new(notes_root: notes_root),
    index_store: IndexStore.new(notes_root: notes_root),
    provider: nil,
    scorer: LexicalChunkScorer.new
  )
    @indexer = indexer
    @index_store = index_store
    @provider = provider || LexicalRetrievalProvider.new(scorer: scorer)
  end

  def query(text:, limit: DEFAULT_LIMIT)
    @provider.rank(query_text: text, chunks: chunks_for_query, limit: limit)
  end

  private

  def chunks_for_query
    stored_index = @index_store.read
    return stored_index.fetch(:chunks, []) if stored_index

    @indexer.index.fetch(:chunks, [])
  end
end
