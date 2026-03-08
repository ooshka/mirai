# frozen_string_literal: true

require_relative "../../../app/services/llm/workflow_planner"

RSpec.describe Llm::WorkflowPlanner do
  it "returns a normalized plan when enabled and provider output is valid" do
    openai_client = instance_double("Llm::OpenAiWorkflowPlannerClient")
    allow(openai_client).to receive(:plan).and_return(
      {
        "rationale" => "Need to inspect note then propose patch",
        "actions" => [
          {"action" => "notes.read", "reason" => "fetch current note", "params" => {"path" => "notes/today.md"}},
          {"action" => "patch.propose", "reason" => "draft note update", "params" => {"path" => "notes/today.md"}}
        ]
      }
    )

    planner = described_class.new(enabled: true, provider: "openai", openai_client: openai_client)

    result = planner.plan(intent: "update today's note", context: {"project" => "mirai"})

    expect(result).to eq(
      {
        intent: "update today's note",
        provider: "openai",
        rationale: "Need to inspect note then propose patch",
        actions: [
          {action: "notes.read", reason: "fetch current note", params: {"path" => "notes/today.md"}},
          {action: "patch.propose", reason: "draft note update", params: {"path" => "notes/today.md"}}
        ]
      }
    )
  end

  it "raises unavailable when planner is disabled" do
    planner = described_class.new(enabled: false, openai_client: instance_double("Llm::OpenAiWorkflowPlannerClient"))

    expect do
      planner.plan(intent: "update", context: {})
    end.to raise_error(described_class::UnavailableError, "workflow planner is unavailable")
  end

  it "maps malformed provider plans to unavailable" do
    openai_client = instance_double("Llm::OpenAiWorkflowPlannerClient")
    allow(openai_client).to receive(:plan).and_return({"rationale" => "missing actions"})
    planner = described_class.new(enabled: true, provider: "openai", openai_client: openai_client)

    expect do
      planner.plan(intent: "update", context: {})
    end.to raise_error(described_class::UnavailableError, "workflow planner is unavailable")
  end

  it "maps provider request errors to unavailable" do
    openai_client = instance_double("Llm::OpenAiWorkflowPlannerClient")
    allow(openai_client).to receive(:plan).and_raise(
      Llm::OpenAiWorkflowPlannerClient::RequestError, "timeout"
    )
    planner = described_class.new(enabled: true, provider: "openai", openai_client: openai_client)

    expect do
      planner.plan(intent: "update", context: {})
    end.to raise_error(described_class::UnavailableError, "workflow planner is unavailable")
  end
end
