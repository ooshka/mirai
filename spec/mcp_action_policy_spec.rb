# frozen_string_literal: true

require_relative "../app/services/mcp/action_policy"

RSpec.describe Mcp::ActionPolicy do
  describe "#enforce!" do
    it "allows all actions in allow_all mode" do
      policy = described_class.new(mode: described_class::MODE_ALLOW_ALL)

      expect { policy.enforce!(described_class::ACTION_PATCH_APPLY) }.not_to raise_error
      expect { policy.enforce!(described_class::ACTION_INDEX_REBUILD) }.not_to raise_error
    end

    it "allows only read actions in read_only mode" do
      policy = described_class.new(mode: described_class::MODE_READ_ONLY)

      expect { policy.enforce!(described_class::ACTION_NOTES_LIST) }.not_to raise_error
      expect { policy.enforce!(described_class::ACTION_NOTES_READ) }.not_to raise_error
      expect { policy.enforce!(described_class::ACTION_INDEX_STATUS) }.not_to raise_error
      expect { policy.enforce!(described_class::ACTION_INDEX_QUERY) }.not_to raise_error
      expect { policy.enforce!(described_class::ACTION_WORKFLOW_PLAN) }.not_to raise_error
    end

    it "denies mutation actions in read_only mode" do
      policy = described_class.new(mode: described_class::MODE_READ_ONLY)

      expect { policy.enforce!(described_class::ACTION_PATCH_PROPOSE) }
        .to raise_error(described_class::DeniedError, "action patch.propose is denied in read_only mode")
      expect { policy.enforce!(described_class::ACTION_PATCH_APPLY) }
        .to raise_error(described_class::DeniedError, "action patch.apply is denied in read_only mode")
      expect { policy.enforce!(described_class::ACTION_INDEX_REBUILD) }
        .to raise_error(described_class::DeniedError, "action index.rebuild is denied in read_only mode")
      expect { policy.enforce!(described_class::ACTION_INDEX_INVALIDATE) }
        .to raise_error(described_class::DeniedError, "action index.invalidate is denied in read_only mode")
    end

    it "preserves allow_all behavior when identity context is provided" do
      policy = described_class.new(mode: described_class::MODE_ALLOW_ALL)
      identity_context = Mcp::IdentityContext.new(actor: "runtime_agent", source: "http_api")

      expect do
        policy.enforce!(
          described_class::ACTION_PATCH_APPLY,
          identity_context: identity_context
        )
      end.not_to raise_error
    end

    it "preserves read_only denial behavior when identity context is provided" do
      policy = described_class.new(mode: described_class::MODE_READ_ONLY)
      identity_context = Mcp::IdentityContext.new(actor: "runtime_agent", source: "http_api")

      expect do
        policy.enforce!(
          described_class::ACTION_PATCH_APPLY,
          identity_context: identity_context
        )
      end.to raise_error(described_class::DeniedError, "action patch.apply is denied in read_only mode")
    end

    it "uses provided identity context before defaults when raising denied error" do
      provided_identity_context = Mcp::IdentityContext.new(actor: "provided", source: "spec")
      default_identity_context = Mcp::IdentityContext.new(actor: "default", source: "spec")
      policy = described_class.new(
        mode: described_class::MODE_READ_ONLY,
        identity_context: default_identity_context
      )

      expect do
        policy.enforce!(
          described_class::ACTION_PATCH_APPLY,
          identity_context: provided_identity_context
        )
      end.to raise_error do |error|
        expect(error).to be_a(described_class::DeniedError)
        expect(error.identity_context).to eq(provided_identity_context)
      end
    end

    it "uses initializer identity context when per-call context is not provided" do
      default_identity_context = Mcp::IdentityContext.new(actor: "default", source: "spec")
      policy = described_class.new(
        mode: described_class::MODE_READ_ONLY,
        identity_context: default_identity_context
      )

      expect do
        policy.enforce!(described_class::ACTION_PATCH_APPLY)
      end.to raise_error do |error|
        expect(error).to be_a(described_class::DeniedError)
        expect(error.identity_context).to eq(default_identity_context)
      end
    end

    it "falls back to runtime agent identity context when no explicit context is configured" do
      policy = described_class.new(mode: described_class::MODE_READ_ONLY)
      runtime_identity_context = Mcp::IdentityContext.new(actor: "runtime_agent", source: "http_api")

      allow(Mcp::IdentityContext).to receive(:runtime_agent).and_return(runtime_identity_context)

      expect do
        policy.enforce!(described_class::ACTION_PATCH_APPLY)
      end.to raise_error do |error|
        expect(error).to be_a(described_class::DeniedError)
        expect(error.identity_context).to eq(runtime_identity_context)
      end
    end
  end

  describe "mode validation" do
    it "returns supported modes" do
      expect(described_class.supported_modes).to eq([
        described_class::MODE_ALLOW_ALL,
        described_class::MODE_READ_ONLY
      ])
    end

    it "normalizes blank values to allow_all" do
      expect(described_class.normalize_mode(nil)).to eq(described_class::MODE_ALLOW_ALL)
      expect(described_class.normalize_mode("  ")).to eq(described_class::MODE_ALLOW_ALL)
    end

    it "raises for unknown modes" do
      expect { described_class.normalize_mode("read-only") }
        .to raise_error(described_class::InvalidModeError, "invalid MCP policy mode: read-only")
    end

    it "raises for unknown modes during initialization" do
      expect { described_class.new(mode: "read-only") }
        .to raise_error(described_class::InvalidModeError, "invalid MCP policy mode: read-only")
    end
  end
end
