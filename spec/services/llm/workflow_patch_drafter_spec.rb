# frozen_string_literal: true

require_relative "../../../app/services/llm/workflow_patch_drafter"

RSpec.describe Llm::WorkflowPatchDrafter do
  it "returns a normalized patch when enabled and provider output is valid" do
    openai_client = instance_double("Llm::OpenAiWorkflowPatchClient")
    allow(openai_client).to receive(:draft_patch).and_return(
      <<~PATCH
        --- a/notes/today.md
        +++ b/notes/today.md
        @@ -1 +1,2 @@
         alpha
        +beta
      PATCH
    )

    drafter = described_class.new(enabled: true, provider: "openai", openai_client: openai_client)
    result = drafter.draft_patch(
      instruction: "add beta",
      path: "notes/today.md",
      content: "alpha\n",
      context: {scope: "notes/today.md"}
    )

    expect(result).to include("--- a/notes/today.md")
  end

  it "raises unavailable when disabled" do
    drafter = described_class.new(enabled: false, openai_client: instance_double("Llm::OpenAiWorkflowPatchClient"))

    expect do
      drafter.draft_patch(instruction: "x", path: "notes/today.md", content: "alpha", context: {})
    end.to raise_error(described_class::UnavailableError, "workflow patch drafter is unavailable")
  end

  it "maps malformed provider output to unavailable" do
    openai_client = instance_double("Llm::OpenAiWorkflowPatchClient")
    allow(openai_client).to receive(:draft_patch).and_return("   ")
    drafter = described_class.new(enabled: true, provider: "openai", openai_client: openai_client)

    expect do
      drafter.draft_patch(instruction: "x", path: "notes/today.md", content: "alpha", context: {})
    end.to raise_error(described_class::UnavailableError, "workflow patch drafter is unavailable")
  end

  it "maps provider request errors to unavailable" do
    openai_client = instance_double("Llm::OpenAiWorkflowPatchClient")
    allow(openai_client).to receive(:draft_patch).and_raise(
      Llm::OpenAiWorkflowPatchClient::RequestError, "timeout"
    )
    drafter = described_class.new(enabled: true, provider: "openai", openai_client: openai_client)

    expect do
      drafter.draft_patch(instruction: "x", path: "notes/today.md", content: "alpha", context: {})
    end.to raise_error(described_class::UnavailableError, "workflow patch drafter is unavailable")
  end
end
