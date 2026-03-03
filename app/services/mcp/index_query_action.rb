# frozen_string_literal: true

require "pathname"
require_relative "../notes_retriever"
require_relative "../retrieval_provider_factory"

module Mcp
  class IndexQueryAction
    class InvalidQueryError < StandardError; end
    class InvalidLimitError < StandardError; end

    def initialize(
      notes_root:,
      retrieval_mode: RetrievalProviderFactory::MODE_LEXICAL,
      semantic_provider_enabled: false,
      retriever: nil
    )
      @notes_root = File.expand_path(notes_root)
      @retriever = retriever || NotesRetriever.new(
        notes_root: notes_root,
        provider_factory: RetrievalProviderFactory.new(
          mode: retrieval_mode,
          semantic_provider_enabled: semantic_provider_enabled
        )
      )
    end

    def call(query:, limit: nil, path_prefix: nil)
      validated_query = validate_query(query)
      validated_limit = validate_limit(limit)
      validated_path_prefix = validate_path_prefix(path_prefix)

      {
        query: validated_query,
        limit: validated_limit,
        chunks: @retriever.query(
          text: validated_query,
          limit: validated_limit,
          path_prefix: validated_path_prefix
        )
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

    def validate_path_prefix(path_prefix)
      return nil if path_prefix.nil?
      raise InvalidQueryError, "path_prefix must be a string" unless path_prefix.is_a?(String)

      normalized = path_prefix.strip
      raise InvalidQueryError, "path_prefix must be a non-empty string" if normalized.empty?
      raise InvalidQueryError, "absolute paths are not allowed" if Pathname.new(normalized).absolute?

      absolute_prefix = File.expand_path(normalized, @notes_root)
      raise InvalidQueryError, "path_prefix escapes notes root" unless contained?(absolute_prefix)

      relative_prefix = Pathname.new(absolute_prefix).relative_path_from(Pathname.new(@notes_root)).to_s
      return nil if relative_prefix == "."

      relative_prefix.sub(%r{/\z}, "")
    end

    def contained?(absolute_path)
      absolute_path == @notes_root || absolute_path.start_with?("#{@notes_root}/")
    end
  end
end
