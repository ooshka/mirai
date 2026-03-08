# frozen_string_literal: true

require_relative "../../../app/services/retrieval/query_snippet_annotator"

RSpec.describe QuerySnippetAnnotator do
  it "adds deterministic offsets for first query-token match per chunk" do
    annotator = described_class.new

    result = annotator.annotate(
      query_text: "beta alpha",
      chunks: [
        {path: "a.md", chunk_index: 0, content: "alpha beta", score: 2},
        {path: "b.md", chunk_index: 0, content: "alpha only", score: 1}
      ]
    )

    expect(result).to eq(
      [
        {path: "a.md", chunk_index: 0, content: "alpha beta", score: 2, snippet_offset: {start: 6, end: 10}},
        {path: "b.md", chunk_index: 0, content: "alpha only", score: 1, snippet_offset: {start: 0, end: 5}}
      ]
    )
  end

  it "matches tokens case-insensitively with lexical boundaries" do
    annotator = described_class.new

    result = annotator.annotate(
      query_text: "alpha",
      chunks: [
        {path: "a.md", chunk_index: 0, content: "MALPHA alpha", score: 1}
      ]
    )

    expect(result).to eq(
      [
        {path: "a.md", chunk_index: 0, content: "MALPHA alpha", score: 1, snippet_offset: {start: 7, end: 12}}
      ]
    )
  end

  it "returns nil offset when no lexical match exists" do
    annotator = described_class.new

    result = annotator.annotate(
      query_text: "lion",
      chunks: [
        {path: "a.md", chunk_index: 0, content: "tiger", score: 0.9}
      ]
    )

    expect(result).to eq(
      [
        {path: "a.md", chunk_index: 0, content: "tiger", score: 0.9, snippet_offset: nil}
      ]
    )
  end
end
