# frozen_string_literal: true

require "json"
require "net/http"
require "uri"
require_relative "openai_workflow_patch_client"

module Llm
  class LocalWorkflowPatchClient
    class ConfigError < StandardError; end
    class RequestError < StandardError; end
    class ResponseError < StandardError; end

    DEFAULT_BASE_URL = "http://127.0.0.1:11434"

    def initialize(model: OpenAiWorkflowPatchClient::DEFAULT_MODEL, base_url: DEFAULT_BASE_URL)
      @model = normalize_string(model)
      @base_url = normalize_string(base_url)
    end

    def configured?
      !@model.nil? && !@base_url.nil?
    end

    def draft_patch(instruction:, path:, content:, context:)
      raise ConfigError, "local workflow patch drafter config is incomplete" unless configured?

      response = post_json(
        path: "/v1/chat/completions",
        payload: {
          model: @model,
          temperature: 0,
          response_format: {type: "json_object"},
          messages: [
            {
              role: "system",
              content: "Return only JSON with a single key 'patch' whose value is a single-file unified diff for the provided markdown note."
            },
            {
              role: "user",
              content: JSON.generate(
                instruction: instruction,
                path: path,
                content: content,
                context: context,
                constraints: [
                  "return a single-file unified diff only",
                  "target the provided markdown path",
                  "keep the patch minimal"
                ]
              )
            }
          ]
        }
      )

      content = response
        .fetch("choices")
        .first
        .fetch("message")
        .fetch("content")

      extract_patch(content)
    rescue KeyError, NoMethodError
      raise ResponseError, "local workflow patch drafter response is malformed"
    end

    private

    def extract_patch(content)
      normalized_content = normalize_string(content)
      raise ResponseError, "local workflow patch drafter response missing message content" if normalized_content.nil?

      return normalized_content if normalized_content.start_with?("--- ")

      payload = JSON.parse(normalized_content)
      raise ResponseError, "local workflow patch drafter response must be a json object or unified diff text" unless payload.is_a?(Hash)

      patch = normalize_string(payload["patch"])
      raise ResponseError, "local workflow patch drafter response missing non-empty patch string" if patch.nil?

      patch
    rescue JSON::ParserError => e
      raise ResponseError, "local workflow patch drafter response was not valid json or unified diff text: #{e.message}"
    end

    def post_json(path:, payload:)
      request = Net::HTTP::Post.new(request_uri(path))
      request["Content-Type"] = "application/json"
      request.body = JSON.generate(payload)

      response = Net::HTTP.start(request.uri.host, request.uri.port, use_ssl: request.uri.scheme == "https") do |http|
        http.request(request)
      end

      unless response.is_a?(Net::HTTPSuccess)
        raise RequestError, "local workflow patch drafter request failed (#{path}) with status #{response.code}"
      end

      JSON.parse(response.body)
    rescue JSON::ParserError => e
      raise ResponseError, "local workflow patch drafter response was not valid json: #{e.message}"
    rescue Timeout::Error, Errno::ECONNREFUSED, Errno::ECONNRESET, SocketError => e
      raise RequestError, "local workflow patch drafter request error: #{e.message}"
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
end
