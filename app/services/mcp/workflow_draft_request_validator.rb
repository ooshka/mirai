# frozen_string_literal: true

module Mcp
  class WorkflowDraftRequestValidator
    class InvalidRequestError < StandardError; end

    def self.validate_instruction(instruction)
      normalized = instruction.to_s.strip
      raise InvalidRequestError, "instruction is required" if normalized.empty?

      normalized
    end

    def self.validate_path(path)
      raise InvalidRequestError, "path must be a string" unless path.is_a?(String)

      normalized = path.strip
      raise InvalidRequestError, "path is required" if normalized.empty?

      normalized
    end

    def self.validate_context(context)
      return {} if context.nil?
      raise InvalidRequestError, "context must be an object" unless context.is_a?(Hash)

      context
    end
  end
end
