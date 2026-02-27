# frozen_string_literal: true

require_relative "../notes_retriever"

module Mcp
  class IndexQueryAction
    class InvalidQueryError < StandardError; end
    class InvalidLimitError < StandardError; end

    def initialize(notes_root:, retriever: NotesRetriever.new(notes_root: notes_root))
      @retriever = retriever
    end

    def call(query:, limit: nil)
      validated_query = validate_query(query)
      validated_limit = validate_limit(limit)

      {
        query: validated_query,
        limit: validated_limit,
        chunks: @retriever.query(text: validated_query, limit: validated_limit)
      }
    end

    private

    def validate_query(query)
      normalized = query.to_s.strip
      raise InvalidQueryError, "query is required" if normalized.empty?

      normalized
    end

    def validate_limit(limit)
      return NotesRetriever::DEFAULT_LIMIT if limit.nil?

      parsed = Integer(limit)
      if parsed < 1 || parsed > NotesRetriever::MAX_LIMIT
        raise InvalidLimitError, "limit must be between 1 and #{NotesRetriever::MAX_LIMIT}"
      end

      parsed
    rescue ArgumentError, TypeError
      raise InvalidLimitError, "limit must be an integer"
    end
  end
end
