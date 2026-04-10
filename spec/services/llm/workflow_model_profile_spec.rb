# frozen_string_literal: true

require_relative "../../../app/services/llm/workflow_model_profile"

RSpec.describe Llm::WorkflowModelProfile do
  it "preserves environment provider defaults when profile is omitted" do
    result = described_class.resolve!(
      profile: nil,
      default_planner_provider: "local",
      default_drafter_provider: "openai"
    )

    expect(result.profile).to be_nil
    expect(result.planner_provider).to eq("local")
    expect(result.drafter_provider).to eq("openai")
  end

  it "maps hosted to openai planner and drafter providers" do
    result = described_class.resolve!(
      profile: "hosted",
      default_planner_provider: "local",
      default_drafter_provider: "local"
    )

    expect(result.profile).to eq("hosted")
    expect(result.planner_provider).to eq("openai")
    expect(result.drafter_provider).to eq("openai")
  end

  it "maps local to local planner and drafter providers" do
    result = described_class.resolve!(
      profile: "local",
      default_planner_provider: "openai",
      default_drafter_provider: "openai"
    )

    expect(result.profile).to eq("local")
    expect(result.planner_provider).to eq("local")
    expect(result.drafter_provider).to eq("local")
  end

  it "resolves auto to the current provider defaults" do
    result = described_class.resolve!(
      profile: "auto",
      default_planner_provider: "local",
      default_drafter_provider: "openai"
    )

    expect(result.profile).to eq("auto")
    expect(result.planner_provider).to eq("local")
    expect(result.drafter_provider).to eq("openai")
  end

  it "rejects invalid profile values" do
    expect do
      described_class.resolve!(
        profile: "dense",
        default_planner_provider: "openai",
        default_drafter_provider: "openai"
      )
    end.to raise_error(
      described_class::InvalidProfileError,
      "workflow model profile must be hosted, local, or auto"
    )
  end

  it "rejects non-string profile values" do
    expect do
      described_class.resolve!(
        profile: 1,
        default_planner_provider: "openai",
        default_drafter_provider: "openai"
      )
    end.to raise_error(
      described_class::InvalidProfileError,
      "workflow model profile must be a string"
    )
  end
end
