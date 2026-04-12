# frozen_string_literal: true

require_relative "../../../app/services/mcp/workflow_execute_action"

RSpec.describe Mcp::WorkflowExecuteAction do
  let(:workflow_draft_apply_action) { instance_double(Mcp::WorkflowDraftApplyAction) }

  it "delegates the canonical workflow.draft_patch action to workflow draft apply" do
    action = described_class.new(workflow_draft_apply_action: workflow_draft_apply_action)

    expect(workflow_draft_apply_action).to receive(:call).with(
      instruction: "add beta",
      path: "notes/today.md",
      context: {"source" => "planner"}
    ).and_return(
      {
        path: "notes/today.md",
        hunk_count: 1,
        net_line_delta: 1,
        audit: {
          patch: "--- a/notes/today.md\n+++ b/notes/today.md\n",
          provider: "openai",
          model: Llm::OpenAiWorkflowPlannerClient::DEFAULT_MODEL
        }
      }
    )

    expect(
      action.call(
        params: {
          "instruction" => "add beta",
          "path" => "notes/today.md",
          "context" => {"source" => "planner"}
        }
      )
    ).to eq(
      {
        path: "notes/today.md",
        hunk_count: 1,
        net_line_delta: 1,
        audit: {
          patch: "--- a/notes/today.md\n+++ b/notes/today.md\n",
          provider: "openai",
          model: Llm::OpenAiWorkflowPlannerClient::DEFAULT_MODEL
        }
      }
    )
  end

  it "requires params to be an object" do
    action = described_class.new(workflow_draft_apply_action: workflow_draft_apply_action)

    expect do
      action.call(params: "bad")
    end.to raise_error(
      described_class::InvalidExecuteRequestError,
      "workflow execute params must be an object"
    )
  end
end
