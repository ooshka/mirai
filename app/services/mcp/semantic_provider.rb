# frozen_string_literal: true

module Mcp
  module SemanticProvider
    DEFAULT_PROVIDER = "openai"
    LOCAL_PROVIDER = "local"
    SUPPORTED_PROVIDERS = [DEFAULT_PROVIDER, LOCAL_PROVIDER].freeze

    class InvalidProviderError < StandardError
      def initialize(provider)
        super("invalid MCP semantic provider: #{provider}")
      end
    end

    def self.supported_providers
      SUPPORTED_PROVIDERS
    end

    def self.normalize_provider!(provider)
      normalized = provider.to_s.strip
      normalized = DEFAULT_PROVIDER if normalized.empty?
      return normalized if SUPPORTED_PROVIDERS.include?(normalized)

      raise InvalidProviderError, normalized
    end
  end
end
