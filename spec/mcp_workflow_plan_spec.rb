# frozen_string_literal: true

require "tmpdir"
require "fileutils"

RSpec.describe "MCP workflow plan endpoint" do
  around do |example|
    original_notes_root = App.settings.notes_root
    original_mcp_policy_mode = App.settings.mcp_policy_mode
    original_mcp_retrieval_mode = App.settings.mcp_retrieval_mode
    original_mcp_semantic_provider_enabled = App.settings.mcp_semantic_provider_enabled
    original_mcp_semantic_provider = App.settings.mcp_semantic_provider
    original_mcp_semantic_configured = App.settings.mcp_semantic_configured
    original_mcp_semantic_ingestion_enabled = App.settings.mcp_semantic_ingestion_enabled
    original_mcp_workflow_planner_enabled = App.settings.mcp_workflow_planner_enabled
    original_mcp_workflow_planner_provider = App.settings.mcp_workflow_planner_provider
    original_mcp_openai_workflow_model = App.settings.mcp_openai_workflow_model
    original_mcp_openai_workflow_configured = App.settings.mcp_openai_workflow_configured
    original_mcp_local_workflow_base_url = App.settings.mcp_local_workflow_base_url
    original_mcp_local_workflow_configured = App.settings.mcp_local_workflow_configured
    original_mcp_workflow_planner_configured = App.settings.mcp_workflow_planner_configured

    Dir.mktmpdir("notes-root") do |notes_root|
      App.set :notes_root, notes_root
      App.set :mcp_policy_mode, Mcp::ActionPolicy::MODE_ALLOW_ALL
      App.set :mcp_retrieval_mode, Mcp::RetrievalMode::MODE_LEXICAL
      App.set :mcp_semantic_provider_enabled, false
      App.set :mcp_semantic_provider, "openai"
      App.set :mcp_semantic_configured, false
      App.set :mcp_semantic_ingestion_enabled, false
      App.set :mcp_workflow_planner_enabled, true
      App.set :mcp_workflow_planner_provider, "openai"
      App.set :mcp_openai_workflow_model, Llm::OpenAiWorkflowPlannerClient::DEFAULT_MODEL
      App.set :mcp_openai_workflow_configured, true
      App.set :mcp_local_workflow_base_url, nil
      App.set :mcp_local_workflow_configured, false
      App.set :mcp_workflow_planner_configured, true
      example.run
    end
  ensure
    App.set :notes_root, original_notes_root
    App.set :mcp_policy_mode, original_mcp_policy_mode
    App.set :mcp_retrieval_mode, original_mcp_retrieval_mode
    App.set :mcp_semantic_provider_enabled, original_mcp_semantic_provider_enabled
    App.set :mcp_semantic_provider, original_mcp_semantic_provider
    App.set :mcp_semantic_configured, original_mcp_semantic_configured
    App.set :mcp_semantic_ingestion_enabled, original_mcp_semantic_ingestion_enabled
    App.set :mcp_workflow_planner_enabled, original_mcp_workflow_planner_enabled
    App.set :mcp_workflow_planner_provider, original_mcp_workflow_planner_provider
    App.set :mcp_openai_workflow_model, original_mcp_openai_workflow_model
    App.set :mcp_openai_workflow_configured, original_mcp_openai_workflow_configured
    App.set :mcp_local_workflow_base_url, original_mcp_local_workflow_base_url
    App.set :mcp_local_workflow_configured, original_mcp_local_workflow_configured
    App.set :mcp_workflow_planner_configured, original_mcp_workflow_planner_configured
  end

  it "returns a structured plan for a valid intent payload" do
    FileUtils.mkdir_p(File.join(App.settings.notes_root, "notes"))
    File.write(File.join(App.settings.notes_root, "notes/today.md"), "alpha\nbeta\n")

    openai_client = instance_double("Llm::OpenAiWorkflowPlannerClient")
    expect(openai_client).to receive(:plan).with(
      intent: "update today's note",
      context: hash_including(
        input: {"scope" => "notes/today.md", "path" => "notes/today.md"},
        hints: {path: "notes/today.md"},
        note_snapshot: hash_including(
          path: "notes/today.md",
          preview: "alpha\nbeta\n",
          preview_truncated: false
        ),
        retrieval_status: hash_including(
          retrieval_mode: Mcp::RetrievalMode::MODE_LEXICAL,
          semantic_provider_enabled: false,
          semantic_provider: "openai",
          semantic_ingestion_enabled: false,
          semantic_configured: false,
          index_status: hash_including(present: false)
        )
      )
    ).and_return(
      {
        "rationale" => "read then propose patch",
        "actions" => [
          {"action" => "notes.read", "reason" => "fetch note", "params" => {"path" => "notes/today.md"}},
          {
            "action" => "workflow.draft_patch",
            "reason" => "draft update",
            "params" => {
              "instruction" => "add beta to today's note",
              "path" => "notes/today.md",
              "context" => {"source" => "planner"}
            }
          }
        ]
      }
    )
    expect(Llm::WorkflowPlannerClientFactory).to receive(:new).with(
      provider: "openai",
      openai_api_key: nil,
      workflow_model: Llm::OpenAiWorkflowPlannerClient::DEFAULT_MODEL,
      openai_base_url: Llm::OpenAiWorkflowPlannerClient::DEFAULT_BASE_URL,
      local_base_url: nil
    ).and_return(instance_double("Llm::WorkflowPlannerClientFactory", build: openai_client))

    post "/mcp/workflow/plan", JSON.generate(
      {
        intent: "update today's note",
        context: {scope: "notes/today.md", path: "notes/today.md"}
      }
    )

    expect(last_response.status).to eq(200)
    body = JSON.parse(last_response.body)
    workflow_action_id = body.fetch("actions").last.fetch("params").fetch("workflow_action_id")
    expect(workflow_action_id).to match(/\Aworkflow-action-2-[0-9a-f]{12}\z/)
    expect(body).to eq(
      {
        "intent" => "update today's note",
        "provider" => "openai",
        "rationale" => "read then propose patch",
        "actions" => [
          {"action" => "notes.read", "reason" => "fetch note", "params" => {"path" => "notes/today.md"}},
          {
            "action" => "workflow.draft_patch",
            "reason" => "draft update",
            "params" => {
              "instruction" => "add beta to today's note",
              "path" => "notes/today.md",
              "context" => {"source" => "planner"},
              "workflow_action_id" => workflow_action_id
            }
          }
        ]
      }
    )
  end

  it "returns canonical draft actions when the planner emits a smaller semantic draft intent" do
    openai_client = instance_double("Llm::OpenAiWorkflowPlannerClient")
    allow(openai_client).to receive(:plan).and_return(
      {
        "rationale" => "draft update",
        "actions" => [
          {
            "action" => "draft_note",
            "reason" => "draft update",
            "params" => {
              "intent" => "add beta to today's note",
              "path" => "notes/today.md",
              "context" => {"source" => "planner"}
            }
          }
        ]
      }
    )
    allow(Llm::WorkflowPlannerClientFactory).to receive(:new).and_return(
      instance_double("Llm::WorkflowPlannerClientFactory", build: openai_client)
    )

    post "/mcp/workflow/plan", JSON.generate({intent: "update today's note"})

    expect(last_response.status).to eq(200)
    body = JSON.parse(last_response.body)
    workflow_action_id = body.fetch("actions").first.fetch("params").fetch("workflow_action_id")
    expect(workflow_action_id).to match(/\Aworkflow-action-1-[0-9a-f]{12}\z/)
    expect(body).to eq(
      {
        "intent" => "update today's note",
        "provider" => "openai",
        "rationale" => "draft update",
        "actions" => [
          {
            "action" => "workflow.draft_patch",
            "reason" => "draft update",
            "params" => {
              "instruction" => "add beta to today's note",
              "path" => "notes/today.md",
              "context" => {"source" => "planner"},
              "workflow_action_id" => workflow_action_id
            }
          }
        ]
      }
    )
  end

  it "returns invalid_workflow_intent when intent is missing" do
    post "/mcp/workflow/plan", JSON.generate({context: {scope: "notes/today.md"}})

    expect(last_response.status).to eq(400)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "error" => {
          "code" => "invalid_workflow_intent",
          "message" => "intent is required"
        }
      }
    )
  end

  it "returns invalid_workflow_intent when context is not an object" do
    post "/mcp/workflow/plan", JSON.generate({intent: "update", context: "bad"})

    expect(last_response.status).to eq(400)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "error" => {
          "code" => "invalid_workflow_intent",
          "message" => "context must be an object"
        }
      }
    )
  end

  it "returns invalid_workflow_intent when context path hint is not a string" do
    post "/mcp/workflow/plan", JSON.generate({intent: "update", context: {path: 1}})

    expect(last_response.status).to eq(400)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "error" => {
          "code" => "invalid_workflow_intent",
          "message" => "context.path must be a string"
        }
      }
    )
  end

  it "returns invalid_workflow_intent when context payload is too large" do
    oversized = "a" * (Mcp::WorkflowPlanAction::MAX_CONTEXT_BYTES + 1)
    post "/mcp/workflow/plan", JSON.generate({intent: "update", context: {blob: oversized}})

    expect(last_response.status).to eq(400)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "error" => {
          "code" => "invalid_workflow_intent",
          "message" => "context is too large"
        }
      }
    )
  end

  it "returns planner_unavailable when provider returns a legacy draft-like action" do
    openai_client = instance_double("Llm::OpenAiWorkflowPlannerClient")
    allow(openai_client).to receive(:plan).and_return(
      {
        "rationale" => "draft update",
        "actions" => [
          {"action" => "patch.propose", "reason" => "draft update", "params" => {"path" => "notes/today.md"}}
        ]
      }
    )
    allow(Llm::WorkflowPlannerClientFactory).to receive(:new).and_return(
      instance_double("Llm::WorkflowPlannerClientFactory", build: openai_client)
    )

    post "/mcp/workflow/plan", JSON.generate({intent: "update today's note"})

    expect(last_response.status).to eq(503)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "error" => {
          "code" => "planner_unavailable",
          "message" => "workflow planner is unavailable"
        }
      }
    )
  end

  it "returns a structured plan through the local planner provider" do
    App.set :mcp_workflow_planner_provider, "local"
    App.set :mcp_openai_workflow_model, "qwen2.5:7b-instruct"
    App.set :mcp_local_workflow_base_url, "http://127.0.0.1:11434"
    App.set :mcp_local_workflow_configured, true
    App.set :mcp_workflow_planner_configured, true

    local_client = instance_double("Llm::LocalWorkflowPlannerClient")
    expect(local_client).to receive(:plan).with(
      intent: "plan local workflow",
      context: hash_including(
        input: {},
        retrieval_status: hash_including(
          retrieval_mode: Mcp::RetrievalMode::MODE_LEXICAL
        )
      )
    ).and_return(
      {
        "rationale" => "use local planner",
        "actions" => [
          {
            "action" => "workflow.draft_patch",
            "reason" => "draft update",
            "params" => {
              "instruction" => "add beta",
              "path" => "notes/today.md"
            }
          }
        ]
      }
    )
    expect(Llm::WorkflowPlannerClientFactory).to receive(:new).with(
      provider: "local",
      openai_api_key: nil,
      workflow_model: "qwen2.5:7b-instruct",
      openai_base_url: Llm::OpenAiWorkflowPlannerClient::DEFAULT_BASE_URL,
      local_base_url: "http://127.0.0.1:11434"
    ).and_return(instance_double("Llm::WorkflowPlannerClientFactory", build: local_client))

    post "/mcp/workflow/plan", JSON.generate({intent: "plan local workflow"})

    expect(last_response.status).to eq(200)
    body = JSON.parse(last_response.body)
    workflow_action_id = body.fetch("actions").first.fetch("params").fetch("workflow_action_id")
    expect(workflow_action_id).to match(/\Aworkflow-action-1-[0-9a-f]{12}\z/)
    expect(body).to eq(
      {
        "intent" => "plan local workflow",
        "provider" => "local",
        "rationale" => "use local planner",
        "actions" => [
          {
            "action" => "workflow.draft_patch",
            "reason" => "draft update",
            "params" => {
              "instruction" => "add beta",
              "path" => "notes/today.md",
              "workflow_action_id" => workflow_action_id
            }
          }
        ]
      }
    )
  end

  it "uses an explicit local workflow profile for planner selection" do
    local_client = instance_double("Llm::LocalWorkflowPlannerClient")
    expect(local_client).to receive(:plan).with(
      intent: "plan local workflow",
      context: hash_including(input: {}, retrieval_status: hash_including(retrieval_mode: Mcp::RetrievalMode::MODE_LEXICAL))
    ).and_return(
      {
        "rationale" => "use local planner",
        "actions" => [
          {
            "action" => "workflow.draft_patch",
            "reason" => "draft update",
            "params" => {
              "instruction" => "add beta",
              "path" => "notes/today.md"
            }
          }
        ]
      }
    )
    expect(Llm::WorkflowPlannerClientFactory).to receive(:new).with(
      provider: "local",
      openai_api_key: nil,
      workflow_model: Llm::OpenAiWorkflowPlannerClient::DEFAULT_MODEL,
      openai_base_url: Llm::OpenAiWorkflowPlannerClient::DEFAULT_BASE_URL,
      local_base_url: nil
    ).and_return(instance_double("Llm::WorkflowPlannerClientFactory", build: local_client))

    post "/mcp/workflow/plan", JSON.generate({intent: "plan local workflow", profile: "local"})

    expect(last_response.status).to eq(200)
    body = JSON.parse(last_response.body)
    workflow_action_id = body.fetch("actions").first.fetch("params").fetch("workflow_action_id")
    expect(workflow_action_id).to match(/\Aworkflow-action-1-[0-9a-f]{12}\z/)
    expect(body).to eq(
      {
        "intent" => "plan local workflow",
        "provider" => "local",
        "rationale" => "use local planner",
        "actions" => [
          {
            "action" => "workflow.draft_patch",
            "reason" => "draft update",
            "params" => {
              "instruction" => "add beta",
              "path" => "notes/today.md",
              "profile" => "local",
              "workflow_action_id" => workflow_action_id
            }
          }
        ]
      }
    )
  end

  it "returns invalid_workflow_intent for invalid workflow profiles" do
    post "/mcp/workflow/plan", JSON.generate({intent: "plan workflow", profile: "dense"})

    expect(last_response.status).to eq(400)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "error" => {
          "code" => "invalid_workflow_intent",
          "message" => "workflow model profile must be hosted, local, or auto"
        }
      }
    )
  end

  it "returns planner_unavailable when the local planner provider is unreachable" do
    App.set :mcp_workflow_planner_provider, "local"
    App.set :mcp_local_workflow_base_url, "http://127.0.0.1:11434"
    App.set :mcp_local_workflow_configured, true
    App.set :mcp_workflow_planner_configured, true

    local_client = instance_double("Llm::LocalWorkflowPlannerClient")
    allow(local_client).to receive(:plan).and_raise(
      Llm::LocalWorkflowPlannerClient::RequestError, "connection refused"
    )
    allow(Llm::WorkflowPlannerClientFactory).to receive(:new).and_return(
      instance_double("Llm::WorkflowPlannerClientFactory", build: local_client)
    )

    post "/mcp/workflow/plan", JSON.generate({intent: "plan local workflow"})

    expect(last_response.status).to eq(503)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "error" => {
          "code" => "planner_unavailable",
          "message" => "workflow planner is unavailable"
        }
      }
    )
  end

  it "returns not_found when hinted note path does not exist" do
    post "/mcp/workflow/plan", JSON.generate({intent: "update", context: {path: "notes/missing.md"}})

    expect(last_response.status).to eq(404)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "error" => {
          "code" => "not_found",
          "message" => "note was not found"
        }
      }
    )
  end

  it "returns planner_unavailable when planner is disabled" do
    App.set :mcp_workflow_planner_enabled, false

    post "/mcp/workflow/plan", JSON.generate({intent: "update"})

    expect(last_response.status).to eq(503)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "error" => {
          "code" => "planner_unavailable",
          "message" => "workflow planner is unavailable"
        }
      }
    )
  end

  it "allows workflow planning in read_only policy mode" do
    App.set :mcp_policy_mode, Mcp::ActionPolicy::MODE_READ_ONLY
    openai_client = instance_double("Llm::OpenAiWorkflowPlannerClient")
    allow(openai_client).to receive(:plan).and_return({"rationale" => "read note", "actions" => []})
    allow(Llm::WorkflowPlannerClientFactory).to receive(:new).and_return(
      instance_double("Llm::WorkflowPlannerClientFactory", build: openai_client)
    )

    post "/mcp/workflow/plan", JSON.generate({intent: "plan read workflow"})

    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "intent" => "plan read workflow",
        "provider" => "openai",
        "rationale" => "read note",
        "actions" => []
      }
    )
  end
end
