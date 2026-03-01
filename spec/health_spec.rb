# frozen_string_literal: true

RSpec.describe "Health" do
  it "returns ok" do
    get "/health"
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq({"ok" => true})
  end

  it "returns config with policy diagnostics" do
    get "/config"
    expect(last_response.status).to eq(200)

    body = JSON.parse(last_response.body)

    expect(body.fetch("notes_root")).to be_a(String)
    expect(body.fetch("mcp_policy_mode")).to eq(App.settings.mcp_policy_mode)
    expect(body.fetch("mcp_policy_modes_supported")).to eq(Mcp::ActionPolicy.supported_modes)
  end
end
