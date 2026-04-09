# frozen_string_literal: true

require "json"
require "net/http"
require "uri"
require_relative "openai_workflow_planner_client"
require_relative "workflow_edit_intent"

module Llm
  class OpenAiWorkflowPatchClient
    class ConfigError < StandardError; end
    class RequestError < StandardError; end
    class ResponseError < StandardError; end

    DEFAULT_BASE_URL = "https://api.openai.com"
    DEFAULT_MODEL = OpenAiWorkflowPlannerClient::DEFAULT_MODEL

    def initialize(api_key:, model: DEFAULT_MODEL, base_url: DEFAULT_BASE_URL)
      @api_key = normalize_string(api_key)
      @model = normalize_string(model)
      @base_url = normalize_string(base_url) || DEFAULT_BASE_URL
    end

    def configured?
      !@api_key.nil? && !@model.nil?
    end

    def draft_patch(instruction:, path:, content:, context:)
      raise ConfigError, "openai workflow patch drafter config is incomplete" unless configured?

      response = post_json(
        path: "/v1/chat/completions",
        payload: {
          model: @model,
          temperature: 0,
          response_format: {type: "json_object"},
          messages: [
            {
              role: "system",
              content: "Return only JSON with an edit_intent object. The edit_intent must include path, operation, and content. Use operation replace_content and set content to the full resulting markdown note text."
            },
            {
              role: "user",
              content: JSON.generate(
                instruction: instruction,
                path: path,
                content: content,
                context: context
              )
            }
          ]
        }
      )

      message_content = response
        .fetch("choices")
        .first
        .fetch("message")
        .fetch("content")

      WorkflowEditIntent.parse_message_content(
        message_content,
        error_prefix: "openai workflow patch drafter"
      )
    rescue KeyError, NoMethodError
      raise ResponseError, "openai workflow patch drafter response is malformed"
    rescue WorkflowEditIntent::Error => e
      raise ResponseError, e.message
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
        raise RequestError, "openai workflow patch drafter request failed (#{path}) with status #{response.code}"
      end

      JSON.parse(response.body)
    rescue JSON::ParserError => e
      raise ResponseError, "openai workflow patch drafter response was not valid json: #{e.message}"
    rescue Timeout::Error, Errno::ECONNREFUSED, Errno::ECONNRESET, SocketError => e
      raise RequestError, "openai workflow patch drafter request error: #{e.message}"
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
