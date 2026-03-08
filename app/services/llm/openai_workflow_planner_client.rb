# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module Llm
  class OpenAiWorkflowPlannerClient
    class ConfigError < StandardError; end
    class RequestError < StandardError; end
    class ResponseError < StandardError; end

    DEFAULT_BASE_URL = "https://api.openai.com"
    DEFAULT_MODEL = "gpt-4.1-mini"

    def initialize(api_key:, model: DEFAULT_MODEL, base_url: DEFAULT_BASE_URL)
      @api_key = normalize_string(api_key)
      @model = normalize_string(model)
      @base_url = normalize_string(base_url) || DEFAULT_BASE_URL
    end

    def configured?
      !@api_key.nil? && !@model.nil?
    end

    def plan(intent:, context:)
      raise ConfigError, "openai workflow planner config is incomplete" unless configured?

      prompt_payload = {
        intent: intent,
        context: context
      }

      response = post_json(
        path: "/v1/chat/completions",
        payload: {
          model: @model,
          temperature: 0,
          response_format: {type: "json_object"},
          messages: [
            {
              role: "system",
              content: "Return only JSON with keys: rationale (string), actions (array of {action, reason, params})."
            },
            {
              role: "user",
              content: JSON.generate(prompt_payload)
            }
          ]
        }
      )

      content = response
        .fetch("choices")
        .first
        .fetch("message")
        .fetch("content")

      JSON.parse(content)
    rescue KeyError, NoMethodError
      raise ResponseError, "openai workflow planner response is malformed"
    rescue JSON::ParserError => e
      raise ResponseError, "openai workflow planner response is not valid json: #{e.message}"
    end

    private

    def post_json(path:, payload:)
      request = Net::HTTP::Post.new(request_uri(path))
      request["Authorization"] = "Bearer #{@api_key}"
      request["Content-Type"] = "application/json"
      request.body = JSON.generate(payload)

      response = Net::HTTP.start(request.uri.host, request.uri.port, use_ssl: request.uri.scheme == "https") do |http|
        http.request(request)
      end

      unless response.is_a?(Net::HTTPSuccess)
        raise RequestError, "openai workflow planner request failed (#{path}) with status #{response.code}"
      end

      JSON.parse(response.body)
    rescue JSON::ParserError => e
      raise ResponseError, "openai workflow planner response was not valid json: #{e.message}"
    rescue Timeout::Error, Errno::ECONNREFUSED, Errno::ECONNRESET, SocketError => e
      raise RequestError, "openai workflow planner request error: #{e.message}"
    end

    def request_uri(path)
      URI.join(@base_url, path)
    end

    def normalize_string(value)
      return nil if value.nil?

      normalized = value.to_s.strip
      return nil if normalized.empty?

      normalized
    end
  end
end
