# frozen_string_literal: true

require "json"
require "net/http"
require "uri"
require_relative "openai_workflow_planner_client"

module Llm
  class LocalWorkflowPlannerClient
    class ConfigError < StandardError; end
    class RequestError < StandardError; end
    class ResponseError < StandardError; end

    DEFAULT_BASE_URL = "http://127.0.0.1:11434"

    def initialize(model: OpenAiWorkflowPlannerClient::DEFAULT_MODEL, base_url: DEFAULT_BASE_URL)
      @model = normalize_string(model)
      @base_url = normalize_string(base_url)
    end

    def configured?
      !@model.nil? && !@base_url.nil?
    end

    def plan(intent:, context:)
      raise ConfigError, "local workflow planner config is incomplete" unless configured?

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
              content: "Return only JSON with keys: rationale (string), actions (array of {action, reason, params}). For draft generation steps, prefer action \"draft_note\" with params containing intent (string), path (string), and optional context (object). Do not return prose outside the JSON object."
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
      raise ResponseError, "local workflow planner response is malformed"
    rescue JSON::ParserError => e
      raise ResponseError, "local workflow planner response is not valid json: #{e.message}"
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
        raise RequestError, "local workflow planner request failed (#{path}) with status #{response.code}"
      end

      JSON.parse(response.body)
    rescue JSON::ParserError => e
      raise ResponseError, "local workflow planner response was not valid json: #{e.message}"
    rescue Timeout::Error, Errno::ECONNREFUSED, Errno::ECONNRESET, SocketError => e
      raise RequestError, "local workflow planner request error: #{e.message}"
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
