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
  end

  describe "mode validation" do
    it "raises for unknown modes" do
      expect { described_class.new(mode: "read-only") }
        .to raise_error(described_class::InvalidModeError, "invalid MCP policy mode: read-only")
    end
  end
end
