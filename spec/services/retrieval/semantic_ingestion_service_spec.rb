# frozen_string_literal: true

require "logger"
require_relative "../../../app/services/retrieval/semantic_ingestion_service"

RSpec.describe AsyncSemanticIngestionService do
  let(:logger) { Logger.new(nil) }

  it "deduplicates queued paths and processes enqueued work" do
    processor = instance_double("processor")
    service = described_class.new(
      enabled: true,
      processor: processor,
      logger: logger,
      autostart: false
    )

    expect(service.enqueue_for_paths(paths: ["notes/a.md", "notes/a.md", "  ", nil])).to eq(true)
    expect(service.enqueue_for_paths(paths: ["notes/a.md"])).to eq(true)
    expect(processor).to receive(:process).with(paths: ["notes/a.md"]).once

    expect(service.process).to eq(true)
    expect(service.process).to eq(false)
  end

  it "does not raise when processor fails and allows re-enqueue" do
    processor = instance_double("processor")
    service = described_class.new(
      enabled: true,
      processor: processor,
      logger: logger,
      autostart: false
    )

    expect(service.enqueue_for_paths(paths: ["notes/a.md"])).to eq(true)
    allow(processor).to receive(:process).and_raise(StandardError, "failure")

    expect(service.process).to eq(true)
    expect(service.enqueue_for_paths(paths: ["notes/a.md"])).to eq(true)
  end

  it "is inert when disabled" do
    processor = instance_double("processor")
    service = described_class.new(
      enabled: false,
      processor: processor,
      logger: logger,
      autostart: false
    )

    expect(service.enqueue_for_paths(paths: ["notes/a.md"])).to eq(false)
    expect(service.process).to eq(false)
  end
end
