# frozen_string_literal: true

require_relative "../../../app/services/mcp/workflow_edit_intent_patch_builder"

RSpec.describe Mcp::WorkflowEditIntentPatchBuilder do
  it "builds a single-file unified diff from replace_content edit_intent" do
    builder = described_class.new

    result = builder.call(
      edit_intent: {
        path: "notes/today.md",
        operation: "replace_content",
        content: "alpha\nbeta\n"
      },
      current_content: "alpha\n"
    )

    expect(result).to eq(
      <<~PATCH
        --- a/notes/today.md
        +++ b/notes/today.md
        @@ -1,1 +1,2 @@
        -alpha
        +alpha
        +beta
      PATCH
    )
  end

  it "rejects no-op edit intents" do
    builder = described_class.new

    expect do
      builder.call(
        edit_intent: {
          path: "notes/today.md",
          operation: "replace_content",
          content: "alpha\n"
        },
        current_content: "alpha\n"
      )
    end.to raise_error(described_class::InvalidEditIntentError, "edit_intent must change note content")
  end
end
