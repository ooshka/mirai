# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

class LocalSemanticClient
  class ConfigError < StandardError; end
  class RequestError < StandardError; end
  class ResponseError < StandardError; end

  DEFAULT_BASE_URL = "http://127.0.0.1:4000"
  QUERY_PATH = "/retrieval/query"

  def initialize(base_url: nil)
    @base_url = normalize_string(base_url)
  end

  def configured?
    !@base_url.nil?
  end

  def search(query_text:, limit:)
    raise ConfigError, "local semantic retrieval config is incomplete" unless configured?

    response = post_json(path: QUERY_PATH, payload: {query: query_text, limit: limit})
    candidates = if response.is_a?(Array)
      response
    else
      response["chunks"] || response["results"]
    end
    raise ResponseError, "local semantic retrieval response missing result array" unless candidates.is_a?(Array)

    candidates.map { |candidate| normalize_candidate(candidate) }
  end

  private

  def normalize_candidate(candidate)
    raise ResponseError, "local semantic retrieval candidate must be a hash" unless candidate.is_a?(Hash)

    path = candidate["path"]
    raise ResponseError, "local semantic retrieval candidate missing path" unless path.is_a?(String) && !path.empty?

    score = candidate["score"]
    raise ResponseError, "local semantic retrieval candidate score is invalid" unless score.is_a?(Numeric)

    content = candidate["content"]
    raise ResponseError, "local semantic retrieval candidate content is invalid" unless content.is_a?(String)

    snippet_offset = candidate["snippet_offset"]
    validate_snippet_offset!(snippet_offset)

    {
      "path" => path,
      "chunk_index" => normalize_chunk_index(candidate["chunk_index"]),
      "score" => score,
      "content" => content,
      "metadata" => {"snippet_offset" => snippet_offset}
    }
  end

  def validate_snippet_offset!(snippet_offset)
    return if snippet_offset.nil?
    unless snippet_offset.is_a?(Hash)
      raise ResponseError, "local semantic retrieval candidate snippet_offset is invalid"
    end

    start_offset = snippet_offset["start"]
    end_offset = snippet_offset["end"]
    unless start_offset.is_a?(Integer) && end_offset.is_a?(Integer) && start_offset >= 0 && end_offset >= start_offset
      raise ResponseError, "local semantic retrieval candidate snippet_offset is invalid"
    end
  end

  def normalize_chunk_index(chunk_index)
    Integer(chunk_index)
  rescue ArgumentError, TypeError
    raise ResponseError, "local semantic retrieval candidate chunk_index is invalid"
  end

  def post_json(path:, payload:)
    request = Net::HTTP::Post.new(request_uri(path))
    request["Content-Type"] = "application/json"
    request.body = JSON.generate(payload)

    response = Net::HTTP.start(request.uri.host, request.uri.port, use_ssl: request.uri.scheme == "https") do |http|
      http.request(request)
    end

    unless response.is_a?(Net::HTTPSuccess)
      raise RequestError, "local semantic retrieval request failed (#{path}) with status #{response.code}"
    end

    JSON.parse(response.body)
  rescue JSON::ParserError => e
    raise ResponseError, "local semantic retrieval response was not valid json: #{e.message}"
  rescue Timeout::Error, Errno::ECONNREFUSED, Errno::ECONNRESET, SocketError => e
    raise RequestError, "local semantic retrieval request error: #{e.message}"
  end

  def request_uri(path)
    URI.join(@base_url.end_with?("/") ? @base_url : "#{@base_url}/", path.delete_prefix("/"))
  end

  def normalize_string(value)
    return nil if value.nil?

    normalized = value.to_s.strip
    return nil if normalized.empty?

    normalized
  end
end
