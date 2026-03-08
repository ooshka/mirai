# frozen_string_literal: true

require_relative "../../../app/services/mcp/patch_apply_action"

RSpec.describe Mcp::PatchApplyAction do
  let(:applier) { instance_double(PatchApplier) }
  let(:index_store) { instance_double(IndexStore) }
  let(:operation_lock) { instance_double(NotesOperationLock) }
  let(:semantic_ingestion_service) { instance_double(NullSemanticIngestionService) }

  it "enqueues semantic ingestion for the patched path after invalidating index" do
    action = described_class.new(
      notes_root: "/notes",
      applier: applier,
      index_store: index_store,
      operation_lock: operation_lock,
      semantic_ingestion_service: semantic_ingestion_service
    )

    allow(operation_lock).to receive(:with_exclusive_lock).and_yield
    allow(applier).to receive(:apply).and_return({path: "notes/today.md", hunk_count: 1, net_line_delta: 1})
    expect(index_store).to receive(:delete).ordered
    expect(semantic_ingestion_service).to receive(:enqueue_for_paths).with(paths: ["notes/today.md"]).ordered

    result = action.call(patch: "patch")

    expect(result.fetch(:path)).to eq("notes/today.md")
  end

  it "keeps patch apply successful when semantic ingestion enqueue raises" do
    action = described_class.new(
      notes_root: "/notes",
      applier: applier,
      index_store: index_store,
      operation_lock: operation_lock,
      semantic_ingestion_service: semantic_ingestion_service
    )

    allow(operation_lock).to receive(:with_exclusive_lock).and_yield
    allow(applier).to receive(:apply).and_return({path: "notes/today.md", hunk_count: 1, net_line_delta: 1})
    allow(index_store).to receive(:delete)
    allow(semantic_ingestion_service).to receive(:enqueue_for_paths).and_raise(StandardError, "boom")

    expect(action.call(patch: "patch")).to include(path: "notes/today.md")
  end
end
