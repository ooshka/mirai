# frozen_string_literal: true

class LexicalChunkScorer
  def score(query_tokens:, content:)
    content_tokens = tokenize(content)
    query_tokens.count { |token| content_tokens.include?(token) }
  end

  private

  def tokenize(text)
    text.to_s.downcase.scan(/[a-z0-9]+/)
  end
end
