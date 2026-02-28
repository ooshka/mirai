# frozen_string_literal: true

require_relative "../index_store"

module Mcp
  class IndexStatusAction
    def initialize(notes_root:)
      @index_store = IndexStore.new(notes_root: notes_root)
    end

    def call
      @index_store.status
    end
  end
end
