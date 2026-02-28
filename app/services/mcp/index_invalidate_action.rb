# frozen_string_literal: true

require_relative "../index_store"

module Mcp
  class IndexInvalidateAction
    def initialize(notes_root:)
      @index_store = IndexStore.new(notes_root: notes_root)
    end

    def call
      {invalidated: @index_store.delete}
    end
  end
end
