# frozen_string_literal: true

require_relative "../../../app/services/llm/workflow_patch_drafter"

RSpec.describe Llm::WorkflowPatchDrafter do
  it "supports the local provider with the same normalized edit_intent contract" do
    local_client = instance_double("Llm::LocalWorkflowPatchClient")
    allow(local_client).to receive(:draft_patch).and_return(
      {
        path: "notes/today.md",
        operation: "replace_content",
        content: "alpha\nbeta\n"
      }
    )

    drafter = described_class.new(enabled: true, provider: "local", client: local_client)

    result = drafter.draft_patch(
      instruction: "add beta",
      path: "notes/today.md",
      content: "alpha\n",
      context: {scope: "notes/today.md"}
    )

    expect(result).to eq(
      {
        path: "notes/today.md",
        operation: "replace_content",
        content: "alpha\nbeta\n"
      }
    )
  end

  it "returns a normalized edit_intent when enabled and provider output is valid" do
    openai_client = instance_double("Llm::OpenAiWorkflowPatchClient")
    allow(openai_client).to receive(:draft_patch).and_return(
      {
        path: "notes/today.md",
        operation: "replace_content",
        content: "alpha\nbeta\n"
      }
    )

    drafter = described_class.new(enabled: true, provider: "openai", client: openai_client)
    result = drafter.draft_patch(
      instruction: "add beta",
      path: "notes/today.md",
      content: "alpha\n",
      context: {scope: "notes/today.md"}
    )

    expect(result).to eq(
      {
        path: "notes/today.md",
        operation: "replace_content",
        content: "alpha\nbeta\n"
      }
    )
  end

  it "raises unavailable when disabled" do
    drafter = described_class.new(enabled: false, client: instance_double("Llm::OpenAiWorkflowPatchClient"))

    expect do
      drafter.draft_patch(instruction: "x", path: "notes/today.md", content: "alpha", context: {})
    end.to raise_error(described_class::UnavailableError, "workflow patch drafter is unavailable")
  end

  it "maps malformed provider output to unavailable" do
    openai_client = instance_double("Llm::OpenAiWorkflowPatchClient")
    allow(openai_client).to receive(:draft_patch).and_return({"path" => "notes/today.md"})
    drafter = described_class.new(enabled: true, provider: "openai", client: openai_client)

    expect do
      drafter.draft_patch(instruction: "x", path: "notes/today.md", content: "alpha", context: {})
    end.to raise_error(described_class::UnavailableError, "workflow patch drafter is unavailable")
  end

  it "maps provider request errors to unavailable" do
    openai_client = instance_double("Llm::OpenAiWorkflowPatchClient")
    allow(openai_client).to receive(:draft_patch).and_raise(
      Llm::OpenAiWorkflowPatchClient::RequestError, "timeout"
    )
    drafter = described_class.new(enabled: true, provider: "openai", client: openai_client)

    expect do
      drafter.draft_patch(instruction: "x", path: "notes/today.md", content: "alpha", context: {})
    end.to raise_error(described_class::UnavailableError, "workflow patch drafter is unavailable")
  end

  it "maps local provider response errors to unavailable" do
    local_client = instance_double("Llm::LocalWorkflowPatchClient")
    allow(local_client).to receive(:draft_patch).and_raise(
      Llm::LocalWorkflowPatchClient::ResponseError, "bad json"
    )
    drafter = described_class.new(
      enabled: true,
      provider: "local",
      client: local_client
    )

    expect do
      drafter.draft_patch(instruction: "x", path: "notes/today.md", content: "alpha", context: {})
    end.to raise_error(described_class::UnavailableError, "workflow patch drafter is unavailable")
  end

  it "rejects unsupported provider values" do
    expect do
      described_class.new(enabled: true, provider: "dense")
    end.to raise_error(described_class::InvalidProviderError, "invalid workflow patch drafter provider: dense")
  end
end
