# frozen_string_literal: true

require_relative "local_workflow_planner_client"
require_relative "openai_workflow_planner_client"
require_relative "workflow_planner"

module Llm
  class WorkflowPlannerClientFactory
    def initialize(
      provider: WorkflowPlanner::DEFAULT_PROVIDER,
      openai_api_key: nil,
      workflow_model: OpenAiWorkflowPlannerClient::DEFAULT_MODEL,
      openai_base_url: OpenAiWorkflowPlannerClient::DEFAULT_BASE_URL,
      local_base_url: LocalWorkflowPlannerClient::DEFAULT_BASE_URL
    )
      @provider = WorkflowPlanner.normalize_provider!(provider)
      @openai_api_key = openai_api_key
      @workflow_model = workflow_model
      @openai_base_url = openai_base_url
      @local_base_url = local_base_url
    end

    def build
      return build_local_client if @provider == WorkflowPlanner::LOCAL_PROVIDER

      build_openai_client
    end

    private

    def build_openai_client
      OpenAiWorkflowPlannerClient.new(
        api_key: @openai_api_key,
        model: @workflow_model,
        base_url: @openai_base_url
      )
    end

    def build_local_client
      LocalWorkflowPlannerClient.new(
        model: @workflow_model,
        base_url: @local_base_url
      )
    end
  end
end
