# frozen_string_literal: true

require_relative "notes_indexer"
require_relative "index_store"

class NotesRetriever
  DEFAULT_LIMIT = 5
  MAX_LIMIT = 50

  def initialize(notes_root:, indexer: NotesIndexer.new(notes_root: notes_root), index_store: IndexStore.new(notes_root: notes_root))
    @indexer = indexer
    @index_store = index_store
  end

  def query(text:, limit: DEFAULT_LIMIT)
    query_tokens = tokenize(text).uniq
    return [] if query_tokens.empty?

    chunks_for_query.map do |chunk|
      score = lexical_score(query_tokens, chunk.fetch(:content, ""))
      chunk.merge(score: score)
    end.select { |chunk| chunk[:score].positive? }
      .sort_by { |chunk| [-chunk[:score], chunk[:path], chunk[:chunk_index]] }
      .first(limit)
  end

  private

  def lexical_score(query_tokens, content)
    content_tokens = tokenize(content)
    query_tokens.count { |token| content_tokens.include?(token) }
  end

  def tokenize(text)
    text.to_s.downcase.scan(/[a-z0-9]+/)
  end

  def chunks_for_query
    stored_index = @index_store.read
    return stored_index.fetch(:chunks, []) if stored_index

    @indexer.index.fetch(:chunks, [])
  end
end
