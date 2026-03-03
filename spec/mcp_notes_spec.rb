# frozen_string_literal: true

require "fileutils"
require "tmpdir"

RSpec.describe "MCP notes read-only endpoints" do
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

  it "lists markdown notes" do
    File.write(File.join(@notes_root, "root.md"), "root")
    FileUtils.mkdir_p(File.join(@notes_root, "nested"))
    File.write(File.join(@notes_root, "nested/child.md"), "child")
    File.write(File.join(@notes_root, "nested/ignore.txt"), "ignore")

    get "/mcp/notes"

    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq(
      {"notes" => ["nested/child.md", "root.md"]}
    )
  end

  it "reads a markdown note by relative path" do
    FileUtils.mkdir_p(File.join(@notes_root, "nested"))
    File.write(File.join(@notes_root, "nested/child.md"), "# Child note")

    get "/mcp/notes/read", path: "nested/child.md"

    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "path" => "nested/child.md",
        "content" => "# Child note"
      }
    )
  end

  it "reads multiple markdown notes in request order" do
    File.write(File.join(@notes_root, "one.md"), "one")
    File.write(File.join(@notes_root, "two.md"), "two")

    post "/mcp/notes/read_batch",
      {paths: ["two.md", "one.md"]}.to_json,
      "CONTENT_TYPE" => "application/json"

    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "notes" => [
          {"path" => "two.md", "content" => "two"},
          {"path" => "one.md", "content" => "one"}
        ]
      }
    )
  end

  it "returns invalid_path for invalid read_batch payload shape" do
    post "/mcp/notes/read_batch", "[]", "CONTENT_TYPE" => "application/json"

    expect(last_response.status).to eq(400)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "error" => {
          "code" => "invalid_path",
          "message" => "paths must be an array"
        }
      }
    )
  end

  it "returns invalid_path for oversized read_batch payload" do
    oversized_paths = (1..(Mcp::NotesBatchReadAction::MAX_BATCH_SIZE + 1)).map { |n| "note-#{n}.md" }
    expected_message = "paths exceeds max batch size of #{Mcp::NotesBatchReadAction::MAX_BATCH_SIZE}"

    post "/mcp/notes/read_batch",
      {paths: oversized_paths}.to_json,
      "CONTENT_TYPE" => "application/json"

    expect(last_response.status).to eq(400)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "error" => {
          "code" => "invalid_path",
          "message" => expected_message
        }
      }
    )
  end

  it "returns invalid_path for unsafe read_batch paths" do
    post "/mcp/notes/read_batch",
      {paths: ["../secret.md"]}.to_json,
      "CONTENT_TYPE" => "application/json"

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

  it "returns 400 for traversal paths" do
    get "/mcp/notes/read", path: "../secret.md"

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

  it "returns 400 for absolute paths" do
    get "/mcp/notes/read", path: "/etc/passwd.md"

    expect(last_response.status).to eq(400)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "error" => {
          "code" => "invalid_path",
          "message" => "absolute paths are not allowed"
        }
      }
    )
  end

  it "returns 400 for non-markdown paths" do
    get "/mcp/notes/read", path: "nested/child.txt"

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

  it "returns 404 for missing markdown notes" do
    get "/mcp/notes/read", path: "missing.md"

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

  it "returns 400 for symlink paths that escape notes root" do
    Dir.mktmpdir("outside-notes-root") do |outside_root|
      outside_file = File.join(outside_root, "secret.md")
      File.write(outside_file, "secret")
      File.symlink(outside_file, File.join(@notes_root, "escaped.md"))

      get "/mcp/notes/read", path: "escaped.md"
    end

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

  it "excludes symlinked markdown files that escape notes root from notes listing" do
    Dir.mktmpdir("outside-notes-root") do |outside_root|
      outside_file = File.join(outside_root, "secret.md")
      File.write(outside_file, "secret")
      File.write(File.join(@notes_root, "inside.md"), "inside")
      File.symlink(outside_file, File.join(@notes_root, "escaped.md"))

      get "/mcp/notes"
    end

    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq(
      {"notes" => ["inside.md"]}
    )
  end

  it "includes symlinked markdown files that resolve inside notes root in notes listing" do
    FileUtils.mkdir_p(File.join(@notes_root, "nested"))
    File.write(File.join(@notes_root, "nested/child.md"), "child")
    File.symlink(
      File.join(@notes_root, "nested/child.md"),
      File.join(@notes_root, "child-link.md")
    )

    get "/mcp/notes"

    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq(
      {"notes" => ["child-link.md", "nested/child.md"]}
    )
  end

  it "allows notes read endpoints in read_only policy mode" do
    App.set :mcp_policy_mode, Mcp::ActionPolicy::MODE_READ_ONLY
    File.write(File.join(@notes_root, "root.md"), "root")

    get "/mcp/notes"

    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq(
      {"notes" => ["root.md"]}
    )
  end

  it "returns invalid_policy_mode for unknown MCP policy mode" do
    App.set :mcp_policy_mode, "read-only"

    get "/mcp/notes"

    expect(last_response.status).to eq(500)
    expect(JSON.parse(last_response.body)).to eq(
      {
        "error" => {
          "code" => "invalid_policy_mode",
          "message" => "invalid MCP policy mode: read-only"
        }
      }
    )
  end
end
