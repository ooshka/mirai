# frozen_string_literal: true

require_relative "../indexing/notes_indexer"
require_relative "../indexing/index_store"
require_relative "lexical_chunk_scorer"
require_relative "query_snippet_annotator"
require_relative "retrieval_provider_factory"
require_relative "retrieval_fallback_policy"

class NotesRetriever
  DEFAULT_LIMIT = 5
  MAX_LIMIT = 50

  def initialize(
    notes_root:,
    indexer: NotesIndexer.new(notes_root: notes_root),
    index_store: IndexStore.new(notes_root: notes_root),
    provider: nil,
    snippet_annotator: QuerySnippetAnnotator.new,
    provider_factory: RetrievalProviderFactory.new,
    fallback_policy: RetrievalFallbackPolicy.new
  )
    @indexer = indexer
    @index_store = index_store
    @snippet_annotator = snippet_annotator
    @fallback_policy = fallback_policy
    if provider
      @provider = provider
      @fallback_provider = provider
    else
      provider_setup = provider_factory.build
      @provider = provider_setup.fetch(:primary_provider)
      @fallback_provider = provider_setup.fetch(:fallback_provider)
    end
  end

  def query(text:, limit: DEFAULT_LIMIT, path_prefix: nil)
    explanation_matcher = explanation_matcher_for_query
    query_tokens = explanation_matcher.tokenize(text).uniq
    chunks = chunks_for_query(path_prefix: path_prefix)
    ranked_chunks = @fallback_policy.rank(
      primary_provider: @provider,
      fallback_provider: @fallback_provider,
      query_text: text,
      chunks: chunks,
      limit: limit
    )

    annotated_chunks = @snippet_annotator.annotate(query_text: text, chunks: ranked_chunks)

    build_query_response_chunks(
      explanation_matcher: explanation_matcher,
      query_tokens: query_tokens,
      chunks: annotated_chunks
    )
  end

  private

  def build_query_response_chunks(explanation_matcher:, query_tokens:, chunks:)
    chunks.map do |chunk|
      content = chunk.fetch(:content)

      {
        content: content,
        score: chunk.fetch(:score),
        metadata: {
          path: chunk.fetch(:path),
          chunk_index: Integer(chunk.fetch(:chunk_index)),
          snippet_offset: chunk.fetch(:snippet_offset, nil)
        },
        explanation: build_query_explanation(
          matcher: explanation_matcher,
          query_tokens: query_tokens,
          content: content
        )
      }
    end
  end

  def build_query_explanation(matcher:, query_tokens:, content:)
    matched_terms = query_tokens.select do |token|
      matcher.token_match(text: content, token: token)
    end

    {
      matched_terms: matched_terms,
      matched_term_count: matched_terms.length
    }
  end

  def explanation_matcher_for_query
    return @fallback_provider if lexical_matcher?(@fallback_provider)
    return @provider if lexical_matcher?(@provider)

    LexicalChunkScorer.new
  end

  def lexical_matcher?(provider)
    provider.respond_to?(:tokenize) && provider.respond_to?(:token_match)
  end

  def chunks_for_query(path_prefix:)
    stored_index = @index_store.read
    chunks = if stored_index
      stored_index.fetch(:chunks, [])
    else
      @indexer.index.fetch(:chunks, [])
    end

    return chunks if path_prefix.nil?

    chunks.select { |chunk| chunk.fetch(:path, "").start_with?(path_prefix) }
  end
end
