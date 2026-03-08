# frozen_string_literal: true

require_relative "lexical_chunk_scorer"

class QuerySnippetAnnotator
  TOKEN_BOUNDARY = "[a-z0-9]"

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
    normalized_content = content.downcase

    query_tokens.each do |token|
      match = token_match(token: token, normalized_content: normalized_content)
      next if match.nil?

      return {start: match.begin(0), end: match.end(0)}
    end

    nil
  end

  def token_match(token:, normalized_content:)
    pattern = /(?<!#{TOKEN_BOUNDARY})#{Regexp.escape(token)}(?!#{TOKEN_BOUNDARY})/
    pattern.match(normalized_content)
  end
end
