# frozen_string_literal: true

require "fileutils"
require "tmpdir"

RSpec.describe "MCP policy identity context plumbing" do
  around do |example|
    original_notes_root = App.settings.notes_root
    original_mcp_policy_mode = App.settings.mcp_policy_mode

    Dir.mktmpdir("notes-root") do |notes_root|
      @notes_root = notes_root
      App.set :notes_root, notes_root
      App.set :mcp_policy_mode, Mcp::ActionPolicy::MODE_ALLOW_ALL
      example.run
    end
  ensure
    App.set :notes_root, original_notes_root
    App.set :mcp_policy_mode, original_mcp_policy_mode
  end

  it "passes identity context through helper policy enforcement for allowed actions" do
    File.write(File.join(@notes_root, "root.md"), "root")

    expect_any_instance_of(Mcp::ActionPolicy).to receive(:enforce!)
      .with(
        Mcp::ActionPolicy::ACTION_NOTES_LIST,
        identity_context: instance_of(Mcp::IdentityContext)
      )
      .and_call_original

    get "/mcp/notes"

    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq({"notes" => ["root.md"]})
  end

  it "passes identity context through helper policy enforcement for denied actions" do
    App.set :mcp_policy_mode, Mcp::ActionPolicy::MODE_READ_ONLY
    patch = <<~PATCH
      --- a/notes/today.md
      +++ b/notes/today.md
      @@ -1 +1,2 @@
       hello
      +world
    PATCH

    expect_any_instance_of(Mcp::ActionPolicy).to receive(:enforce!)
      .with(
        Mcp::ActionPolicy::ACTION_PATCH_PROPOSE,
        identity_context: instance_of(Mcp::IdentityContext)
      )
      .and_call_original

    post "/mcp/patch/propose", {patch: patch}.to_json, "CONTENT_TYPE" => "application/json"

    expect(last_response.status).to eq(403)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "error" => {
          "code" => "policy_denied",
          "message" => "action patch.propose is denied in read_only mode"
        }
      }
    )
  end
end
