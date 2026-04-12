# frozen_string_literal: true

require_relative "local_workflow_planner_client"
require_relative "openai_workflow_planner_client"

module Llm
  class WorkflowPlanner
    DEFAULT_PROVIDER = "openai"
    LOCAL_PROVIDER = "local"
    SUPPORTED_PROVIDERS = [DEFAULT_PROVIDER, LOCAL_PROVIDER].freeze
    DRAFT_PATCH_ACTION = "workflow.draft_patch"
    SEMANTIC_DRAFT_ACTION = "draft_note"
    LEGACY_DRAFT_ACTIONS = ["patch.propose"].freeze
    SUPPORTED_PROFILES = ["hosted", "local", "auto"].freeze

    class UnavailableError < StandardError; end
    class InvalidPlanError < StandardError; end
    class InvalidProviderError < StandardError; end

    def self.normalize_provider!(provider)
      normalized = send(:normalize_optional_string, provider) || DEFAULT_PROVIDER
      return normalized if SUPPORTED_PROVIDERS.include?(normalized)

      raise InvalidProviderError, "invalid workflow planner provider: #{normalized}"
    end

    def initialize(
      enabled: false,
      provider: DEFAULT_PROVIDER,
      openai_client: OpenAiWorkflowPlannerClient.new(api_key: nil),
      local_client: LocalWorkflowPlannerClient.new
    )
      @enabled = enabled
      @provider = self.class.normalize_provider!(provider)
      @openai_client = openai_client
      @local_client = local_client
    end

    def plan(intent:, context:)
      raise UnavailableError, "workflow planner is unavailable" unless @enabled

      raw_plan = planner_client.plan(intent: intent, context: context)
      normalize_plan(raw_plan: raw_plan, intent: intent)
    rescue OpenAiWorkflowPlannerClient::ConfigError,
      OpenAiWorkflowPlannerClient::RequestError,
      OpenAiWorkflowPlannerClient::ResponseError,
      LocalWorkflowPlannerClient::ConfigError,
      LocalWorkflowPlannerClient::RequestError,
      LocalWorkflowPlannerClient::ResponseError,
      InvalidPlanError
      raise UnavailableError, "workflow planner is unavailable"
    end

    private

    def planner_client
      return @local_client if @provider == LOCAL_PROVIDER

      @openai_client
    end

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
      raise InvalidPlanError, "workflow plan action #{name} is not supported for draft generation" if LEGACY_DRAFT_ACTIONS.include?(name)

      params = action["params"]
      raise InvalidPlanError, "workflow plan action params must be an object" unless params.nil? || params.is_a?(Hash)

      normalized_name, normalized_params = normalize_action_payload(name: name, params: params || {})

      {
        action: normalized_name,
        reason: normalize_optional_string(action["reason"]),
        params: normalized_params
      }
    end

    def normalize_action_payload(name:, params:)
      case name
      when DRAFT_PATCH_ACTION
        [DRAFT_PATCH_ACTION, normalize_draft_patch_params(params)]
      when SEMANTIC_DRAFT_ACTION
        [DRAFT_PATCH_ACTION, normalize_semantic_draft_params(params)]
      else
        [name, params]
      end
    end

    def normalize_draft_patch_params(params)
      raise InvalidPlanError, "workflow.draft_patch params must be an object" unless params.is_a?(Hash)

      instruction = normalize_optional_string(params["instruction"])
      raise InvalidPlanError, "workflow.draft_patch params.instruction is required" if instruction.nil?

      path = normalize_optional_string(params["path"])
      raise InvalidPlanError, "workflow.draft_patch params.path is required" if path.nil?

      context = params.fetch("context", nil)
      raise InvalidPlanError, "workflow.draft_patch params.context must be an object" unless context.nil? || context.is_a?(Hash)

      profile = normalize_profile(params.fetch("profile", nil), error_prefix: "workflow.draft_patch")

      normalized = {
        "instruction" => instruction,
        "path" => path
      }
      normalized["context"] = context unless context.nil?
      normalized["profile"] = profile unless profile.nil?
      normalized
    end

    def normalize_semantic_draft_params(params)
      raise InvalidPlanError, "#{SEMANTIC_DRAFT_ACTION} params must be an object" unless params.is_a?(Hash)

      intent = normalize_optional_string(params["intent"])
      raise InvalidPlanError, "#{SEMANTIC_DRAFT_ACTION} params.intent is required" if intent.nil?

      path = normalize_optional_string(params["path"])
      raise InvalidPlanError, "#{SEMANTIC_DRAFT_ACTION} params.path is required" if path.nil?

      context = params.fetch("context", nil)
      raise InvalidPlanError, "#{SEMANTIC_DRAFT_ACTION} params.context must be an object" unless context.nil? || context.is_a?(Hash)

      profile = normalize_profile(params.fetch("profile", nil), error_prefix: SEMANTIC_DRAFT_ACTION)

      normalized = {
        "instruction" => intent,
        "path" => path
      }
      normalized["context"] = context unless context.nil?
      normalized["profile"] = profile unless profile.nil?
      normalized
    end

    def normalize_profile(profile, error_prefix:)
      return nil if profile.nil?
      raise InvalidPlanError, "#{error_prefix} params.profile must be a string" unless profile.is_a?(String)

      normalized = profile.strip
      return nil if normalized.empty?
      return normalized if SUPPORTED_PROFILES.include?(normalized)

      raise InvalidPlanError, "#{error_prefix} params.profile must be hosted, local, or auto"
    end

    def self.normalize_optional_string(value)
      return nil if value.nil?

      normalized = value.to_s.strip
      return nil if normalized.empty?

      normalized
    end
    private_class_method :normalize_optional_string

    def normalize_optional_string(value)
      return nil if value.nil?

      normalized = value.to_s.strip
      return nil if normalized.empty?

      normalized
    end
  end
end
