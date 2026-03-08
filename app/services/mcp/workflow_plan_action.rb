# frozen_string_literal: true

require_relative "../llm/workflow_planner"

module Mcp
  class WorkflowPlanAction
    class InvalidIntentError < StandardError; end

    def initialize(planner:, context_builder:)
      @planner = planner
      @context_builder = context_builder
    end

    def call(intent:, context: nil)
      normalized_intent = validate_intent(intent)
      normalized_context = validate_context(context)
      path_hint = validate_path_hint(normalized_context)
      enriched_context = @context_builder.build(input_context: normalized_context, path_hint: path_hint)
      @planner.plan(intent: normalized_intent, context: enriched_context)
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

    def validate_path_hint(context)
      value = context.fetch("path") { context[:path] }
      return nil if value.nil?
      raise InvalidIntentError, "context.path must be a string" unless value.is_a?(String)

      normalized = value.strip
      raise InvalidIntentError, "context.path must be a non-empty string" if normalized.empty?

      normalized
    end
  end
end
