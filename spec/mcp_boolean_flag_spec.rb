# frozen_string_literal: true

require_relative "../app/services/mcp/boolean_flag"

RSpec.describe Mcp::BooleanFlag do
  describe ".enabled?" do
    it "returns true for canonical true values" do
      expect(described_class.enabled?("true")).to eq(true)
      expect(described_class.enabled?(" TRUE ")).to eq(true)
    end

    it "returns false for non-true values" do
      expect(described_class.enabled?("false")).to eq(false)
      expect(described_class.enabled?("")).to eq(false)
      expect(described_class.enabled?(nil)).to eq(false)
    end
  end
end
