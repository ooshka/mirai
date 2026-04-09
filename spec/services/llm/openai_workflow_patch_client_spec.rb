# frozen_string_literal: true

require "json"
require_relative "../../../app/services/llm/openai_workflow_patch_client"

RSpec.describe Llm::OpenAiWorkflowPatchClient do
  def ok_response(body)
    response = double("response", body: JSON.generate(body), code: "200")
    allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
    response
  end

  it "requests and returns a normalized edit_intent payload" do
    client = described_class.new(api_key: "sk-test", model: "gpt-4.1-mini", base_url: "https://api.openai.com")
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
      expect(use_ssl).to eq(true)
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
      "model" => "gpt-4.1-mini",
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

  it "raises response error when edit_intent is missing" do
    client = described_class.new(api_key: "sk-test", model: "gpt-4.1-mini", base_url: "https://api.openai.com")
    response = ok_response("choices" => [{"message" => {"content" => JSON.generate(path: "notes/today.md")}}])

    allow(Net::HTTP).to receive(:start) do |_host, _port, use_ssl:, &block|
      expect(use_ssl).to eq(true)
      fake_http = double("http")
      allow(fake_http).to receive(:request).and_return(response)
      block.call(fake_http)
    end

    expect do
      client.draft_patch(instruction: "add beta", path: "notes/today.md", content: "alpha\n", context: {})
    end.to raise_error(described_class::ResponseError, "openai workflow patch drafter response missing edit_intent object")
  end
end
