# frozen_string_literal: true

require "open3"

RSpec.describe "App boot policy mode validation" do
  it "fails fast when MCP_POLICY_MODE is invalid" do
    app_root = File.expand_path("..", __dir__)
    command = [
      "ruby",
      "-e",
      "require File.expand_path('app.rb', Dir.pwd)"
    ]

    stdout, stderr, status = Open3.capture3(
      {"MCP_POLICY_MODE" => "read-only"},
      *command,
      chdir: app_root
    )

    expect(status.success?).to eq(false)
    expect("#{stdout}\n#{stderr}").to include("invalid MCP policy mode: read-only")
  end
end
