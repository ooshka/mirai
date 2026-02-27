# frozen_string_literal: true

require "fileutils"
require "tmpdir"

RSpec.describe "MCP patch proposal/apply endpoints" do
  around do |example|
    original_notes_root = App.settings.notes_root

    Dir.mktmpdir("notes-root") do |notes_root|
      @notes_root = notes_root
      App.set :notes_root, notes_root
      example.run
    end
  ensure
    App.set :notes_root, original_notes_root
  end

  it "proposes a valid patch with summary details" do
    patch = <<~PATCH
      --- a/notes/today.md
      +++ b/notes/today.md
      @@ -1 +1,2 @@
       hello
      +world
    PATCH

    post "/mcp/patch/propose", { patch: patch }.to_json, "CONTENT_TYPE" => "application/json"

    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "path" => "notes/today.md",
        "hunk_count" => 1,
        "net_line_delta" => 1
      }
    )
  end

  it "returns invalid_patch for malformed patch" do
    post "/mcp/patch/propose", { patch: "bad patch" }.to_json, "CONTENT_TYPE" => "application/json"

    expect(last_response.status).to eq(400)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "error" => {
          "code" => "invalid_patch",
          "message" => "invalid patch header"
        }
      }
    )
  end

  it "returns invalid_path for traversal patch path" do
    patch = <<~PATCH
      --- a/../secret.md
      +++ b/../secret.md
      @@ -1 +1 @@
      -x
      +y
    PATCH

    post "/mcp/patch/propose", { patch: patch }.to_json, "CONTENT_TYPE" => "application/json"

    expect(last_response.status).to eq(400)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "error" => {
          "code" => "invalid_path",
          "message" => "path escapes notes root"
        }
      }
    )
  end

  it "returns invalid_extension for non-markdown patch path" do
    patch = <<~PATCH
      --- a/notes/today.txt
      +++ b/notes/today.txt
      @@ -1 +1 @@
      -x
      +y
    PATCH

    post "/mcp/patch/propose", { patch: patch }.to_json, "CONTENT_TYPE" => "application/json"

    expect(last_response.status).to eq(400)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "error" => {
          "code" => "invalid_extension",
          "message" => "only .md files are allowed"
        }
      }
    )
  end

  it "applies a valid patch and updates file content" do
    FileUtils.mkdir_p(File.join(@notes_root, "notes"))
    file_path = File.join(@notes_root, "notes/today.md")
    File.write(file_path, "alpha\n")

    patch = <<~PATCH
      --- a/notes/today.md
      +++ b/notes/today.md
      @@ -1 +1,2 @@
       alpha
      +beta
    PATCH

    post "/mcp/patch/apply", { patch: patch }.to_json, "CONTENT_TYPE" => "application/json"

    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "path" => "notes/today.md",
        "hunk_count" => 1,
        "net_line_delta" => 1
      }
    )
    expect(File.read(file_path)).to eq("alpha\nbeta\n")
  end

  it "returns not_found when apply target is missing" do
    patch = <<~PATCH
      --- a/notes/missing.md
      +++ b/notes/missing.md
      @@ -1 +1 @@
      -x
      +y
    PATCH

    post "/mcp/patch/apply", { patch: patch }.to_json, "CONTENT_TYPE" => "application/json"

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

  it "returns conflict when apply context does not match current file" do
    FileUtils.mkdir_p(File.join(@notes_root, "notes"))
    File.write(File.join(@notes_root, "notes/today.md"), "current\n")

    patch = <<~PATCH
      --- a/notes/today.md
      +++ b/notes/today.md
      @@ -1 +1 @@
      -expected
      +updated
    PATCH

    post "/mcp/patch/apply", { patch: patch }.to_json, "CONTENT_TYPE" => "application/json"

    expect(last_response.status).to eq(409)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "error" => {
          "code" => "conflict",
          "message" => "patch does not apply cleanly"
        }
      }
    )
  end
end
