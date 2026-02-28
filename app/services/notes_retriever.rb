# frozen_string_literal: true

require_relative "notes_indexer"
require_relative "index_store"
require_relative "lexical_chunk_scorer"

class NotesRetriever
  DEFAULT_LIMIT = 5
  MAX_LIMIT = 50

  def initialize(
    notes_root:,
    indexer: NotesIndexer.new(notes_root: notes_root),
    index_store: IndexStore.new(notes_root: notes_root),
    scorer: LexicalChunkScorer.new
  )
    @indexer = indexer
    @index_store = index_store
    @scorer = scorer
  end

  def query(text:, limit: DEFAULT_LIMIT)
    query_tokens = tokenize(text).uniq
    return [] if query_tokens.empty?

    chunks_for_query.map do |chunk|
      score = @scorer.score(query_tokens: query_tokens, content: chunk.fetch(:content, ""))
      chunk.merge(score: score)
    end.select { |chunk| chunk[:score].positive? }
      .sort_by { |chunk| [-chunk[:score], chunk[:path], chunk[:chunk_index]] }
      .first(limit)
  end

  private

  def tokenize(text)
    text.to_s.downcase.scan(/[a-z0-9]+/)
  end

  def chunks_for_query
    stored_index = @index_store.read
    return stored_index.fetch(:chunks, []) if stored_index

    @indexer.index.fetch(:chunks, [])
  end
end
