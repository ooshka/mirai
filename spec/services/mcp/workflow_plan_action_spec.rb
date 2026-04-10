# frozen_string_literal: true

require_relative "../../../app/services/mcp/workflow_plan_action"

RSpec.describe Mcp::WorkflowPlanAction do
  it "validates hints and calls planner with enriched context" do
    planner = instance_double(Llm::WorkflowPlanner)
    context_builder = double("workflow_plan_context_builder")

    action = described_class.new(planner: planner, context_builder: context_builder)

    input_context = {path: "notes/today.md", scope: "daily", filters: [{kind: "tag", value: "work"}]}
    normalized_context = {
      "path" => "notes/today.md",
      "scope" => "daily",
      "filters" => [{"kind" => "tag", "value" => "work"}]
    }
    enriched_context = {input: normalized_context, hints: {path: "notes/today.md"}}

    expect(context_builder).to receive(:build).with(
      input_context: normalized_context,
      path_hint: "notes/today.md"
    ).and_return(enriched_context)
    expect(planner).to receive(:plan).with(
      intent: "update note",
      context: enriched_context
    ).and_return({intent: "update note", actions: []})

    result = action.call(intent: " update note ", context: input_context)

    expect(result).to eq({intent: "update note", actions: []})
  end

  it "threads an explicit profile into workflow draft handoff actions" do
    planner = instance_double(Llm::WorkflowPlanner)
    context_builder = double("workflow_plan_context_builder")

    action = described_class.new(planner: planner, context_builder: context_builder, profile: "local")

    expect(context_builder).to receive(:build).with(input_context: {}, path_hint: nil).and_return({input: {}})
    expect(planner).to receive(:plan).and_return(
      {
        intent: "update note",
        actions: [
          {action: "notes.read", reason: "read", params: {"path" => "notes/today.md"}},
          {
            action: "workflow.draft_patch",
            reason: "draft",
            params: {
              "instruction" => "add beta",
              "path" => "notes/today.md"
            }
          }
        ]
      }
    )

    expect(action.call(intent: "update note")).to eq(
      {
        intent: "update note",
        actions: [
          {action: "notes.read", reason: "read", params: {"path" => "notes/today.md"}},
          {
            action: "workflow.draft_patch",
            reason: "draft",
            params: {
              "instruction" => "add beta",
              "path" => "notes/today.md",
              "profile" => "local"
            }
          }
        ]
      }
    )
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

  it "rejects context values with unsupported types" do
    action = described_class.new(
      planner: instance_double(Llm::WorkflowPlanner),
      context_builder: double("workflow_plan_context_builder")
    )

    expect do
      action.call(intent: "update", context: {"obj" => Object.new})
    end.to raise_error(described_class::InvalidIntentError, "context contains unsupported value type")
  end

  it "rejects oversized context payloads" do
    action = described_class.new(
      planner: instance_double(Llm::WorkflowPlanner),
      context_builder: double("workflow_plan_context_builder")
    )

    oversized = "a" * (described_class::MAX_CONTEXT_BYTES + 1)

    expect do
      action.call(intent: "update", context: {"blob" => oversized})
    end.to raise_error(described_class::InvalidIntentError, "context is too large")
  end
end
