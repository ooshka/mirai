# frozen_string_literal: true

require "tmpdir"
require "timeout"

RSpec.describe "MCP index lifecycle locking" do
  let(:lock_spy_class) do
    Class.new do
      attr_reader :calls, :inside

      def initialize
        @calls = 0
        @inside = false
      end

      def with_exclusive_lock
        @calls += 1
        @inside = true
        yield
      ensure
        @inside = false
      end
    end
  end

  it "wraps patch apply and artifact invalidation in one exclusive lock" do
    lock = lock_spy_class.new
    applier = instance_double(PatchApplier)
    index_store = instance_double(IndexStore)

    expect(applier).to receive(:apply).with("patch-body") do
      expect(lock.inside).to eq(true)
      {path: "notes/today.md", hunk_count: 1, net_line_delta: 1}
    end
    expect(index_store).to receive(:delete) do
      expect(lock.inside).to eq(true)
      true
    end

    action = Mcp::PatchApplyAction.new(
      notes_root: "/unused",
      applier: applier,
      index_store: index_store,
      operation_lock: lock
    )

    result = action.call(patch: "patch-body")

    expect(result).to eq({path: "notes/today.md", hunk_count: 1, net_line_delta: 1})
    expect(lock.calls).to eq(1)
  end

  it "wraps index rebuild in an exclusive lock" do
    lock = lock_spy_class.new
    index = {
      notes_indexed: 1,
      chunks_indexed: 2,
      chunks: [
        {path: "root.md", chunk_index: 0, content: "alpha"},
        {path: "root.md", chunk_index: 1, content: "beta"}
      ]
    }
    indexer = instance_double(NotesIndexer)
    index_store = instance_double(IndexStore)

    expect(indexer).to receive(:index) do
      expect(lock.inside).to eq(true)
      index
    end
    expect(index_store).to receive(:write).with(index) do
      expect(lock.inside).to eq(true)
    end

    action = Mcp::IndexRebuildAction.new(
      notes_root: "/unused",
      indexer: indexer,
      index_store: index_store,
      operation_lock: lock
    )

    result = action.call

    expect(result).to eq({notes_indexed: 1, chunks_indexed: 2})
    expect(lock.calls).to eq(1)
  end

  it "wraps index invalidation in an exclusive lock" do
    lock = lock_spy_class.new
    index_store = instance_double(IndexStore)

    expect(index_store).to receive(:delete) do
      expect(lock.inside).to eq(true)
      true
    end

    action = Mcp::IndexInvalidateAction.new(
      notes_root: "/unused",
      index_store: index_store,
      operation_lock: lock
    )

    expect(action.call).to eq({invalidated: true})
    expect(lock.calls).to eq(1)
  end

  it "keeps artifact invalidated when patch apply races with rebuild and rebuild enters lock first" do
    Dir.mktmpdir("notes-root") do |notes_root|
      operation_lock = NotesOperationLock.new(notes_root: notes_root)
      index_store = IndexStore.new(notes_root: notes_root)
      rebuild_started = Queue.new

      index_store.write(
        {
          notes_indexed: 1,
          chunks_indexed: 1,
          chunks: [{path: "root.md", chunk_index: 0, content: "before"}]
        }
      )
      expect(index_store.read).not_to be_nil

      slow_indexer = instance_double(NotesIndexer)
      allow(slow_indexer).to receive(:index) do
        rebuild_started << true
        sleep 0.2
        {
          notes_indexed: 1,
          chunks_indexed: 1,
          chunks: [{path: "root.md", chunk_index: 0, content: "after"}]
        }
      end

      applier = instance_double(PatchApplier)
      allow(applier).to receive(:apply).and_return(
        {path: "root.md", hunk_count: 1, net_line_delta: 1}
      )

      rebuild_action = Mcp::IndexRebuildAction.new(
        notes_root: notes_root,
        indexer: slow_indexer,
        index_store: index_store,
        operation_lock: operation_lock
      )
      patch_action = Mcp::PatchApplyAction.new(
        notes_root: notes_root,
        applier: applier,
        index_store: index_store,
        operation_lock: operation_lock
      )

      rebuild_thread = Thread.new { rebuild_action.call }
      Timeout.timeout(2) { rebuild_started.pop }
      patch_thread = Thread.new { patch_action.call(patch: "unused") }

      expect(rebuild_thread.join(2)).not_to be_nil
      expect(patch_thread.join(2)).not_to be_nil
      expect(index_store.read).to be_nil
    end
  end
end
