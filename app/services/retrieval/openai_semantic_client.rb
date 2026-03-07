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

    embedding = fetch_embedding(query_text)
    fetch_vector_search_results(embedding: embedding, limit: limit)
  end

  private

  def fetch_embedding(query_text)
    response = post_json(
      path: "/v1/embeddings",
      payload: {model: @embedding_model, input: query_text}
    )

    vector = response.dig("data", 0, "embedding")
    validate_embedding!(vector)
  end

  def fetch_vector_search_results(embedding:, limit:)
    response = post_json(
      path: "/v1/vector_stores/#{@vector_store_id}/search",
      payload: {query: embedding, max_num_results: limit}
    )

    data = response["data"]
    raise ResponseError, "openai vector search response missing data array" unless data.is_a?(Array)

    data
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

  def validate_embedding!(embedding)
    unless embedding.is_a?(Array) && embedding.all? { |value| value.is_a?(Numeric) }
      raise ResponseError, "openai embedding response is malformed"
    end

    embedding
  end

  def normalize_string(value)
    return nil if value.nil?

    normalized = value.to_s.strip
    return nil if normalized.empty?

    normalized
  end
end
