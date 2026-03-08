# frozen_string_literal: true

require "json"
require "net/http"
require "securerandom"
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

  def upsert_path_chunks(path:, chunks:)
    raise ConfigError, "openai semantic retrieval config is incomplete" unless configured?

    normalized_path = normalize_string(path)
    raise ResponseError, "path is required" if normalized_path.nil?

    normalized_chunks = normalize_chunks(chunks)

    vector_store_files_for_path(path: normalized_path).each do |vector_store_file|
      vector_store_file_id = vector_store_file["id"]
      next unless vector_store_file_id.is_a?(String) && !vector_store_file_id.empty?

      delete_json(path: "/v1/vector_stores/#{@vector_store_id}/files/#{vector_store_file_id}")
    end

    normalized_chunks.each do |chunk|
      uploaded_file = post_multipart_file(
        path: "/v1/files",
        purpose: "assistants",
        file_name: "chunk-#{chunk.fetch(:chunk_index)}.txt",
        file_content: chunk.fetch(:content)
      )
      file_id = uploaded_file.fetch("id")

      post_json(
        path: "/v1/vector_stores/#{@vector_store_id}/files",
        payload: {
          file_id: file_id,
          attributes: {
            path: normalized_path,
            chunk_index: chunk.fetch(:chunk_index)
          }
        }
      )
    end
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
    request = Net::HTTP::Post.new(request_uri(path))
    apply_auth!(request)
    request["Content-Type"] = "application/json"
    request.body = JSON.generate(payload)

    perform_json_request(request: request, request_path: path)
  end

  def get_json(path:)
    request = Net::HTTP::Get.new(request_uri(path))
    apply_auth!(request)

    perform_json_request(request: request, request_path: path)
  end

  def delete_json(path:)
    request = Net::HTTP::Delete.new(request_uri(path))
    apply_auth!(request)

    perform_json_request(request: request, request_path: path)
  end

  def post_multipart_file(path:, purpose:, file_name:, file_content:)
    request = Net::HTTP::Post.new(request_uri(path))
    apply_auth!(request)

    boundary = "----mirai-#{SecureRandom.hex(16)}"
    request["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
    request.body = multipart_body(
      boundary: boundary,
      purpose: purpose,
      file_name: file_name,
      file_content: file_content
    )

    perform_json_request(request: request, request_path: path)
  end

  def perform_json_request(request:, request_path:)
    uri = request.uri

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(request)
    end

    unless response.is_a?(Net::HTTPSuccess)
      raise RequestError, "openai request failed (#{request_path}) with status #{response.code}"
    end

    JSON.parse(response.body)
  rescue JSON::ParserError => e
    raise ResponseError, "openai response was not valid json: #{e.message}"
  rescue Timeout::Error, Errno::ECONNREFUSED, Errno::ECONNRESET, SocketError => e
    raise RequestError, "openai request error: #{e.message}"
  end

  def vector_store_files_for_path(path:)
    request_path = "/v1/vector_stores/#{@vector_store_id}/files?limit=100"
    matching = []

    loop do
      response = get_json(path: request_path)
      data = response["data"]
      raise ResponseError, "openai vector store file list response missing data array" unless data.is_a?(Array)

      matching.concat(data.select do |vector_store_file|
        attributes = vector_store_file["attributes"]
        attributes.is_a?(Hash) && attributes["path"] == path
      end)

      break unless response["has_more"] == true

      last_id = response["last_id"]
      unless last_id.is_a?(String) && !last_id.empty?
        raise ResponseError, "openai vector store file list response missing last_id for pagination"
      end

      request_path = "/v1/vector_stores/#{@vector_store_id}/files?limit=100&after=#{URI.encode_www_form_component(last_id)}"
    end

    matching
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

  def request_uri(path)
    URI.join(@base_url, path)
  end

  def apply_auth!(request)
    request["Authorization"] = "Bearer #{@api_key}"
  end

  def multipart_body(boundary:, purpose:, file_name:, file_content:)
    body = +""
    body << "--#{boundary}\r\n"
    body << "Content-Disposition: form-data; name=\"purpose\"\r\n\r\n"
    body << "#{purpose}\r\n"
    body << "--#{boundary}\r\n"
    body << "Content-Disposition: form-data; name=\"file\"; filename=\"#{file_name}\"\r\n"
    body << "Content-Type: text/plain\r\n\r\n"
    body << file_content
    body << "\r\n--#{boundary}--\r\n"
    body
  end

  def normalize_chunks(chunks)
    Array(chunks).map do |chunk|
      raise ResponseError, "chunk must be a hash" unless chunk.is_a?(Hash)

      chunk_index = Integer(chunk.fetch(:chunk_index))
      content = chunk.fetch(:content)
      raise ResponseError, "chunk content is missing" unless content.is_a?(String)

      {
        chunk_index: chunk_index,
        content: content
      }
    end.sort_by { |chunk| chunk.fetch(:chunk_index) }
  rescue KeyError, ArgumentError, TypeError
    raise ResponseError, "chunk metadata is invalid"
  end
end
