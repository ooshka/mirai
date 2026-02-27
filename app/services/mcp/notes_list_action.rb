# frozen_string_literal: true

require_relative "../notes_reader"

module Mcp
  class NotesListAction
    def initialize(notes_root:)
      @reader = NotesReader.new(notes_root: notes_root)
    end

    def call
      {notes: @reader.list_notes}
    end
  end
end
