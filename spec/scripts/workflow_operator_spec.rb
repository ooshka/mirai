# frozen_string_literal: true

require "json"
require "open3"
require "rbconfig"
require "socket"

RSpec.describe "workflow operator CLI" do
  def start_server(&handler)
    server = TCPServer.new("127.0.0.1", 0)
    thread = Thread.new do
      loop do
        socket = server.accept
        request_line = socket.gets
        break if request_line.nil?

        method, path, = request_line.split
        headers = {}
        while (line = socket.gets)
          line = line.chomp
          break if line.empty?

          key, value = line.split(":", 2)
          headers[key] = value.to_s.strip
        end

        body = socket.read(headers.fetch("Content-Length", "0").to_i)
        status, response_body = handler.call(
          {
            method: method,
            path: path,
            body: body
          }
        )

        socket.write("HTTP/1.1 #{status}\r\n")
        socket.write("Content-Type: application/json\r\n")
        socket.write("Content-Length: #{response_body.bytesize}\r\n")
        socket.write("Connection: close\r\n")
        socket.write("\r\n")
        socket.write(response_body)
        socket.close
      end
    rescue IOError, Errno::EBADF
      nil
    end
    [server, thread]
  end

  def stop_server(server, thread)
    server.close
    thread.join
  rescue IOError, Errno::EBADF
    thread.join
  end

  def run_cli(*args, stdin_data: "")
    script_path = File.expand_path("../../scripts/workflow_operator.rb", __dir__)
    Open3.capture3(RbConfig.ruby, script_path, *args, stdin_data:)
  end

  it "posts the canonical draft payload and prints the dry-run summary" do
    requests = []
    server, thread = start_server do |req|
      requests << {
        path: req.fetch(:path),
        body: JSON.parse(req.fetch(:body))
      }

      [
        200,
        JSON.generate(
          {
            "edit_intent" => {
              "path" => "notes/today.md",
              "operation" => "replace_content",
              "content" => "alpha\nbeta\n"
            },
            "trace" => {
              "provider" => "local",
              "model" => "qwen3:8b",
              "target" => {"path" => "notes/today.md", "content_bytes" => 6},
              "context" => {"source" => "cli"},
              "validation" => {
                "status" => "valid",
                "path" => "notes/today.md",
                "hunk_count" => 1,
                "net_line_delta" => 1
              },
              "workflow_action_id" => "workflow-action-2-abc123def456",
              "apply_ready" => true,
              "audit" => {
                "patch" => "--- a/notes/today.md\n+++ b/notes/today.md\n@@ -1,1 +1,2 @@\n-alpha\n+alpha\n+beta\n"
              }
            }
          }
        )
      ]
    end

    base_url = "http://127.0.0.1:#{server.addr[1]}"
    stdout, stderr, status = run_cli(
      "--instruction", "add beta",
      "--path", "notes/today.md",
      "--profile", "local",
      "--workflow-action-id", "workflow-action-2-abc123def456",
      "--context", '{"source":"cli"}',
      "--base-url", base_url
    )

    expect(status.success?).to eq(true), stderr
    expect(stderr).to eq("")
    expect(requests).to eq(
      [
        {
          path: "/mcp/workflow/draft_patch",
          body: {
            "action" => "workflow.draft_patch",
            "params" => {
              "instruction" => "add beta",
              "path" => "notes/today.md",
              "profile" => "local",
              "workflow_action_id" => "workflow-action-2-abc123def456",
              "context" => {"source" => "cli"}
            }
          }
        }
      ]
    )
    expect(stdout).to include("Dry run")
    expect(stdout).to include("Workflow action: workflow.draft_patch")
    expect(stdout).to include("Workflow action id: workflow-action-2-abc123def456")
    expect(stdout).to include("Requested profile: local")
    expect(stdout).to include("Resolved provider: local")
    expect(stdout).to include("Model: qwen3:8b")
    expect(stdout).to include("Target path: notes/today.md")
    expect(stdout).to include("Apply ready: true")
    expect(stdout).to include("Patch:")
  ensure
    stop_server(server, thread) if server
  end

  it "runs draft then apply when explicitly requested" do
    requests = []
    server, thread = start_server do |req|
      requests << {
        path: req.fetch(:path),
        body: JSON.parse(req.fetch(:body))
      }

      case req.fetch(:path)
      when "/mcp/workflow/draft_patch"
        [
          200,
          JSON.generate(
            {
              "edit_intent" => {
                "path" => "notes/today.md",
                "operation" => "replace_content",
                "content" => "alpha\nbeta\n"
              },
              "trace" => {
                "provider" => "openai",
                "model" => "gpt-4.1-mini",
                "target" => {"path" => "notes/today.md", "content_bytes" => 6},
                "context" => {},
                "validation" => {
                  "status" => "valid",
                  "path" => "notes/today.md",
                  "hunk_count" => 1,
                  "net_line_delta" => 1
                },
                "workflow_action_id" => "workflow-action-2-abc123def456",
                "apply_ready" => true,
                "audit" => {"patch" => "--- a/notes/today.md\n+++ b/notes/today.md\n"}
              }
            }
          )
        ]
      when "/mcp/workflow/apply_patch"
        [
          200,
          JSON.generate(
            {
              "path" => "notes/today.md",
              "hunk_count" => 1,
              "net_line_delta" => 1,
              "action" => "workflow.draft_patch",
              "audit" => {
                "patch" => "--- a/notes/today.md\n+++ b/notes/today.md\n",
                "provider" => "openai",
                "model" => "gpt-4.1-mini",
                "workflow_action_id" => "workflow-action-2-abc123def456"
              }
            }
          )
        ]
      else
        raise "unexpected path #{req.fetch(:path)}"
      end
    end

    base_url = "http://127.0.0.1:#{server.addr[1]}"
    stdout, stderr, status = run_cli(
      "--instruction", "add beta",
      "--path", "notes/today.md",
      "--workflow-action-id", "workflow-action-2-abc123def456",
      "--apply",
      "--yes",
      "--base-url", base_url
    )

    expect(status.success?).to eq(true), stderr
    expect(stderr).to eq("")
    expect(requests.map { |request| request[:path] }).to eq(
      ["/mcp/workflow/draft_patch", "/mcp/workflow/apply_patch"]
    )
    expect(requests.map { |request| request[:body] }.uniq).to eq(
      [
        {
          "action" => "workflow.draft_patch",
          "params" => {
            "instruction" => "add beta",
            "path" => "notes/today.md",
            "workflow_action_id" => "workflow-action-2-abc123def456"
          }
        }
      ]
    )
    expect(stdout).to include("Apply result")
    expect(stdout).to include("Workflow action: workflow.draft_patch")
    expect(stdout).to include("Workflow action id: workflow-action-2-abc123def456")
    expect(stdout).to include("Provider: openai")
    expect(stdout).to include("Model: gpt-4.1-mini")
  ensure
    stop_server(server, thread) if server
  end

  it "surfaces API errors and exits non-zero" do
    server, thread = start_server do |_req|
      [
        400,
        JSON.generate(
          {
            "error" => {
              "code" => "invalid_workflow_draft",
              "message" => "workflow model profile must be hosted, local, or auto"
            }
          }
        )
      ]
    end

    base_url = "http://127.0.0.1:#{server.addr[1]}"
    stdout, stderr, status = run_cli(
      "--instruction", "add beta",
      "--path", "notes/today.md",
      "--profile", "local",
      "--base-url", base_url
    )

    expect(status.success?).to eq(false)
    expect(stdout).to eq("")
    expect(stderr).to include("/mcp/workflow/draft_patch failed: invalid_workflow_draft")
  ensure
    stop_server(server, thread) if server
  end

  it "surfaces unexpected dry-run response shapes and exits non-zero" do
    server, thread = start_server do |_req|
      [
        200,
        JSON.generate(
          {
            "edit_intent" => {
              "path" => "today.md",
              "operation" => "replace_content",
              "content" => "updated"
            }
          }
        )
      ]
    end

    base_url = "http://127.0.0.1:#{server.addr[1]}"
    stdout, stderr, status = run_cli(
      "--instruction", "add beta",
      "--path", "today.md",
      "--profile", "local",
      "--base-url", base_url
    )

    expect(status.success?).to eq(false)
    expect(stdout).to eq("")
    expect(stderr).to include('dry-run response missing "trace"; got keys: edit_intent')
  ensure
    stop_server(server, thread) if server
  end
end
