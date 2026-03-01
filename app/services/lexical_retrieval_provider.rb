# frozen_string_literal: true

require_relative "lexical_chunk_scorer"

class LexicalRetrievalProvider
  def initialize(scorer: LexicalChunkScorer.new)
    @scorer = scorer
  end

  def rank(query_text:, chunks:, limit:)
    query_tokens = @scorer.tokenize(query_text).uniq
    return [] if query_tokens.empty?

    chunks.map do |chunk|
      score = @scorer.score(query_tokens: query_tokens, content: chunk.fetch(:content, ""))
      chunk.merge(score: score)
    end.select { |chunk| chunk[:score].positive? }
      .sort_by { |chunk| [-chunk[:score], chunk[:path], chunk[:chunk_index]] }
      .first(limit)
  end
end
