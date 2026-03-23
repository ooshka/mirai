# frozen_string_literal: true

require_relative "local_workflow_patch_client"
require_relative "openai_workflow_patch_client"
require_relative "workflow_patch_drafter"

module Llm
  class WorkflowPatchClientFactory
    def initialize(
      provider: WorkflowPatchDrafter::DEFAULT_PROVIDER,
      openai_api_key: nil,
      workflow_model: OpenAiWorkflowPatchClient::DEFAULT_MODEL,
      openai_base_url: OpenAiWorkflowPatchClient::DEFAULT_BASE_URL,
      local_base_url: LocalWorkflowPatchClient::DEFAULT_BASE_URL
    )
      @provider = WorkflowPatchDrafter.normalize_provider!(provider)
      @openai_api_key = openai_api_key
      @workflow_model = workflow_model
      @openai_base_url = openai_base_url
      @local_base_url = local_base_url
    end

    def build
      return build_local_client if @provider == WorkflowPatchDrafter::LOCAL_PROVIDER

      build_openai_client
    end

    private

    def build_openai_client
      OpenAiWorkflowPatchClient.new(
        api_key: @openai_api_key,
        model: @workflow_model,
        base_url: @openai_base_url
      )
    end

    def build_local_client
      LocalWorkflowPatchClient.new(
        model: @workflow_model,
        base_url: @local_base_url
      )
    end
  end
end
