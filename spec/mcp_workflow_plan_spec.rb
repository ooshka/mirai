# frozen_string_literal: true

RSpec.describe "MCP workflow plan endpoint" do
  around do |example|
    original_notes_root = App.settings.notes_root
    original_mcp_policy_mode = App.settings.mcp_policy_mode
    original_mcp_workflow_planner_enabled = App.settings.mcp_workflow_planner_enabled
    original_mcp_workflow_planner_provider = App.settings.mcp_workflow_planner_provider
    original_mcp_openai_workflow_model = App.settings.mcp_openai_workflow_model
    original_mcp_openai_workflow_configured = App.settings.mcp_openai_workflow_configured

    App.set :notes_root, "/tmp/notes"
    App.set :mcp_policy_mode, Mcp::ActionPolicy::MODE_ALLOW_ALL
    App.set :mcp_workflow_planner_enabled, true
    App.set :mcp_workflow_planner_provider, "openai"
    App.set :mcp_openai_workflow_model, Llm::OpenAiWorkflowPlannerClient::DEFAULT_MODEL
    App.set :mcp_openai_workflow_configured, true
    example.run
  ensure
    App.set :notes_root, original_notes_root
    App.set :mcp_policy_mode, original_mcp_policy_mode
    App.set :mcp_workflow_planner_enabled, original_mcp_workflow_planner_enabled
    App.set :mcp_workflow_planner_provider, original_mcp_workflow_planner_provider
    App.set :mcp_openai_workflow_model, original_mcp_openai_workflow_model
    App.set :mcp_openai_workflow_configured, original_mcp_openai_workflow_configured
  end

  it "returns a structured plan for a valid intent payload" do
    openai_client = instance_double("Llm::OpenAiWorkflowPlannerClient")
    allow(openai_client).to receive(:plan).and_return(
      {
        "rationale" => "read then propose patch",
        "actions" => [
          {"action" => "notes.read", "reason" => "fetch note", "params" => {"path" => "notes/today.md"}},
          {"action" => "patch.propose", "reason" => "draft update", "params" => {"path" => "notes/today.md"}}
        ]
      }
    )
    allow(Llm::OpenAiWorkflowPlannerClient).to receive(:new).and_return(openai_client)

    post "/mcp/workflow/plan", JSON.generate(
      {
        intent: "update today's note",
        context: {scope: "notes/today.md"}
      }
    )

    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "intent" => "update today's note",
        "provider" => "openai",
        "rationale" => "read then propose patch",
        "actions" => [
          {"action" => "notes.read", "reason" => "fetch note", "params" => {"path" => "notes/today.md"}},
          {"action" => "patch.propose", "reason" => "draft update", "params" => {"path" => "notes/today.md"}}
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
    allow(Llm::OpenAiWorkflowPlannerClient).to receive(:new).and_return(openai_client)

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
