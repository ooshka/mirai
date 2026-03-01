# frozen_string_literal: true

module Mcp
  module RetrievalMode
    MODE_LEXICAL = "lexical"
    MODE_SEMANTIC = "semantic"
    SUPPORTED_MODES = [MODE_LEXICAL, MODE_SEMANTIC].freeze

    class InvalidModeError < StandardError
      attr_reader :mode

      def initialize(mode)
        @mode = mode
        super("invalid MCP retrieval mode: #{mode}")
      end
    end

    module_function

    def supported_modes
      SUPPORTED_MODES
    end

    def normalize_mode!(mode)
      normalized = mode.to_s.strip.downcase
      return MODE_LEXICAL if normalized.empty?
      return normalized if SUPPORTED_MODES.include?(normalized)

      raise InvalidModeError, normalized
    end
  end
end
