# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require_relative "../../../app/services/mcp/workflow_plan_context_builder"

RSpec.describe Mcp::WorkflowPlanContextBuilder do
  it "builds deterministic retrieval metadata with no path hint" do
    Dir.mktmpdir("notes-root") do |notes_root|
      builder = described_class.new(
        notes_root: notes_root,
        retrieval_mode: "lexical",
        semantic_provider_enabled: false,
        semantic_provider: "openai",
        semantic_ingestion_enabled: false,
        semantic_configured: false
      )

      result = builder.build(input_context: {"scope" => "notes"}, path_hint: nil)

      expect(result).to include(
        input: {"scope" => "notes"},
        hints: {path: nil},
        note_snapshot: nil
      )
      expect(result.fetch(:retrieval_status)).to include(
        retrieval_mode: "lexical",
        semantic_provider_enabled: false,
        semantic_provider: "openai",
        semantic_ingestion_enabled: false,
        semantic_configured: false
      )
      expect(result.fetch(:retrieval_status).fetch(:index_status)).to include(
        present: false,
        notes_present: 0
      )
    end
  end

  it "builds a bounded note snapshot when path hint is provided" do
    Dir.mktmpdir("notes-root") do |notes_root|
      FileUtils.mkdir_p(File.join(notes_root, "notes"))
      long_content = ("a" * 700) + "\n"
      File.write(File.join(notes_root, "notes/today.md"), long_content)

      builder = described_class.new(
        notes_root: notes_root,
        retrieval_mode: "semantic",
        semantic_provider_enabled: true,
        semantic_provider: "openai",
        semantic_ingestion_enabled: true,
        semantic_configured: true
      )

      result = builder.build(input_context: {}, path_hint: "notes/today.md")
      snapshot = result.fetch(:note_snapshot)

      expect(snapshot).to include(
        path: "notes/today.md",
        bytes: long_content.bytesize,
        preview_truncated: true
      )
      expect(snapshot.fetch(:preview).length).to eq(described_class::NOTE_PREVIEW_LIMIT)
    end
  end

  it "raises not found when hinted note does not exist" do
    Dir.mktmpdir("notes-root") do |notes_root|
      builder = described_class.new(
        notes_root: notes_root,
        retrieval_mode: "lexical",
        semantic_provider_enabled: false,
        semantic_provider: "openai",
        semantic_ingestion_enabled: false,
        semantic_configured: false
      )

      expect do
        builder.build(input_context: {}, path_hint: "notes/missing.md")
      end.to raise_error(Errno::ENOENT)
    end
  end
end
