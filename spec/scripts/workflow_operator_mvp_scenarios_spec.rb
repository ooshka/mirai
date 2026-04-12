# frozen_string_literal: true

require "json"
require "open3"
require "rbconfig"
require "socket"

RSpec.describe "workflow operator MVP scenario pack" do
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

  def draft_response(provider:, model:, path:)
    JSON.generate(
      {
        "edit_intent" => {
          "path" => path,
          "operation" => "replace_content",
          "content" => "alpha\nbeta\n"
        },
        "trace" => {
          "provider" => provider,
          "model" => model,
          "target" => {"path" => path, "content_bytes" => 6},
          "validation" => {
            "status" => "valid",
            "path" => path,
            "hunk_count" => 1,
            "net_line_delta" => 1
          },
          "apply_ready" => true,
          "audit" => {
            "patch" => "--- a/#{path}\n+++ b/#{path}\n@@ -1,1 +1,2 @@\n-alpha\n+alpha\n+beta\n"
          }
        }
      }
    )
  end

  def apply_response(provider:, model:, path:)
    JSON.generate(
      {
        "path" => path,
        "hunk_count" => 1,
        "net_line_delta" => 1,
        "audit" => {
          "patch" => "--- a/#{path}\n+++ b/#{path}\n",
          "provider" => provider,
          "model" => model
        }
      }
    )
  end

  def run_cli(*args)
    script_path = File.expand_path("../../scripts/workflow_operator_mvp_scenarios.rb", __dir__)
    Open3.capture3(RbConfig.ruby, script_path, *args)
  end

  it "runs local and hosted dry-run scenarios through the existing operator CLI" do
    requests = []
    server, thread = start_server do |req|
      requests << {
        path: req.fetch(:path),
        body: JSON.parse(req.fetch(:body))
      }

      payload = requests.last.fetch(:body)
      profile = payload.fetch("params").fetch("profile")
      provider = (profile == "local") ? "local" : "openai"
      model = (profile == "local") ? "qwen3:8b" : "gpt-4.1-mini"
      [200, draft_response(provider: provider, model: model, path: "notes/today.md")]
    end

    base_url = "http://127.0.0.1:#{server.addr[1]}"
    stdout, stderr, status = run_cli("--path", "notes/today.md", "--base-url", base_url)

    expect(status.success?).to eq(true), stderr
    expect(stderr).to eq("")
    expect(requests.map { |request| request[:body].dig("params", "profile") }).to eq(%w[local hosted])
    expect(requests.map { |request| request[:path] }.uniq).to eq(["/mcp/workflow/draft_patch"])
    expect(stdout).to include("Workflow operator MVP scenario pack")
    expect(stdout).to include("== local dry run ==")
    expect(stdout).to include("== hosted dry run ==")
    expect(stdout).to include("Inspect before continuing:")
    expect(stdout).to include("Requested profile: local")
    expect(stdout).to include("Requested profile: hosted")
    expect(stdout).to include("Resolved provider: local")
    expect(stdout).to include("Resolved provider: openai")
  ensure
    stop_server(server, thread) if server
  end

  it "supports an optional explicit apply scenario for a selected profile" do
    requests = []
    server, thread = start_server do |req|
      requests << {
        path: req.fetch(:path),
        body: JSON.parse(req.fetch(:body))
      }

      profile = requests.last.fetch(:body).fetch("params").fetch("profile")
      provider = (profile == "local") ? "local" : "openai"
      model = (profile == "local") ? "qwen3:8b" : "gpt-4.1-mini"

      case req.fetch(:path)
      when "/mcp/workflow/draft_patch"
        [200, draft_response(provider: provider, model: model, path: "notes/today.md")]
      when "/mcp/workflow/apply_patch"
        [200, apply_response(provider: provider, model: model, path: "notes/today.md")]
      else
        raise "unexpected path #{req.fetch(:path)}"
      end
    end

    base_url = "http://127.0.0.1:#{server.addr[1]}"
    stdout, stderr, status = run_cli(
      "--path", "notes/today.md",
      "--base-url", base_url,
      "--include-apply",
      "--apply-profile", "hosted",
      "--yes"
    )

    expect(status.success?).to eq(true), stderr
    expect(stderr).to eq("")
    expect(requests.map { |request| request[:path] }).to eq(
      [
        "/mcp/workflow/draft_patch",
        "/mcp/workflow/draft_patch",
        "/mcp/workflow/draft_patch",
        "/mcp/workflow/apply_patch"
      ]
    )
    expect(requests.map { |request| request[:body].dig("params", "profile") }).to eq(
      %w[local hosted hosted hosted]
    )
    expect(stdout).to include("== hosted explicit apply ==")
    expect(stdout).to include("Apply result")
  ensure
    stop_server(server, thread) if server
  end
end
