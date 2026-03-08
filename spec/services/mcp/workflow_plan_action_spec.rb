# frozen_string_literal: true

require_relative "../../../app/services/mcp/workflow_plan_action"

RSpec.describe Mcp::WorkflowPlanAction do
  it "validates hints and calls planner with enriched context" do
    planner = instance_double(Llm::WorkflowPlanner)
    context_builder = double("workflow_plan_context_builder")

    action = described_class.new(planner: planner, context_builder: context_builder)

    input_context = {"path" => "notes/today.md", "scope" => "daily"}
    enriched_context = {input: input_context, hints: {path: "notes/today.md"}}

    expect(context_builder).to receive(:build).with(
      input_context: input_context,
      path_hint: "notes/today.md"
    ).and_return(enriched_context)
    expect(planner).to receive(:plan).with(
      intent: "update note",
      context: enriched_context
    ).and_return({intent: "update note", actions: []})

    result = action.call(intent: " update note ", context: input_context)

    expect(result).to eq({intent: "update note", actions: []})
  end

  it "rejects non-object context" do
    action = described_class.new(
      planner: instance_double(Llm::WorkflowPlanner),
      context_builder: double("workflow_plan_context_builder")
    )

    expect do
      action.call(intent: "update", context: "bad")
    end.to raise_error(described_class::InvalidIntentError, "context must be an object")
  end

  it "rejects non-string context path hints" do
    action = described_class.new(
      planner: instance_double(Llm::WorkflowPlanner),
      context_builder: double("workflow_plan_context_builder")
    )

    expect do
      action.call(intent: "update", context: {"path" => 123})
    end.to raise_error(described_class::InvalidIntentError, "context.path must be a string")
  end
end
