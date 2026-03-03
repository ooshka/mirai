# frozen_string_literal: true

require_relative "semantic_retrieval_provider"

class RetrievalFallbackPolicy
  def initialize(unavailable_error_class: SemanticRetrievalProvider::UnavailableError)
    @unavailable_error_class = unavailable_error_class
  end

  def rank(primary_provider:, fallback_provider:, query_text:, chunks:, limit:)
    primary_provider.rank(query_text: query_text, chunks: chunks, limit: limit)
  rescue @unavailable_error_class
    fallback_provider.rank(query_text: query_text, chunks: chunks, limit: limit)
  end
end
