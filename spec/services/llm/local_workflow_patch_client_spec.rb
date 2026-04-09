# frozen_string_literal: true

require "json"
require_relative "../../../app/services/llm/local_workflow_patch_client"

RSpec.describe Llm::LocalWorkflowPatchClient do
  def ok_response(body)
    response = double("response", body: JSON.generate(body), code: "200")
    allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
    response
  end

  it "returns a normalized edit_intent response" do
    client = described_class.new(model: "qwen2.5:7b-instruct", base_url: "http://127.0.0.1:11434")
    requests = []
    response = ok_response(
      "choices" => [
        {
          "message" => {
            "content" => JSON.generate(
              edit_intent: {
                path: "notes/today.md",
                operation: "replace_content",
                content: "alpha\nbeta"
              }
            )
          }
        }
      ]
    )

    allow(Net::HTTP).to receive(:start) do |_host, _port, use_ssl:, &block|
      expect(use_ssl).to eq(false)
      fake_http = double("http")
      allow(fake_http).to receive(:request) do |request|
        requests << request
        response
      end
      block.call(fake_http)
    end

    result = client.draft_patch(
      instruction: "add beta",
      path: "notes/today.md",
      content: "alpha\n",
      context: {"source" => "planner"}
    )

    expect(requests.length).to eq(1)
    expect(requests.first.uri.path).to eq("/v1/chat/completions")
    expect(JSON.parse(requests.first.body)).to include(
      "model" => "qwen2.5:7b-instruct",
      "response_format" => {"type" => "json_object"}
    )
    expect(result).to eq(
      {
        path: "notes/today.md",
        operation: "replace_content",
        content: "alpha\nbeta\n"
      }
    )
  end

  it "extracts a non-empty edit_intent from a json message content payload" do
    client = described_class.new(model: "qwen2.5:7b-instruct", base_url: "http://127.0.0.1:11434")
    response = ok_response(
      "choices" => [
        {
          "message" => {
            "content" => JSON.generate(
              edit_intent: {
                path: "notes/today.md",
                operation: "replace_content",
                content: "alpha\nbeta\n"
              }
            )
          }
        }
      ]
    )

    allow(Net::HTTP).to receive(:start) do |_host, _port, use_ssl:, &block|
      expect(use_ssl).to eq(false)
      fake_http = double("http")
      allow(fake_http).to receive(:request).and_return(response)
      block.call(fake_http)
    end

    result = client.draft_patch(
      instruction: "add beta",
      path: "notes/today.md",
      content: "alpha\n",
      context: {}
    )

    expect(result).to eq(
      {
        path: "notes/today.md",
        operation: "replace_content",
        content: "alpha\nbeta\n"
      }
    )
  end

  it "raises response error when the provider payload is missing message content" do
    client = described_class.new(model: "qwen2.5:7b-instruct", base_url: "http://127.0.0.1:11434")
    response = ok_response("choices" => [{"message" => {}}])

    allow(Net::HTTP).to receive(:start) do |_host, _port, use_ssl:, &block|
      expect(use_ssl).to eq(false)
      fake_http = double("http")
      allow(fake_http).to receive(:request).and_return(response)
      block.call(fake_http)
    end

    expect do
      client.draft_patch(instruction: "add beta", path: "notes/today.md", content: "alpha\n", context: {})
    end.to raise_error(described_class::ResponseError, "local workflow patch drafter response is malformed")
  end

  it "raises response error when the provider edit_intent is missing content" do
    client = described_class.new(model: "qwen2.5:7b-instruct", base_url: "http://127.0.0.1:11434")
    response = ok_response(
      "choices" => [
        {
          "message" => {
            "content" => JSON.generate(
              edit_intent: {
                path: "notes/today.md",
                operation: "replace_content"
              }
            )
          }
        }
      ]
    )

    allow(Net::HTTP).to receive(:start) do |_host, _port, use_ssl:, &block|
      expect(use_ssl).to eq(false)
      fake_http = double("http")
      allow(fake_http).to receive(:request).and_return(response)
      block.call(fake_http)
    end

    expect do
      client.draft_patch(instruction: "add beta", path: "notes/today.md", content: "alpha\n", context: {})
    end.to raise_error(described_class::ResponseError, "local workflow patch drafter edit_intent.content must be a string")
  end

  it "raises response error when message content is not valid json" do
    client = described_class.new(model: "qwen2.5:7b-instruct", base_url: "http://127.0.0.1:11434")
    response = ok_response(
      "choices" => [
        {
          "message" => {
            "content" => "plain text response"
          }
        }
      ]
    )

    allow(Net::HTTP).to receive(:start) do |_host, _port, use_ssl:, &block|
      expect(use_ssl).to eq(false)
      fake_http = double("http")
      allow(fake_http).to receive(:request).and_return(response)
      block.call(fake_http)
    end

    expect do
      client.draft_patch(instruction: "add beta", path: "notes/today.md", content: "alpha\n", context: {})
    end.to raise_error(described_class::ResponseError, /local workflow patch drafter response was not valid json:/)
  end

  it "raises request error when the provider is unreachable" do
    client = described_class.new(model: "qwen2.5:7b-instruct", base_url: "http://127.0.0.1:11434")

    allow(Net::HTTP).to receive(:start).and_raise(Errno::ECONNREFUSED, "Connection refused")

    expect do
      client.draft_patch(instruction: "add beta", path: "notes/today.md", content: "alpha\n", context: {})
    end.to raise_error(described_class::RequestError, /local workflow patch drafter request error:/)
  end
end
