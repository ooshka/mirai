# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

class OpenAiSemanticClient
  class ConfigError < StandardError; end
  class RequestError < StandardError; end
  class ResponseError < StandardError; end

  DEFAULT_BASE_URL = "https://api.openai.com"
  DEFAULT_EMBEDDING_MODEL = "text-embedding-3-small"

  def initialize(
    api_key:,
    embedding_model: DEFAULT_EMBEDDING_MODEL,
    vector_store_id: nil,
    base_url: DEFAULT_BASE_URL
  )
    @api_key = normalize_string(api_key)
    @embedding_model = normalize_string(embedding_model)
    @vector_store_id = normalize_string(vector_store_id)
    @base_url = normalize_string(base_url) || DEFAULT_BASE_URL
  end

  def configured?
    !@api_key.nil? && !@embedding_model.nil? && !@vector_store_id.nil?
  end

  def search(query_text:, limit:)
    raise ConfigError, "openai semantic retrieval config is incomplete" unless configured?

    fetch_vector_search_results(query_text: query_text, limit: limit)
  end

  private

  def fetch_vector_search_results(query_text:, limit:)
    response = post_json(
      path: "/v1/vector_stores/#{@vector_store_id}/search",
      payload: {query: query_text, max_num_results: limit}
    )

    data = response["data"]
    raise ResponseError, "openai vector search response missing data array" unless data.is_a?(Array)

    data.map { |candidate| normalize_search_candidate(candidate) }
  end

  def post_json(path:, payload:)
    uri = URI.join(@base_url, path)
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{@api_key}"
    request["Content-Type"] = "application/json"
    request.body = JSON.generate(payload)

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(request)
    end

    unless response.is_a?(Net::HTTPSuccess)
      raise RequestError, "openai request failed with status #{response.code}"
    end

    JSON.parse(response.body)
  rescue JSON::ParserError => e
    raise ResponseError, "openai response was not valid json: #{e.message}"
  rescue Timeout::Error, Errno::ECONNREFUSED, Errno::ECONNRESET, SocketError => e
    raise RequestError, "openai request error: #{e.message}"
  end

  def normalize_search_candidate(candidate)
    raise ResponseError, "openai vector search candidate must be a hash" unless candidate.is_a?(Hash)

    attributes = candidate["attributes"]
    attributes = {} unless attributes.is_a?(Hash)

    path = candidate_path(candidate, attributes)
    chunk_index = candidate_chunk_index(attributes)
    score = candidate_score(candidate)
    content = candidate_content(candidate)

    {
      "path" => path,
      "chunk_index" => chunk_index,
      "score" => score,
      "content" => content,
      "metadata" => attributes
    }
  end

  def candidate_path(candidate, attributes)
    path = attributes["path"] || attributes["source_path"] || candidate["filename"]
    raise ResponseError, "openai vector search candidate missing path metadata" unless path.is_a?(String) && !path.empty?

    path
  end

  def candidate_chunk_index(attributes)
    Integer(attributes.fetch("chunk_index"))
  rescue KeyError, ArgumentError, TypeError
    raise ResponseError, "openai vector search candidate missing chunk_index metadata"
  end

  def candidate_score(candidate)
    score = candidate["score"]
    raise ResponseError, "openai vector search candidate score is invalid" unless score.is_a?(Numeric)

    score
  end

  def candidate_content(candidate)
    content_blocks = candidate["content"]
    return nil unless content_blocks.is_a?(Array)

    text_block = content_blocks.find do |block|
      block.is_a?(Hash) && (block["type"] == "text" || block["type"] == "output_text")
    end
    return nil unless text_block.is_a?(Hash)

    text = text_block["text"]
    text if text.is_a?(String)
  end

  def normalize_string(value)
    return nil if value.nil?

    normalized = value.to_s.strip
    return nil if normalized.empty?

    normalized
  end
end
