# frozen_string_literal: true

require_relative "../../../app/services/retrieval/openai_semantic_ingestion_processor"

RSpec.describe OpenAiSemanticIngestionProcessor do
  it "upserts per requested path using indexed chunks" do
    indexer = instance_double(NotesIndexer)
    openai_client = instance_double(OpenAiSemanticClient)
    processor = described_class.new(
      notes_root: "/notes",
      indexer: indexer,
      openai_client: openai_client
    )

    allow(indexer).to receive(:index).and_return(
      {
        chunks: [
          {path: "notes/a.md", chunk_index: 0, content: "A0"},
          {path: "notes/a.md", chunk_index: 1, content: "A1"},
          {path: "notes/b.md", chunk_index: 0, content: "B0"}
        ]
      }
    )
    expect(openai_client).to receive(:upsert_path_chunks).with(
      path: "notes/a.md",
      chunks: [
        {chunk_index: 0, content: "A0"},
        {chunk_index: 1, content: "A1"}
      ]
    )
    expect(openai_client).to receive(:upsert_path_chunks).with(path: "notes/c.md", chunks: [])

    processor.process(paths: ["notes/a.md", "notes/c.md"])
  end
end
