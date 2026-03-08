# frozen_string_literal: true

require_relative "../indexing/notes_indexer"
require_relative "openai_semantic_client"

class OpenAiSemanticIngestionProcessor
  def initialize(
    notes_root:,
    indexer: NotesIndexer.new(notes_root: notes_root),
    openai_client: OpenAiSemanticClient.new(api_key: nil)
  )
    @indexer = indexer
    @openai_client = openai_client
  end

  def process(paths:)
    normalized_paths = normalize_paths(paths)
    return if normalized_paths.empty?

    chunks = @indexer.index.fetch(:chunks, [])
    chunks_by_path = chunks.group_by { |chunk| chunk.fetch(:path) }

    normalized_paths.each do |path|
      path_chunks = chunks_by_path.fetch(path, []).map do |chunk|
        {chunk_index: Integer(chunk.fetch(:chunk_index)), content: chunk.fetch(:content)}
      end

      @openai_client.upsert_path_chunks(path: path, chunks: path_chunks)
    end
  end

  private

  def normalize_paths(paths)
    Array(paths).filter_map do |path|
      next unless path.is_a?(String)

      normalized = path.strip
      next if normalized.empty?

      normalized
    end.uniq
  end
end
