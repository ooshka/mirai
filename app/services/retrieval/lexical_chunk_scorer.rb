# frozen_string_literal: true

class LexicalChunkScorer
  TOKEN_BOUNDARY_CLASS = "[a-z0-9]"
  TOKEN_PATTERN = /[a-z0-9]+/

  def score(query_tokens:, content:)
    content_tokens = tokenize(content)
    query_tokens.count { |token| content_tokens.include?(token) }
  end

  def tokenize(text)
    text.to_s.downcase.scan(TOKEN_PATTERN)
  end

  def token_match(text:, token:)
    normalized = text.to_s.downcase
    pattern = /(?<!#{TOKEN_BOUNDARY_CLASS})#{Regexp.escape(token)}(?!#{TOKEN_BOUNDARY_CLASS})/
    pattern.match(normalized)
  end
end
