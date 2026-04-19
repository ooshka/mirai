# frozen_string_literal: true

require "digest"
require "json"
require_relative "../llm/workflow_planner"

module Mcp
  class WorkflowPlanAction
    MAX_CONTEXT_BYTES = 4_000
    MAX_CONTEXT_DEPTH = 4
    MAX_ARRAY_ITEMS = 50
    MAX_KEY_LENGTH = 100

    class InvalidIntentError < StandardError; end

    def initialize(planner:, context_builder:, profile: nil)
      @planner = planner
      @context_builder = context_builder
      @profile = profile
    end

    def call(intent:, context: nil)
      normalized_intent = validate_intent(intent)
      normalized_context = validate_context(context)
      path_hint = validate_path_hint(normalized_context)
      enriched_context = @context_builder.build(input_context: normalized_context, path_hint: path_hint)
      plan = @planner.plan(intent: normalized_intent, context: enriched_context)

      plan.merge(
        actions: plan.fetch(:actions).each_with_index.map do |action, index|
          action_with_handoff_metadata(action, index: index)
        end
      )
    end

    private

    def action_with_handoff_metadata(action, index:)
      return action unless action.fetch(:action) == Llm::WorkflowPlanner::DRAFT_PATCH_ACTION

      params = action.fetch(:params).dup
      params["profile"] = @profile unless @profile.nil?
      params["workflow_action_id"] = workflow_action_id(action: action, params: params, index: index)
      action.merge(params: params)
    end

    def workflow_action_id(action:, params:, index:)
      digest = Digest::SHA256.hexdigest(
        JSON.generate(
          {
            index: index,
            action: action.fetch(:action),
            reason: action.fetch(:reason, nil),
            params: params.except("workflow_action_id")
          }
        )
      )

      "workflow-action-#{index + 1}-#{digest[0, 12]}"
    end

    def validate_intent(intent)
      normalized = intent.to_s.strip
      raise InvalidIntentError, "intent is required" if normalized.empty?

      normalized
    end

    def validate_context(context)
      return {} if context.nil?
      raise InvalidIntentError, "context must be an object" unless context.is_a?(Hash)

      normalized = normalize_hash(context, depth: 1)
      serialized_size = JSON.generate(normalized).bytesize
      raise InvalidIntentError, "context is too large" if serialized_size > MAX_CONTEXT_BYTES

      normalized
    end

    def validate_path_hint(context)
      value = context["path"]
      return nil if value.nil?
      raise InvalidIntentError, "context.path must be a string" unless value.is_a?(String)

      normalized = value.strip
      raise InvalidIntentError, "context.path must be a non-empty string" if normalized.empty?

      normalized
    end

    def normalize_hash(value, depth:)
      raise InvalidIntentError, "context is too deep" if depth > MAX_CONTEXT_DEPTH

      value.each_with_object({}) do |(key, nested_value), normalized|
        normalized_key = normalize_key(key)
        normalized[normalized_key] = normalize_value(nested_value, depth: depth + 1)
      end
    end

    def normalize_array(value, depth:)
      raise InvalidIntentError, "context is too deep" if depth > MAX_CONTEXT_DEPTH
      raise InvalidIntentError, "context array has too many items" if value.length > MAX_ARRAY_ITEMS

      value.map { |item| normalize_value(item, depth: depth + 1) }
    end

    def normalize_value(value, depth:)
      case value
      when String, Integer, Float, TrueClass, FalseClass, NilClass
        value
      when Hash
        normalize_hash(value, depth: depth)
      when Array
        normalize_array(value, depth: depth)
      else
        raise InvalidIntentError, "context contains unsupported value type"
      end
    end

    def normalize_key(key)
      normalized = key.to_s.strip
      raise InvalidIntentError, "context contains an empty key" if normalized.empty?
      raise InvalidIntentError, "context key is too long" if normalized.length > MAX_KEY_LENGTH

      normalized
    end
  end
end
