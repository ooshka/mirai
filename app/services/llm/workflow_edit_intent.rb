# frozen_string_literal: true

require "json"

module Llm
  class WorkflowEditIntent
    OPERATION_REPLACE_CONTENT = "replace_content"
    SUPPORTED_OPERATIONS = [OPERATION_REPLACE_CONTENT].freeze

    class Error < StandardError; end

    def self.parse_message_content(content, error_prefix:)
      normalized_content = normalize_message_content(content, error_prefix: error_prefix)
      payload = JSON.parse(normalized_content)
      raise Error, "#{error_prefix} response must be a json object" unless payload.is_a?(Hash)

      normalize_payload(payload, error_prefix: error_prefix)
    rescue JSON::ParserError => e
      raise Error, "#{error_prefix} response was not valid json: #{e.message}"
    end

    def self.normalize_hash(edit_intent, error_prefix:)
      raise Error, "#{error_prefix} response missing edit_intent object" unless edit_intent.is_a?(Hash)

      normalize_payload(
        {"edit_intent" => stringify_keys(edit_intent)},
        error_prefix: error_prefix
      )
    end

    def self.normalize_payload(payload, error_prefix:)
      edit_intent = payload["edit_intent"]
      raise Error, "#{error_prefix} response missing edit_intent object" unless edit_intent.is_a?(Hash)

      path = normalize_required_string(edit_intent["path"], "#{error_prefix} edit_intent.path")
      operation = normalize_required_string(edit_intent["operation"], "#{error_prefix} edit_intent.operation")
      raise Error, "#{error_prefix} edit_intent.operation is unsupported" unless SUPPORTED_OPERATIONS.include?(operation)

      content = edit_intent["content"]
      raise Error, "#{error_prefix} edit_intent.content must be a string" unless content.is_a?(String)

      {
        path: path,
        operation: operation,
        content: normalize_note_content(content)
      }
    end

    def self.as_json(edit_intent)
      {
        edit_intent: {
          path: edit_intent.fetch(:path),
          operation: edit_intent.fetch(:operation),
          content: edit_intent.fetch(:content)
        }
      }
    end

    def self.normalize_message_content(content, error_prefix:)
      raise Error, "#{error_prefix} response missing message content" unless content.is_a?(String)

      normalized = content.strip
      raise Error, "#{error_prefix} response missing message content" if normalized.empty?

      normalized
    end
    private_class_method :normalize_message_content

    def self.normalize_required_string(value, label)
      raise Error, "#{label} is required" unless value.is_a?(String)

      normalized = value.strip
      raise Error, "#{label} is required" if normalized.empty?

      normalized
    end
    private_class_method :normalize_required_string

    def self.normalize_note_content(content)
      normalized = content.gsub("\r\n", "\n")
      return normalized if normalized.empty? || normalized.end_with?("\n")

      "#{normalized}\n"
    end
    private_class_method :normalize_note_content

    def self.stringify_keys(hash)
      hash.each_with_object({}) do |(key, value), result|
        result[key.to_s] = value
      end
    end
    private_class_method :stringify_keys
  end
end
