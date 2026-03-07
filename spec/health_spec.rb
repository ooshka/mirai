# frozen_string_literal: true

RSpec.describe "Health" do
  it "returns ok" do
    get "/health"
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq({"ok" => true})
  end

  it "returns config with policy and retrieval diagnostics" do
    get "/config"
    expect(last_response.status).to eq(200)

    body = JSON.parse(last_response.body)

    expect(body.fetch("notes_root")).to be_a(String)
    expect(body.fetch("mcp_policy_mode")).to eq(App.settings.mcp_policy_mode)
    expect(body.fetch("mcp_policy_modes_supported")).to eq(Mcp::ActionPolicy.supported_modes)
    expect(body.fetch("mcp_retrieval_mode")).to eq(App.settings.mcp_retrieval_mode)
    expect(body.fetch("mcp_retrieval_modes_supported")).to eq(Mcp::RetrievalMode.supported_modes)
    expect(body.fetch("mcp_semantic_provider_enabled")).to eq(App.settings.mcp_semantic_provider_enabled)
    expect(body.fetch("mcp_semantic_provider")).to eq(App.settings.mcp_semantic_provider)
    expect(body.fetch("mcp_openai_embedding_model")).to eq(App.settings.mcp_openai_embedding_model)
    expect(body.fetch("mcp_openai_vector_store_id")).to eq(App.settings.mcp_openai_vector_store_id)
    expect(body.fetch("mcp_openai_configured")).to eq(App.settings.mcp_openai_configured)
  end
end
