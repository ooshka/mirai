# frozen_string_literal: true

require "fileutils"
require "json"
require "open3"
require "rbconfig"
require "socket"
require "stringio"
require "tmpdir"
require "uri"
require_relative "../spec_helper"
require_relative "../../app/services/llm/workflow_patch_client_factory"

SmokeWorkflowPatchClient = Struct.new(:updated_content) do
  def draft_patch(instruction:, path:, content:, context:)
    {
      path: path,
      operation: "replace_content",
      content: updated_content
    }
  end
end

SmokeWorkflowPatchFactory = Struct.new(:drafter) do
  def build_drafter(enabled:)
    drafter
  end
end

RSpec.describe "workflow operator real-notes smoke" do
  def start_rack_server
    server = TCPServer.new("127.0.0.1", 0)
    port = server.addr[1]
    thread = Thread.new do
      loop do
        socket = server.accept
        handle_rack_request(socket, port: port)
      end
    rescue IOError, Errno::EBADF
      nil
    end
    [server, thread]
  end

  def handle_rack_request(socket, port:)
    request_line = socket.gets
    return if request_line.nil?

    method, raw_path, = request_line.split
    headers = read_headers(socket)
    body = socket.read(headers.fetch("Content-Length", "0").to_i)
    uri = URI.parse(raw_path)

    status, response_headers, response_body = App.call(
      {
        "REQUEST_METHOD" => method,
        "SCRIPT_NAME" => "",
        "PATH_INFO" => uri.path,
        "QUERY_STRING" => uri.query.to_s,
        "SERVER_NAME" => "127.0.0.1",
        "SERVER_PORT" => port.to_s,
        "HTTP_HOST" => "127.0.0.1:#{port}",
        "rack.input" => StringIO.new(body),
        "rack.errors" => $stderr,
        "rack.url_scheme" => "http",
        "rack.version" => [1, 3],
        "rack.multithread" => true,
        "rack.multiprocess" => false,
        "rack.run_once" => false,
        "CONTENT_LENGTH" => body.bytesize.to_s,
        "CONTENT_TYPE" => headers["Content-Type"]
      }
    )

    response_text = +""
    response_body.each { |chunk| response_text << chunk }
    response_body.close if response_body.respond_to?(:close)

    socket.write("HTTP/1.1 #{status}\r\n")
    response_headers.each { |key, value| socket.write("#{key}: #{value}\r\n") }
    socket.write("Content-Length: #{response_text.bytesize}\r\n")
    socket.write("Connection: close\r\n")
    socket.write("\r\n")
    socket.write(response_text)
  ensure
    socket.close
  end

  def read_headers(socket)
    headers = {}
    while (line = socket.gets)
      line = line.chomp
      break if line.empty?

      key, value = line.split(":", 2)
      headers[key] = value.to_s.strip
    end
    headers
  end

  def stop_server(server, thread)
    server.close
    thread.join
  rescue IOError, Errno::EBADF
    thread.join
  end

  def run_cli(*args)
    script_path = File.expand_path("../../scripts/workflow_operator.rb", __dir__)
    Open3.capture3(RbConfig.ruby, script_path, *args)
  end

  around do |example|
    original_notes_root = App.settings.notes_root
    original_mcp_policy_mode = App.settings.mcp_policy_mode
    original_mcp_workflow_planner_enabled = App.settings.mcp_workflow_planner_enabled
    original_mcp_workflow_drafter_provider = App.settings.mcp_workflow_drafter_provider
    original_mcp_openai_workflow_model = App.settings.mcp_openai_workflow_model
    original_mcp_local_workflow_base_url = App.settings.mcp_local_workflow_base_url
    original_semantic_ingestion_service = App.settings.semantic_ingestion_service

    Dir.mktmpdir("notes-root") do |notes_root|
      @notes_root = notes_root
      init_git_repo
      App.set :notes_root, notes_root
      App.set :mcp_policy_mode, Mcp::ActionPolicy::MODE_ALLOW_ALL
      App.set :mcp_workflow_planner_enabled, true
      App.set :mcp_workflow_drafter_provider, "openai"
      App.set :mcp_openai_workflow_model, Llm::OpenAiWorkflowPlannerClient::DEFAULT_MODEL
      App.set :mcp_local_workflow_base_url, nil
      App.set :semantic_ingestion_service, NullSemanticIngestionService.new
      example.run
    end
  ensure
    App.set :notes_root, original_notes_root
    App.set :mcp_policy_mode, original_mcp_policy_mode
    App.set :mcp_workflow_planner_enabled, original_mcp_workflow_planner_enabled
    App.set :mcp_workflow_drafter_provider, original_mcp_workflow_drafter_provider
    App.set :mcp_openai_workflow_model, original_mcp_openai_workflow_model
    App.set :mcp_local_workflow_base_url, original_mcp_local_workflow_base_url
    App.set :semantic_ingestion_service, original_semantic_ingestion_service
  end

  it "runs dry-run and apply against a temporary git-backed notes root" do
    FileUtils.mkdir_p(File.join(@notes_root, "notes"))
    note_path = File.join(@notes_root, "notes/today.md")
    File.write(note_path, "alpha\n")
    git!("add", "notes/today.md")
    git!("commit", "-m", "Seed note")

    updated_content = "alpha\nbeta\n"
    fake_client = SmokeWorkflowPatchClient.new(updated_content)
    fake_factory = SmokeWorkflowPatchFactory.new(
      Llm::WorkflowPatchDrafter.new(enabled: true, provider: "openai", client: fake_client)
    )
    allow(Llm::WorkflowPatchClientFactory).to receive(:new).and_return(fake_factory)

    server, thread = start_rack_server
    stdout, stderr, status = run_cli(
      "--instruction", "add beta",
      "--path", "notes/today.md",
      "--workflow-action-id", "workflow-action-smoke-123",
      "--apply",
      "--yes",
      "--base-url", "http://127.0.0.1:#{server.addr[1]}"
    )

    expect(status.success?).to eq(true), stderr
    expect(stdout).to include("Dry run")
    expect(stdout).to include("Apply result")
    expect(stdout).to include("Workflow action id: workflow-action-smoke-123")
    expect(File.read(note_path)).to eq(updated_content)
    expect(git!("log", "--format=%s", "-n", "1", "--", "notes/today.md").strip)
      .to eq("mcp.patch_apply: notes/today.md")
  ensure
    stop_server(server, thread) if server
  end

  def init_git_repo
    git!("init")
    git!("config", "user.email", "test@example.com")
    git!("config", "user.name", "Test User")
  end

  def git!(*args)
    output, status = Open3.capture2e("git", "-C", @notes_root, *args)
    raise "git #{args.join(" ")} failed: #{output}" unless status.success?

    output
  end
end
