# frozen_string_literal: true

module Mcp
  class IdentityContext
    ACTOR_RUNTIME_AGENT = "runtime_agent"
    SOURCE_HTTP_API = "http_api"

    attr_reader :actor, :source

    def self.runtime_agent
      new(actor: ACTOR_RUNTIME_AGENT, source: SOURCE_HTTP_API)
    end

    def initialize(actor:, source:)
      @actor = actor.to_s.strip
      @source = source.to_s.strip
    end
  end
end
