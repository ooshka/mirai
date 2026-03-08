# frozen_string_literal: true

require_relative "openai_workflow_patch_client"
require_relative "workflow_planner"

module Llm
  class WorkflowPatchDrafter
    class UnavailableError < StandardError; end
    class InvalidDraftError < StandardError; end

    def initialize(
      enabled: false,
      provider: WorkflowPlanner::DEFAULT_PROVIDER,
      openai_client: OpenAiWorkflowPatchClient.new(api_key: nil)
    )
      @enabled = enabled
      @provider = normalize_provider(provider)
      @openai_client = openai_client
    end

    def draft_patch(instruction:, path:, content:, context:)
      raise UnavailableError, "workflow patch drafter is unavailable" unless @enabled
      raise UnavailableError, "workflow patch drafter is unavailable" unless @provider == WorkflowPlanner::DEFAULT_PROVIDER

      patch = @openai_client.draft_patch(
        instruction: instruction,
        path: path,
        content: content,
        context: context
      )

      normalized_patch = normalize_optional_string(patch)
      raise InvalidDraftError, "workflow patch drafter returned empty patch" if normalized_patch.nil?

      normalized_patch
    rescue OpenAiWorkflowPatchClient::ConfigError,
      OpenAiWorkflowPatchClient::RequestError,
      OpenAiWorkflowPatchClient::ResponseError,
      InvalidDraftError
      raise UnavailableError, "workflow patch drafter is unavailable"
    end

    private

    def normalize_provider(provider)
      normalize_optional_string(provider) || WorkflowPlanner::DEFAULT_PROVIDER
    end

    def normalize_optional_string(value)
      return nil if value.nil?

      normalized = value.to_s.strip
      return nil if normalized.empty?

      normalized
    end
  end
end
