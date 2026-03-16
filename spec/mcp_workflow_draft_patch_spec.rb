# frozen_string_literal: true

require "tmpdir"
require "fileutils"

RSpec.describe "MCP workflow draft patch endpoint" do
  around do |example|
    original_notes_root = App.settings.notes_root
    original_mcp_policy_mode = App.settings.mcp_policy_mode
    original_mcp_workflow_planner_enabled = App.settings.mcp_workflow_planner_enabled
    original_mcp_workflow_planner_provider = App.settings.mcp_workflow_planner_provider
    original_mcp_openai_workflow_model = App.settings.mcp_openai_workflow_model
    original_mcp_openai_workflow_configured = App.settings.mcp_openai_workflow_configured

    Dir.mktmpdir("notes-root") do |notes_root|
      App.set :notes_root, notes_root
      App.set :mcp_policy_mode, Mcp::ActionPolicy::MODE_ALLOW_ALL
      App.set :mcp_workflow_planner_enabled, true
      App.set :mcp_workflow_planner_provider, "openai"
      App.set :mcp_openai_workflow_model, Llm::OpenAiWorkflowPlannerClient::DEFAULT_MODEL
      App.set :mcp_openai_workflow_configured, true
      example.run
    end
  ensure
    App.set :notes_root, original_notes_root
    App.set :mcp_policy_mode, original_mcp_policy_mode
    App.set :mcp_workflow_planner_enabled, original_mcp_workflow_planner_enabled
    App.set :mcp_workflow_planner_provider, original_mcp_workflow_planner_provider
    App.set :mcp_openai_workflow_model, original_mcp_openai_workflow_model
    App.set :mcp_openai_workflow_configured, original_mcp_openai_workflow_configured
  end

  it "returns a validated dry-run patch for a valid request" do
    FileUtils.mkdir_p(File.join(App.settings.notes_root, "notes"))
    file_path = File.join(App.settings.notes_root, "notes/today.md")
    File.write(file_path, "alpha\n")

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
    allow(Llm::OpenAiWorkflowPatchClient).to receive(:new).and_return(openai_client)

    post "/mcp/workflow/draft_patch", JSON.generate(
      {
        instruction: "add beta",
        path: "notes/today.md",
        context: {source: "test"}
      }
    )

    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "patch" => <<~PATCH.strip
          --- a/notes/today.md
          +++ b/notes/today.md
          @@ -1 +1,2 @@
           alpha
          +beta
        PATCH
      }
    )
    expect(File.read(file_path)).to eq("alpha\n")
  end

  it "accepts a workflow.draft_patch action payload directly from planner output" do
    FileUtils.mkdir_p(File.join(App.settings.notes_root, "notes"))
    file_path = File.join(App.settings.notes_root, "notes/today.md")
    File.write(file_path, "alpha\n")

    openai_client = instance_double("Llm::OpenAiWorkflowPatchClient")
    expect(openai_client).to receive(:draft_patch).with(
      instruction: "add beta",
      path: "notes/today.md",
      content: "alpha\n",
      context: {"source" => "planner"}
    ).and_return(
      <<~PATCH
        --- a/notes/today.md
        +++ b/notes/today.md
        @@ -1 +1,2 @@
         alpha
        +beta
      PATCH
    )
    allow(Llm::OpenAiWorkflowPatchClient).to receive(:new).and_return(openai_client)

    post "/mcp/workflow/draft_patch", JSON.generate(
      {
        action: "workflow.draft_patch",
        reason: "draft update",
        params: {
          instruction: "add beta",
          path: "notes/today.md",
          context: {source: "planner"}
        }
      }
    )

    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "patch" => <<~PATCH.strip
          --- a/notes/today.md
          +++ b/notes/today.md
          @@ -1 +1,2 @@
           alpha
          +beta
        PATCH
      }
    )
  end

  it "returns invalid_workflow_draft when instruction is missing" do
    post "/mcp/workflow/draft_patch", JSON.generate({path: "notes/today.md"})

    expect(last_response.status).to eq(400)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "error" => {
          "code" => "invalid_workflow_draft",
          "message" => "instruction is required"
        }
      }
    )
  end

  it "returns invalid_workflow_draft when action payload uses the wrong action name" do
    post "/mcp/workflow/draft_patch", JSON.generate(
      {
        action: "patch.propose",
        params: {instruction: "add beta", path: "notes/today.md"}
      }
    )

    expect(last_response.status).to eq(400)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "error" => {
          "code" => "invalid_workflow_draft",
          "message" => "workflow draft action must be workflow.draft_patch"
        }
      }
    )
  end

  it "returns invalid_workflow_draft when action payload params are not an object" do
    post "/mcp/workflow/draft_patch", JSON.generate(
      {
        action: "workflow.draft_patch",
        params: "bad"
      }
    )

    expect(last_response.status).to eq(400)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "error" => {
          "code" => "invalid_workflow_draft",
          "message" => "workflow draft params must be an object"
        }
      }
    )
  end

  it "returns invalid_workflow_draft when path is missing" do
    post "/mcp/workflow/draft_patch", JSON.generate({instruction: "add beta"})

    expect(last_response.status).to eq(400)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "error" => {
          "code" => "invalid_workflow_draft",
          "message" => "path must be a string"
        }
      }
    )
  end

  it "returns draft_unavailable when drafter is disabled" do
    FileUtils.mkdir_p(File.join(App.settings.notes_root, "notes"))
    File.write(File.join(App.settings.notes_root, "notes/today.md"), "alpha\n")
    App.set :mcp_workflow_planner_enabled, false
    post "/mcp/workflow/draft_patch", JSON.generate(
      {
        instruction: "add beta",
        path: "notes/today.md"
      }
    )

    expect(last_response.status).to eq(503)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "error" => {
          "code" => "draft_unavailable",
          "message" => "workflow patch drafter is unavailable"
        }
      }
    )
  end

  it "allows workflow draft patch in read_only policy mode" do
    FileUtils.mkdir_p(File.join(App.settings.notes_root, "notes"))
    File.write(File.join(App.settings.notes_root, "notes/today.md"), "alpha\n")
    App.set :mcp_policy_mode, Mcp::ActionPolicy::MODE_READ_ONLY

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
    allow(Llm::OpenAiWorkflowPatchClient).to receive(:new).and_return(openai_client)

    post "/mcp/workflow/draft_patch", JSON.generate(
      {
        instruction: "add beta",
        path: "notes/today.md"
      }
    )

    expect(last_response.status).to eq(200)
  end
end
