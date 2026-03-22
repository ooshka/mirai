# frozen_string_literal: true

require_relative "../../../app/services/llm/workflow_planner"

RSpec.describe Llm::WorkflowPlanner do
  it "supports the local provider with the same normalized plan contract" do
    local_client = instance_double("Llm::LocalWorkflowPlannerClient")
    allow(local_client).to receive(:plan).and_return(
      {
        "rationale" => "inspect note first",
        "actions" => [
          {"action" => "notes.read", "reason" => "fetch note", "params" => {"path" => "notes/today.md"}}
        ]
      }
    )

    planner = described_class.new(enabled: true, provider: "local", local_client: local_client)

    result = planner.plan(intent: "update today's note", context: {"project" => "mirai"})

    expect(result).to eq(
      {
        intent: "update today's note",
        provider: "local",
        rationale: "inspect note first",
        actions: [
          {action: "notes.read", reason: "fetch note", params: {"path" => "notes/today.md"}}
        ]
      }
    )
  end

  it "returns a normalized plan when enabled and provider output is valid" do
    openai_client = instance_double("Llm::OpenAiWorkflowPlannerClient")
    allow(openai_client).to receive(:plan).and_return(
      {
        "rationale" => "Need to inspect note then propose patch",
        "actions" => [
          {"action" => "notes.read", "reason" => "fetch current note", "params" => {"path" => "notes/today.md"}},
          {
            "action" => "workflow.draft_patch",
            "reason" => "draft note update",
            "params" => {
              "instruction" => "add beta",
              "path" => "notes/today.md",
              "context" => {"source" => "planner"}
            }
          }
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
          {
            action: "workflow.draft_patch",
            reason: "draft note update",
            params: {
              "instruction" => "add beta",
              "path" => "notes/today.md",
              "context" => {"source" => "planner"}
            }
          }
        ]
      }
    )
  end

  it "maps malformed workflow.draft_patch params to unavailable" do
    openai_client = instance_double("Llm::OpenAiWorkflowPlannerClient")
    allow(openai_client).to receive(:plan).and_return(
      {
        "rationale" => "Need to draft patch",
        "actions" => [
          {"action" => "workflow.draft_patch", "reason" => "draft note update", "params" => {"path" => "notes/today.md"}}
        ]
      }
    )
    planner = described_class.new(enabled: true, provider: "openai", openai_client: openai_client)

    expect do
      planner.plan(intent: "update", context: {})
    end.to raise_error(described_class::UnavailableError, "workflow planner is unavailable")
  end

  it "maps legacy draft-like actions to unavailable" do
    openai_client = instance_double("Llm::OpenAiWorkflowPlannerClient")
    allow(openai_client).to receive(:plan).and_return(
      {
        "rationale" => "Need to draft patch",
        "actions" => [
          {"action" => "patch.propose", "reason" => "draft note update", "params" => {"path" => "notes/today.md"}}
        ]
      }
    )
    planner = described_class.new(enabled: true, provider: "openai", openai_client: openai_client)

    expect do
      planner.plan(intent: "update", context: {})
    end.to raise_error(described_class::UnavailableError, "workflow planner is unavailable")
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

  it "maps local provider response errors to unavailable" do
    local_client = instance_double("Llm::LocalWorkflowPlannerClient")
    allow(local_client).to receive(:plan).and_raise(
      Llm::LocalWorkflowPlannerClient::ResponseError, "bad json"
    )
    planner = described_class.new(enabled: true, provider: "local", local_client: local_client)

    expect do
      planner.plan(intent: "update", context: {})
    end.to raise_error(described_class::UnavailableError, "workflow planner is unavailable")
  end

  it "rejects unsupported provider values" do
    expect do
      described_class.new(enabled: true, provider: "dense")
    end.to raise_error(described_class::InvalidProviderError, "invalid workflow planner provider: dense")
  end
end
