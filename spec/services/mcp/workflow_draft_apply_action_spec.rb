# frozen_string_literal: true

require_relative "../../../app/services/mcp/workflow_draft_apply_action"

RSpec.describe Mcp::WorkflowDraftApplyAction do
  let(:workflow_draft_patch_action) { instance_double(Mcp::WorkflowDraftPatchAction) }
  let(:patch_apply_action) { instance_double(Mcp::PatchApplyAction) }

  it "reuses workflow draft output and nests patch audit alongside apply summary" do
    action = described_class.new(
      workflow_draft_patch_action: workflow_draft_patch_action,
      patch_apply_action: patch_apply_action
    )

    expect(workflow_draft_patch_action).to receive(:call_with_patch).with(
      instruction: "add beta",
      path: "notes/today.md",
      context: {"source" => "planner"}
    ).and_return(
      {
        patch: <<~PATCH.strip,
          --- a/notes/today.md
          +++ b/notes/today.md
          @@ -1 +1,2 @@
           alpha
          +beta
        PATCH
        trace: {
          provider: "openai",
          model: Llm::OpenAiWorkflowPlannerClient::DEFAULT_MODEL
        }
      }
    )
    expect(patch_apply_action).to receive(:call).with(
      patch: <<~PATCH.strip
        --- a/notes/today.md
        +++ b/notes/today.md
        @@ -1 +1,2 @@
         alpha
        +beta
      PATCH
    ).and_return({path: "notes/today.md", hunk_count: 1, net_line_delta: 1})

    expect(
      action.call(
        instruction: "add beta",
        path: "notes/today.md",
        context: {"source" => "planner"}
      )
    ).to eq(
      {
        action: "workflow.draft_patch",
        path: "notes/today.md",
        hunk_count: 1,
        net_line_delta: 1,
        audit: {
          patch: <<~PATCH.strip,
            --- a/notes/today.md
            +++ b/notes/today.md
            @@ -1 +1,2 @@
             alpha
            +beta
          PATCH
          provider: "openai",
          model: Llm::OpenAiWorkflowPlannerClient::DEFAULT_MODEL
        }
      }
    )
  end
end
