# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require "open3"
require_relative "../app/services/llm/workflow_patch_client_factory"

RSpec.describe "MCP workflow apply patch endpoint" do
  def stub_draft_factory(
    provider:,
    drafter:,
    local_base_url: nil,
    enabled: true,
    workflow_model: Llm::OpenAiWorkflowPlannerClient::DEFAULT_MODEL
  )
    draft_factory = instance_double("Llm::WorkflowPatchClientFactory")
    expect(Llm::WorkflowPatchClientFactory).to receive(:new).with(
      provider: provider,
      openai_api_key: nil,
      workflow_model: workflow_model,
      openai_base_url: Llm::OpenAiWorkflowPatchClient::DEFAULT_BASE_URL,
      local_base_url: local_base_url
    ).and_return(draft_factory)
    expect(draft_factory).to receive(:build_drafter).with(enabled: enabled).and_return(drafter)
  end

  around do |example|
    original_notes_root = App.settings.notes_root
    original_mcp_policy_mode = App.settings.mcp_policy_mode
    original_mcp_workflow_planner_enabled = App.settings.mcp_workflow_planner_enabled
    original_mcp_workflow_drafter_provider = App.settings.mcp_workflow_drafter_provider
    original_mcp_openai_workflow_model = App.settings.mcp_openai_workflow_model
    original_semantic_ingestion_service = App.settings.semantic_ingestion_service

    Dir.mktmpdir("notes-root") do |notes_root|
      @notes_root = notes_root
      init_git_repo
      App.set :notes_root, notes_root
      App.set :mcp_policy_mode, Mcp::ActionPolicy::MODE_ALLOW_ALL
      App.set :mcp_workflow_planner_enabled, true
      App.set :mcp_workflow_drafter_provider, "openai"
      App.set :mcp_openai_workflow_model, Llm::OpenAiWorkflowPlannerClient::DEFAULT_MODEL
      App.set :semantic_ingestion_service, NullSemanticIngestionService.new
      example.run
    end
  ensure
    App.set :notes_root, original_notes_root
    App.set :mcp_policy_mode, original_mcp_policy_mode
    App.set :mcp_workflow_planner_enabled, original_mcp_workflow_planner_enabled
    App.set :mcp_workflow_drafter_provider, original_mcp_workflow_drafter_provider
    App.set :mcp_openai_workflow_model, original_mcp_openai_workflow_model
    App.set :semantic_ingestion_service, original_semantic_ingestion_service
  end

  it "drafts and applies a canonical workflow action payload" do
    FileUtils.mkdir_p(File.join(@notes_root, "notes"))
    file_path = File.join(@notes_root, "notes/today.md")
    File.write(file_path, "alpha\n")
    git!("add", "notes/today.md")
    git!("commit", "-m", "Seed note")

    openai_client = instance_double("Llm::OpenAiWorkflowPatchClient")
    stub_draft_factory(
      provider: "openai",
      local_base_url: nil,
      drafter: Llm::WorkflowPatchDrafter.new(enabled: true, provider: "openai", client: openai_client)
    )
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

    post "/mcp/workflow/apply_patch", JSON.generate(
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
        "path" => "notes/today.md",
        "hunk_count" => 1,
        "net_line_delta" => 1,
        "patch" => <<~PATCH.strip
          --- a/notes/today.md
          +++ b/notes/today.md
          @@ -1 +1,2 @@
           alpha
          +beta
        PATCH
      }
    )
    expect(File.read(file_path)).to eq("alpha\nbeta\n")
    expect(git!("log", "--format=%s", "-n", "1", "--", "notes/today.md").strip)
      .to eq("mcp.patch_apply: notes/today.md")
  end

  it "returns invalid_workflow_draft when the canonical action envelope is missing" do
    post "/mcp/workflow/apply_patch", JSON.generate(
      {
        instruction: "add beta",
        path: "notes/today.md"
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

  it "returns policy_denied for workflow apply in read_only policy mode" do
    App.set :mcp_policy_mode, Mcp::ActionPolicy::MODE_READ_ONLY

    post "/mcp/workflow/apply_patch", JSON.generate(
      {
        action: "workflow.draft_patch",
        params: {
          instruction: "add beta",
          path: "notes/today.md"
        }
      }
    )

    expect(last_response.status).to eq(403)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "error" => {
          "code" => "policy_denied",
          "message" => "action patch.apply is denied in read_only mode"
        }
      }
    )
  end

  def init_git_repo
    git!("init")
    git!("config", "user.email", "agent@example.com")
    git!("config", "user.name", "Agent")
  end

  def git!(*args)
    stdout, stderr, status = Open3.capture3("git", *args, chdir: @notes_root)
    raise "git command failed: git #{args.join(" ")}\n#{stderr}" unless status.success?

    stdout
  end
end
