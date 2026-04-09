# frozen_string_literal: true

require "json"
require "net/http"
require "uri"
require_relative "openai_workflow_patch_client"
require_relative "workflow_edit_intent"

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
              content: "Return only JSON with an edit_intent object. The edit_intent must include path, operation, and content. Use operation replace_content and set content to the full resulting markdown note text."
            },
            {
              role: "user",
              content: JSON.generate(
                instruction: instruction,
                path: path,
                content: content,
                context: context,
                constraints: [
                  "return a json object with an edit_intent field only",
                  "set edit_intent.path to the provided markdown path",
                  "use operation replace_content",
                  "set edit_intent.content to the complete updated markdown note text"
                ]
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
        error_prefix: "local workflow patch drafter"
      )
    rescue KeyError, NoMethodError
      raise ResponseError, "local workflow patch drafter response is malformed"
    rescue WorkflowEditIntent::Error => e
      raise ResponseError, e.message
    end

    private

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
