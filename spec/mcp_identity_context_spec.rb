# frozen_string_literal: true

require_relative "../app/services/mcp/identity_context"

RSpec.describe Mcp::IdentityContext do
  describe ".runtime_agent" do
    it "returns deterministic default context for unauthenticated runtime requests" do
      context = described_class.runtime_agent

      expect(context.actor).to eq(described_class::ACTOR_RUNTIME_AGENT)
      expect(context.source).to eq(described_class::SOURCE_HTTP_API)
    end
  end

  describe "#initialize" do
    it "normalizes actor and source values by trimming whitespace" do
      context = described_class.new(actor: " runtime_agent ", source: " http_api ")

      expect(context.actor).to eq("runtime_agent")
      expect(context.source).to eq("http_api")
    end
  end
end
