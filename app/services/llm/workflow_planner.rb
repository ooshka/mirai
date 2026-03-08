# frozen_string_literal: true

require_relative "openai_workflow_planner_client"

module Llm
  class WorkflowPlanner
    DEFAULT_PROVIDER = "openai"
    SUPPORTED_PROVIDERS = [DEFAULT_PROVIDER].freeze

    class UnavailableError < StandardError; end
    class InvalidPlanError < StandardError; end

    def initialize(
      enabled: false,
      provider: DEFAULT_PROVIDER,
      openai_client: OpenAiWorkflowPlannerClient.new(api_key: nil)
    )
      @enabled = enabled
      @provider = normalize_provider(provider)
      @openai_client = openai_client
    end

    def plan(intent:, context:)
      raise UnavailableError, "workflow planner is unavailable" unless @enabled
      raise UnavailableError, "workflow planner is unavailable" unless @provider == DEFAULT_PROVIDER

      raw_plan = @openai_client.plan(intent: intent, context: context)
      normalize_plan(raw_plan: raw_plan, intent: intent)
    rescue OpenAiWorkflowPlannerClient::ConfigError,
      OpenAiWorkflowPlannerClient::RequestError,
      OpenAiWorkflowPlannerClient::ResponseError,
      InvalidPlanError
      raise UnavailableError, "workflow planner is unavailable"
    end

    private

    def normalize_plan(raw_plan:, intent:)
      raise InvalidPlanError, "workflow plan must be a hash" unless raw_plan.is_a?(Hash)

      actions = raw_plan["actions"]
      raise InvalidPlanError, "workflow plan actions must be an array" unless actions.is_a?(Array)

      normalized_actions = actions.map { |action| normalize_action(action) }

      {
        intent: intent,
        provider: @provider,
        rationale: normalize_optional_string(raw_plan["rationale"]),
        actions: normalized_actions
      }
    end

    def normalize_action(action)
      raise InvalidPlanError, "workflow plan action must be a hash" unless action.is_a?(Hash)

      name = normalize_optional_string(action["action"])
      raise InvalidPlanError, "workflow plan action is required" if name.nil?

      params = action["params"]
      raise InvalidPlanError, "workflow plan action params must be an object" unless params.nil? || params.is_a?(Hash)

      {
        action: name,
        reason: normalize_optional_string(action["reason"]),
        params: params || {}
      }
    end

    def normalize_provider(provider)
      normalized = normalize_optional_string(provider) || DEFAULT_PROVIDER
      return normalized if SUPPORTED_PROVIDERS.include?(normalized)

      normalized
    end

    def normalize_optional_string(value)
      return nil if value.nil?

      normalized = value.to_s.strip
      return nil if normalized.empty?

      normalized
    end
  end
end
