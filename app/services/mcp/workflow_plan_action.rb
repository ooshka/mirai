# frozen_string_literal: true

require_relative "../llm/workflow_planner"

module Mcp
  class WorkflowPlanAction
    class InvalidIntentError < StandardError; end

    def initialize(planner:)
      @planner = planner
    end

    def call(intent:, context: nil)
      normalized_intent = validate_intent(intent)
      normalized_context = validate_context(context)
      @planner.plan(intent: normalized_intent, context: normalized_context)
    end

    private

    def validate_intent(intent)
      normalized = intent.to_s.strip
      raise InvalidIntentError, "intent is required" if normalized.empty?

      normalized
    end

    def validate_context(context)
      return {} if context.nil?
      raise InvalidIntentError, "context must be an object" unless context.is_a?(Hash)

      context
    end
  end
end
