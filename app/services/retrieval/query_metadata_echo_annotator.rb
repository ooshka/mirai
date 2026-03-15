# frozen_string_literal: true

class QueryMetadataEchoAnnotator
  def annotate(chunks:)
    chunks.map do |chunk|
      {
        content: chunk.fetch(:content),
        score: chunk.fetch(:score),
        metadata: {
          path: chunk.fetch(:path),
          chunk_index: Integer(chunk.fetch(:chunk_index)),
          snippet_offset: chunk.fetch(:snippet_offset, nil)
        }
      }
    end
  end
end
