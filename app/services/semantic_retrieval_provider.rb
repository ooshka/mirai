# frozen_string_literal: true

require_relative "lexical_retrieval_provider"

class SemanticRetrievalProvider
  class UnavailableError < StandardError; end

  def initialize(enabled: false, lexical_provider: LexicalRetrievalProvider.new)
    @enabled = enabled
    @lexical_provider = lexical_provider
  end

  def rank(query_text:, chunks:, limit:)
    raise UnavailableError, "semantic retrieval provider is unavailable" unless @enabled

    # Placeholder semantic adapter: keeps ranking contract stable while provider wiring lands.
    @lexical_provider.rank(query_text: query_text, chunks: chunks, limit: limit)
  end
end
