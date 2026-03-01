# frozen_string_literal: true

require_relative "../app/services/mcp/retrieval_mode"

RSpec.describe Mcp::RetrievalMode do
  describe ".supported_modes" do
    it "returns supported retrieval modes in deterministic order" do
      expect(described_class.supported_modes).to eq([
        described_class::MODE_LEXICAL,
        described_class::MODE_SEMANTIC
      ])
    end
  end

  describe ".normalize_mode!" do
    it "defaults blank mode to lexical" do
      expect(described_class.normalize_mode!(nil)).to eq(described_class::MODE_LEXICAL)
      expect(described_class.normalize_mode!("  ")).to eq(described_class::MODE_LEXICAL)
    end

    it "normalizes semantic mode with surrounding whitespace and case" do
      expect(described_class.normalize_mode!("  SEMANTIC  ")).to eq(described_class::MODE_SEMANTIC)
    end

    it "raises for unsupported modes" do
      expect { described_class.normalize_mode!("dense") }
        .to raise_error(described_class::InvalidModeError, "invalid MCP retrieval mode: dense")
    end
  end
end
