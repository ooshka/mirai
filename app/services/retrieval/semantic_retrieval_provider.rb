# frozen_string_literal: true

require_relative "lexical_retrieval_provider"
require_relative "local_semantic_client"
require_relative "openai_semantic_client"

class SemanticRetrievalProvider
  class UnavailableError < StandardError; end
  class MalformedResultError < StandardError; end

  def initialize(
    enabled: false,
    lexical_provider: LexicalRetrievalProvider.new,
    semantic_client: nil,
    openai_client: nil
  )
    @enabled = enabled
    @lexical_provider = lexical_provider
    @semantic_client = semantic_client || openai_client || OpenAiSemanticClient.new(api_key: nil)
  end

  def rank(query_text:, chunks:, limit:)
    raise UnavailableError, "semantic retrieval provider is unavailable" unless @enabled

    semantic_results = @semantic_client.search(query_text: query_text, limit: limit)
    normalize_results(semantic_results: semantic_results, fallback_chunks: chunks, limit: limit)
  rescue OpenAiSemanticClient::ConfigError,
    OpenAiSemanticClient::RequestError,
    OpenAiSemanticClient::ResponseError,
    LocalSemanticClient::ConfigError,
    LocalSemanticClient::RequestError,
    LocalSemanticClient::ResponseError,
    MalformedResultError
    raise UnavailableError, "semantic retrieval provider is unavailable"
  end

  private

  def normalize_results(semantic_results:, fallback_chunks:, limit:)
    chunk_lookup = fallback_chunks.each_with_object({}) do |chunk, memo|
      key = [chunk.fetch(:path), Integer(chunk.fetch(:chunk_index))]
      memo[key] = chunk
    end

    normalized = semantic_results.filter_map do |candidate|
      normalize_candidate(candidate, chunk_lookup)
    end

    normalized
      .sort_by { |chunk| [-chunk.fetch(:score), chunk.fetch(:path), chunk.fetch(:chunk_index)] }
      .first(limit)
  end

  def normalize_candidate(candidate, chunk_lookup)
    raise MalformedResultError, "semantic candidate must be a hash" unless candidate.is_a?(Hash)

    metadata = candidate["metadata"]
    metadata = {} unless metadata.is_a?(Hash)

    path = extract_path(candidate, metadata)
    chunk_index = extract_chunk_index(candidate, metadata)
    key = [path, chunk_index]
    fallback_chunk = chunk_lookup[key]
    return nil if fallback_chunk.nil?

    content = extract_content(fallback_chunk)
    score = extract_score(candidate)

    {path: path, chunk_index: chunk_index, content: content, score: score.to_f}
  end

  def extract_path(candidate, metadata)
    path = candidate["path"] || metadata["path"]
    raise MalformedResultError, "semantic candidate path is missing" unless path.is_a?(String) && !path.empty?

    path
  end

  def extract_chunk_index(candidate, metadata)
    chunk_index = candidate["chunk_index"]
    chunk_index = metadata["chunk_index"] if chunk_index.nil?

    Integer(chunk_index)
  rescue ArgumentError, TypeError
    raise MalformedResultError, "semantic candidate chunk_index is invalid"
  end

  def extract_content(fallback_chunk)
    content = fallback_chunk.fetch(:content, nil)
    raise MalformedResultError, "semantic candidate content is missing" unless content.is_a?(String)

    content
  end

  def extract_score(candidate)
    score = candidate["score"]
    raise MalformedResultError, "semantic candidate score is invalid" unless score.is_a?(Numeric)

    score
  end
end
