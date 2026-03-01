# frozen_string_literal: true

require_relative "notes_indexer"
require_relative "index_store"
require_relative "lexical_chunk_scorer"
require_relative "lexical_retrieval_provider"
require_relative "semantic_retrieval_provider"

class NotesRetriever
  DEFAULT_LIMIT = 5
  MAX_LIMIT = 50
  MODE_LEXICAL = "lexical"
  MODE_SEMANTIC = "semantic"

  def initialize(
    notes_root:,
    indexer: NotesIndexer.new(notes_root: notes_root),
    index_store: IndexStore.new(notes_root: notes_root),
    provider: nil,
    mode: ENV.fetch("MCP_RETRIEVAL_MODE", MODE_LEXICAL),
    semantic_provider_enabled: ENV.fetch("MCP_SEMANTIC_PROVIDER_ENABLED", "false"),
    lexical_provider: LexicalRetrievalProvider.new,
    semantic_provider: nil
  )
    @indexer = indexer
    @index_store = index_store
    @mode = normalize_mode(mode)
    @lexical_provider = lexical_provider
    @semantic_provider = semantic_provider || SemanticRetrievalProvider.new(
      enabled: truthy?(semantic_provider_enabled),
      lexical_provider: @lexical_provider
    )
    @provider = provider || provider_for_mode
  end

  def query(text:, limit: DEFAULT_LIMIT)
    chunks = chunks_for_query
    @provider.rank(query_text: text, chunks: chunks, limit: limit)
  rescue SemanticRetrievalProvider::UnavailableError
    @lexical_provider.rank(query_text: text, chunks: chunks, limit: limit)
  end

  private

  def provider_for_mode
    @mode == MODE_SEMANTIC ? @semantic_provider : @lexical_provider
  end

  def normalize_mode(mode)
    normalized = mode.to_s.strip.downcase
    return MODE_LEXICAL if normalized.empty?
    return MODE_SEMANTIC if normalized == MODE_SEMANTIC

    MODE_LEXICAL
  end

  def truthy?(value)
    value.to_s.strip.downcase == "true"
  end

  def chunks_for_query
    stored_index = @index_store.read
    return stored_index.fetch(:chunks, []) if stored_index

    @indexer.index.fetch(:chunks, [])
  end
end
