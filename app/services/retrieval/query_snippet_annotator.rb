# frozen_string_literal: true

require_relative "lexical_chunk_scorer"

class QuerySnippetAnnotator
  def initialize(scorer: LexicalChunkScorer.new)
    @scorer = scorer
  end

  def annotate(query_text:, chunks:)
    query_tokens = @scorer.tokenize(query_text).uniq

    chunks.map do |chunk|
      content = chunk.fetch(:content, "").to_s
      chunk.merge(snippet_offset: snippet_offset(query_tokens: query_tokens, content: content))
    end
  end

  private

  def snippet_offset(query_tokens:, content:)
    query_tokens.each do |token|
      match = @scorer.token_match(text: content, token: token)
      next if match.nil?

      return {start: match.begin(0), end: match.end(0)}
    end

    nil
  end
end
