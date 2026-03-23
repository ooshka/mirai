# frozen_string_literal: true

require_relative "openai_workflow_patch_client"
require_relative "local_workflow_patch_client"
require_relative "workflow_planner"

module Llm
  class WorkflowPatchDrafter
    DEFAULT_PROVIDER = WorkflowPlanner::DEFAULT_PROVIDER
    LOCAL_PROVIDER = WorkflowPlanner::LOCAL_PROVIDER
    SUPPORTED_PROVIDERS = [DEFAULT_PROVIDER, LOCAL_PROVIDER].freeze

    class UnavailableError < StandardError; end
    class InvalidDraftError < StandardError; end
    class InvalidProviderError < StandardError; end

    def self.normalize_provider!(provider)
      normalized = send(:normalize_optional_string, provider) || DEFAULT_PROVIDER
      return normalized if SUPPORTED_PROVIDERS.include?(normalized)

      raise InvalidProviderError, "invalid workflow patch drafter provider: #{normalized}"
    end

    def initialize(
      enabled: false,
      provider: DEFAULT_PROVIDER,
      client: nil
    )
      @enabled = enabled
      @provider = self.class.normalize_provider!(provider)
      @client = client || default_client
    end

    def draft_patch(instruction:, path:, content:, context:)
      raise UnavailableError, "workflow patch drafter is unavailable" unless @enabled

      patch = @client.draft_patch(
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
      LocalWorkflowPatchClient::ConfigError,
      LocalWorkflowPatchClient::RequestError,
      LocalWorkflowPatchClient::ResponseError,
      InvalidDraftError
      raise UnavailableError, "workflow patch drafter is unavailable"
    end

    private

    def default_client
      return LocalWorkflowPatchClient.new if @provider == LOCAL_PROVIDER

      OpenAiWorkflowPatchClient.new(api_key: nil)
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
