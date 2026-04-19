# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require "open3"
require_relative "../app/services/llm/workflow_patch_client_factory"

RSpec.describe "MCP workflow draft patch endpoint" do
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

  def stub_planner_factory(
    provider:,
    planner_client:,
    local_base_url: nil,
    workflow_model: Llm::OpenAiWorkflowPlannerClient::DEFAULT_MODEL
  )
    planner_factory = instance_double("Llm::WorkflowPlannerClientFactory")
    expect(Llm::WorkflowPlannerClientFactory).to receive(:new).with(
      provider: provider,
      openai_api_key: nil,
      workflow_model: workflow_model,
      openai_base_url: Llm::OpenAiWorkflowPlannerClient::DEFAULT_BASE_URL,
      local_base_url: local_base_url
    ).and_return(planner_factory)
    expect(planner_factory).to receive(:build).and_return(planner_client)
  end

  def expected_dry_run_response(provider:, model:, context:, workflow_action_id: nil)
    trace = {
      "provider" => provider,
      "model" => model,
      "target" => {
        "path" => "notes/today.md",
        "content_bytes" => 6
      },
      "context" => context,
      "validation" => {
        "status" => "valid",
        "path" => "notes/today.md",
        "hunk_count" => 1,
        "net_line_delta" => 1
      },
      "apply_ready" => true,
      "audit" => {
        "patch" => <<~PATCH
          --- a/notes/today.md
          +++ b/notes/today.md
          @@ -1,1 +1,2 @@
          -alpha
          +alpha
          +beta
        PATCH
      }
    }
    trace["workflow_action_id"] = workflow_action_id unless workflow_action_id.nil?

    {
      "edit_intent" => {
        "path" => "notes/today.md",
        "operation" => "replace_content",
        "content" => "alpha\nbeta\n"
      },
      "trace" => trace
    }
  end

  around do |example|
    original_notes_root = App.settings.notes_root
    original_mcp_policy_mode = App.settings.mcp_policy_mode
    original_mcp_workflow_planner_enabled = App.settings.mcp_workflow_planner_enabled
    original_mcp_workflow_planner_provider = App.settings.mcp_workflow_planner_provider
    original_mcp_workflow_drafter_provider = App.settings.mcp_workflow_drafter_provider
    original_mcp_openai_workflow_model = App.settings.mcp_openai_workflow_model
    original_mcp_openai_workflow_configured = App.settings.mcp_openai_workflow_configured
    original_mcp_local_workflow_base_url = App.settings.mcp_local_workflow_base_url
    original_mcp_local_workflow_configured = App.settings.mcp_local_workflow_configured
    original_mcp_workflow_drafter_configured = App.settings.mcp_workflow_drafter_configured

    Dir.mktmpdir("notes-root") do |notes_root|
      App.set :notes_root, notes_root
      App.set :mcp_policy_mode, Mcp::ActionPolicy::MODE_ALLOW_ALL
      App.set :mcp_workflow_planner_enabled, true
      App.set :mcp_workflow_planner_provider, "openai"
      App.set :mcp_workflow_drafter_provider, "openai"
      App.set :mcp_openai_workflow_model, Llm::OpenAiWorkflowPlannerClient::DEFAULT_MODEL
      App.set :mcp_openai_workflow_configured, true
      App.set :mcp_local_workflow_base_url, nil
      App.set :mcp_local_workflow_configured, false
      App.set :mcp_workflow_drafter_configured, true
      example.run
    end
  ensure
    App.set :notes_root, original_notes_root
    App.set :mcp_policy_mode, original_mcp_policy_mode
    App.set :mcp_workflow_planner_enabled, original_mcp_workflow_planner_enabled
    App.set :mcp_workflow_planner_provider, original_mcp_workflow_planner_provider
    App.set :mcp_workflow_drafter_provider, original_mcp_workflow_drafter_provider
    App.set :mcp_openai_workflow_model, original_mcp_openai_workflow_model
    App.set :mcp_openai_workflow_configured, original_mcp_openai_workflow_configured
    App.set :mcp_local_workflow_base_url, original_mcp_local_workflow_base_url
    App.set :mcp_local_workflow_configured, original_mcp_local_workflow_configured
    App.set :mcp_workflow_drafter_configured, original_mcp_workflow_drafter_configured
  end

  it "returns a validated dry-run patch for a valid request" do
    FileUtils.mkdir_p(File.join(App.settings.notes_root, "notes"))
    file_path = File.join(App.settings.notes_root, "notes/today.md")
    File.write(file_path, "alpha\n")
    init_git_repo(App.settings.notes_root)
    git!(App.settings.notes_root, "add", "notes/today.md")
    git!(App.settings.notes_root, "commit", "-m", "Seed note")
    initial_head = git!(App.settings.notes_root, "rev-parse", "HEAD")

    openai_client = instance_double("Llm::OpenAiWorkflowPatchClient")
    stub_draft_factory(
      provider: "openai",
      local_base_url: nil,
      drafter: Llm::WorkflowPatchDrafter.new(enabled: true, provider: "openai", client: openai_client)
    )
    allow(openai_client).to receive(:draft_patch).and_return(
      {
        path: "notes/today.md",
        operation: "replace_content",
        content: "alpha\nbeta\n"
      }
    )

    post "/mcp/workflow/draft_patch", JSON.generate(
      {
        action: "workflow.draft_patch",
        params: {
          instruction: "add beta",
          path: "notes/today.md",
          context: {source: "test"}
        }
      }
    )

    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq(
      expected_dry_run_response(
        provider: "openai",
        model: Llm::OpenAiWorkflowPlannerClient::DEFAULT_MODEL,
        context: {"source" => "test"}
      )
    )
    expect(File.read(file_path)).to eq("alpha\n")
    expect(git!(App.settings.notes_root, "rev-parse", "HEAD")).to eq(initial_head)
  end

  it "accepts a workflow.draft_patch action payload directly from planner output" do
    FileUtils.mkdir_p(File.join(App.settings.notes_root, "notes"))
    file_path = File.join(App.settings.notes_root, "notes/today.md")
    File.write(file_path, "alpha\n")

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
      {
        path: "notes/today.md",
        operation: "replace_content",
        content: "alpha\nbeta\n"
      }
    )

    post "/mcp/workflow/draft_patch", JSON.generate(
      {
        action: "workflow.draft_patch",
        reason: "draft update",
        params: {
          instruction: "add beta",
          path: "notes/today.md",
          context: {source: "planner"},
          workflow_action_id: "workflow-action-2-abc123def456"
        }
      }
    )

    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq(
      expected_dry_run_response(
        provider: "openai",
        model: Llm::OpenAiWorkflowPlannerClient::DEFAULT_MODEL,
        context: {"source" => "planner"},
        workflow_action_id: "workflow-action-2-abc123def456"
      )
    )
  end

  it "accepts a canonical local planner action directly in the draft endpoint" do
    FileUtils.mkdir_p(File.join(App.settings.notes_root, "notes"))
    file_path = File.join(App.settings.notes_root, "notes/today.md")
    File.write(file_path, "alpha\n")
    App.set :mcp_workflow_planner_provider, "local"
    App.set :mcp_workflow_drafter_provider, "local"
    App.set :mcp_openai_workflow_model, "qwen2.5:7b-instruct"
    App.set :mcp_local_workflow_base_url, "http://127.0.0.1:11434"
    App.set :mcp_local_workflow_configured, true
    App.set :mcp_workflow_planner_configured, true
    App.set :mcp_workflow_drafter_configured, true

    local_planner_client = instance_double("Llm::LocalWorkflowPlannerClient")
    stub_planner_factory(
      provider: "local",
      local_base_url: "http://127.0.0.1:11434",
      workflow_model: "qwen2.5:7b-instruct",
      planner_client: local_planner_client
    )
    expect(local_planner_client).to receive(:plan).with(
      intent: "add beta",
      context: hash_including(
        input: {"path" => "notes/today.md"},
        hints: {path: "notes/today.md"},
        note_snapshot: hash_including(path: "notes/today.md", preview: "alpha\n")
      )
    ).and_return(
      {
        "rationale" => "draft with local workflow",
        "actions" => [
          {
            "action" => "workflow.draft_patch",
            "reason" => "draft update",
            "params" => {
              "instruction" => "add beta",
              "path" => "notes/today.md",
              "context" => {"source" => "planner"}
            }
          }
        ]
      }
    )

    local_draft_client = instance_double("Llm::LocalWorkflowPatchClient")
    stub_draft_factory(
      provider: "local",
      local_base_url: "http://127.0.0.1:11434",
      workflow_model: "qwen2.5:7b-instruct",
      drafter: Llm::WorkflowPatchDrafter.new(enabled: true, provider: "local", client: local_draft_client)
    )
    expect(local_draft_client).to receive(:draft_patch).with(
      instruction: "add beta",
      path: "notes/today.md",
      content: "alpha\n",
      context: {"source" => "planner"}
    ).and_return(
      {
        path: "notes/today.md",
        operation: "replace_content",
        content: "alpha\nbeta\n"
      }
    )

    post "/mcp/workflow/plan", JSON.generate(
      {
        intent: "add beta",
        context: {path: "notes/today.md"}
      }
    )

    expect(last_response.status).to eq(200)
    workflow_action = JSON.parse(last_response.body).fetch("actions").find { |action| action.fetch("action") == "workflow.draft_patch" }
    workflow_action_id = workflow_action.fetch("params").fetch("workflow_action_id")
    expect(workflow_action_id).to match(/\Aworkflow-action-1-[0-9a-f]{12}\z/)
    expect(workflow_action).to eq(
      {
        "action" => "workflow.draft_patch",
        "reason" => "draft update",
        "params" => {
          "instruction" => "add beta",
          "path" => "notes/today.md",
          "context" => {"source" => "planner"},
          "workflow_action_id" => workflow_action_id
        }
      }
    )

    post "/mcp/workflow/draft_patch", JSON.generate(workflow_action)

    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq(
      expected_dry_run_response(
        provider: "local",
        model: "qwen2.5:7b-instruct",
        context: {"source" => "planner"},
        workflow_action_id: workflow_action_id
      )
    )
    expect(File.read(file_path)).to eq("alpha\n")
  end

  it "returns invalid_workflow_draft when workflow_action_id is not a string" do
    post "/mcp/workflow/draft_patch", JSON.generate(
      {
        action: "workflow.draft_patch",
        params: {
          instruction: "add beta",
          path: "notes/today.md",
          workflow_action_id: 123
        }
      }
    )

    expect(last_response.status).to eq(400)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "error" => {
          "code" => "invalid_workflow_draft",
          "message" => "workflow_action_id must be a string"
        }
      }
    )
  end

  it "returns a validated dry-run patch for a local provider request" do
    FileUtils.mkdir_p(File.join(App.settings.notes_root, "notes"))
    file_path = File.join(App.settings.notes_root, "notes/today.md")
    File.write(file_path, "alpha\n")
    App.set :mcp_workflow_drafter_provider, "local"
    App.set :mcp_local_workflow_base_url, "http://127.0.0.1:11434"
    App.set :mcp_local_workflow_configured, true
    App.set :mcp_workflow_drafter_configured, true

    local_client = instance_double("Llm::LocalWorkflowPatchClient")
    stub_draft_factory(
      provider: "local",
      local_base_url: "http://127.0.0.1:11434",
      drafter: Llm::WorkflowPatchDrafter.new(enabled: true, provider: "local", client: local_client)
    )
    expect(local_client).to receive(:draft_patch).with(
      instruction: "add beta",
      path: "notes/today.md",
      content: "alpha\n",
      context: {}
    ).and_return(
      {
        path: "notes/today.md",
        operation: "replace_content",
        content: "alpha\nbeta\n"
      }
    )

    post "/mcp/workflow/draft_patch", JSON.generate(
      {
        action: "workflow.draft_patch",
        params: {
          instruction: "add beta",
          path: "notes/today.md"
        }
      }
    )

    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq(
      expected_dry_run_response(
        provider: "local",
        model: Llm::OpenAiWorkflowPlannerClient::DEFAULT_MODEL,
        context: {}
      )
    )
    expect(File.read(file_path)).to eq("alpha\n")
  end

  it "uses an explicit local workflow profile for draft selection" do
    FileUtils.mkdir_p(File.join(App.settings.notes_root, "notes"))
    file_path = File.join(App.settings.notes_root, "notes/today.md")
    File.write(file_path, "alpha\n")

    local_client = instance_double("Llm::LocalWorkflowPatchClient")
    stub_draft_factory(
      provider: "local",
      local_base_url: nil,
      drafter: Llm::WorkflowPatchDrafter.new(enabled: true, provider: "local", client: local_client)
    )
    expect(local_client).to receive(:draft_patch).with(
      instruction: "add beta",
      path: "notes/today.md",
      content: "alpha\n",
      context: {}
    ).and_return(
      {
        path: "notes/today.md",
        operation: "replace_content",
        content: "alpha\nbeta\n"
      }
    )

    post "/mcp/workflow/draft_patch", JSON.generate(
      {
        action: "workflow.draft_patch",
        params: {
          instruction: "add beta",
          path: "notes/today.md",
          profile: "local"
        }
      }
    )

    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq(
      expected_dry_run_response(
        provider: "local",
        model: Llm::OpenAiWorkflowPlannerClient::DEFAULT_MODEL,
        context: {}
      )
    )
  end

  it "uses an explicit hosted workflow profile for draft selection" do
    FileUtils.mkdir_p(File.join(App.settings.notes_root, "notes"))
    file_path = File.join(App.settings.notes_root, "notes/today.md")
    File.write(file_path, "alpha\n")
    App.set :mcp_workflow_drafter_provider, "local"

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
      context: {}
    ).and_return(
      {
        path: "notes/today.md",
        operation: "replace_content",
        content: "alpha\nbeta\n"
      }
    )

    post "/mcp/workflow/draft_patch", JSON.generate(
      {
        action: "workflow.draft_patch",
        params: {
          instruction: "add beta",
          path: "notes/today.md",
          profile: "hosted"
        }
      }
    )

    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq(
      expected_dry_run_response(
        provider: "openai",
        model: Llm::OpenAiWorkflowPlannerClient::DEFAULT_MODEL,
        context: {}
      )
    )
  end

  it "returns invalid_workflow_draft for invalid workflow profiles" do
    post "/mcp/workflow/draft_patch", JSON.generate(
      {
        action: "workflow.draft_patch",
        params: {
          instruction: "add beta",
          path: "notes/today.md",
          profile: "dense"
        }
      }
    )

    expect(last_response.status).to eq(400)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "error" => {
          "code" => "invalid_workflow_draft",
          "message" => "workflow model profile must be hosted, local, or auto"
        }
      }
    )
  end

  it "returns invalid_workflow_draft when edit_intent path does not match requested path" do
    FileUtils.mkdir_p(File.join(App.settings.notes_root, "notes"))
    File.write(File.join(App.settings.notes_root, "notes/today.md"), "alpha\n")

    openai_client = instance_double("Llm::OpenAiWorkflowPatchClient")
    stub_draft_factory(
      provider: "openai",
      local_base_url: nil,
      drafter: Llm::WorkflowPatchDrafter.new(enabled: true, provider: "openai", client: openai_client)
    )
    allow(openai_client).to receive(:draft_patch).and_return(
      {
        path: "notes/other.md",
        operation: "replace_content",
        content: "alpha\nbeta\n"
      }
    )

    post "/mcp/workflow/draft_patch", JSON.generate(
      {
        action: "workflow.draft_patch",
        params: {
          instruction: "add beta",
          path: "notes/today.md"
        }
      }
    )

    expect(last_response.status).to eq(400)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "error" => {
          "code" => "invalid_workflow_draft",
          "message" => "edit_intent path must match requested path"
        }
      }
    )
  end

  it "returns draft_unavailable when provider edit_intent content type is invalid" do
    FileUtils.mkdir_p(File.join(App.settings.notes_root, "notes"))
    File.write(File.join(App.settings.notes_root, "notes/today.md"), "alpha\n")

    openai_client = instance_double("Llm::OpenAiWorkflowPatchClient")
    stub_draft_factory(
      provider: "openai",
      local_base_url: nil,
      drafter: Llm::WorkflowPatchDrafter.new(enabled: true, provider: "openai", client: openai_client)
    )
    allow(openai_client).to receive(:draft_patch).and_return(
      {
        path: "notes/today.md",
        operation: "replace_content",
        content: 123
      }
    )

    post "/mcp/workflow/draft_patch", JSON.generate(
      {
        action: "workflow.draft_patch",
        params: {
          instruction: "add beta",
          path: "notes/today.md"
        }
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

  it "returns draft_unavailable when local drafter response is malformed" do
    FileUtils.mkdir_p(File.join(App.settings.notes_root, "notes"))
    File.write(File.join(App.settings.notes_root, "notes/today.md"), "alpha\n")
    App.set :mcp_workflow_drafter_provider, "local"
    App.set :mcp_local_workflow_base_url, "http://127.0.0.1:11434"
    App.set :mcp_local_workflow_configured, true
    App.set :mcp_workflow_drafter_configured, true

    local_client = instance_double("Llm::LocalWorkflowPatchClient")
    stub_draft_factory(
      provider: "local",
      local_base_url: "http://127.0.0.1:11434",
      drafter: Llm::WorkflowPatchDrafter.new(enabled: true, provider: "local", client: local_client)
    )
    allow(local_client).to receive(:draft_patch).and_raise(
      Llm::LocalWorkflowPatchClient::ResponseError, "bad json"
    )

    post "/mcp/workflow/draft_patch", JSON.generate(
      {
        action: "workflow.draft_patch",
        params: {
          instruction: "add beta",
          path: "notes/today.md"
        }
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

  it "returns draft_unavailable when local drafter is unreachable" do
    FileUtils.mkdir_p(File.join(App.settings.notes_root, "notes"))
    File.write(File.join(App.settings.notes_root, "notes/today.md"), "alpha\n")
    App.set :mcp_workflow_drafter_provider, "local"
    App.set :mcp_local_workflow_base_url, "http://127.0.0.1:11434"
    App.set :mcp_local_workflow_configured, true
    App.set :mcp_workflow_drafter_configured, true

    local_client = instance_double("Llm::LocalWorkflowPatchClient")
    stub_draft_factory(
      provider: "local",
      local_base_url: "http://127.0.0.1:11434",
      drafter: Llm::WorkflowPatchDrafter.new(enabled: true, provider: "local", client: local_client)
    )
    allow(local_client).to receive(:draft_patch).and_raise(
      Llm::LocalWorkflowPatchClient::RequestError, "connection refused"
    )

    post "/mcp/workflow/draft_patch", JSON.generate(
      {
        action: "workflow.draft_patch",
        params: {
          instruction: "add beta",
          path: "notes/today.md"
        }
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

  it "returns invalid_workflow_draft when instruction is missing" do
    post "/mcp/workflow/draft_patch", JSON.generate(
      {
        action: "workflow.draft_patch",
        params: {path: "notes/today.md"}
      }
    )

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
    post "/mcp/workflow/draft_patch", JSON.generate(
      {
        action: "workflow.draft_patch",
        params: {instruction: "add beta"}
      }
    )

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
    stub_draft_factory(
      provider: "openai",
      local_base_url: nil,
      enabled: false,
      drafter: Llm::WorkflowPatchDrafter.new(
        enabled: false,
        provider: "openai",
        client: instance_double("Llm::OpenAiWorkflowPatchClient")
      )
    )
    post "/mcp/workflow/draft_patch", JSON.generate(
      {
        action: "workflow.draft_patch",
        params: {
          instruction: "add beta",
          path: "notes/today.md"
        }
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
    stub_draft_factory(
      provider: "openai",
      local_base_url: nil,
      drafter: Llm::WorkflowPatchDrafter.new(enabled: true, provider: "openai", client: openai_client)
    )
    allow(openai_client).to receive(:draft_patch).and_return(
      {
        path: "notes/today.md",
        operation: "replace_content",
        content: "alpha\nbeta\n"
      }
    )

    post "/mcp/workflow/draft_patch", JSON.generate(
      {
        action: "workflow.draft_patch",
        params: {
          instruction: "add beta",
          path: "notes/today.md"
        }
      }
    )

    expect(last_response.status).to eq(200)
  end

  it "returns invalid_workflow_draft when canonical action envelope is missing" do
    post "/mcp/workflow/draft_patch", JSON.generate(
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

  def init_git_repo(notes_root)
    git!(notes_root, "init")
    git!(notes_root, "config", "user.email", "agent@example.com")
    git!(notes_root, "config", "user.name", "Agent")
  end

  def git!(notes_root, *args)
    stdout, stderr, status = Open3.capture3("git", *args, chdir: notes_root)
    raise "git command failed: git #{args.join(" ")}\n#{stderr}" unless status.success?

    stdout
  end
end
