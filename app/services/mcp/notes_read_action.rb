# frozen_string_literal: true

require_relative "../notes_reader"

module Mcp
  class NotesReadAction
    def initialize(notes_root:)
      @reader = NotesReader.new(notes_root: notes_root)
    end

    def call(path:)
      {path: path, content: @reader.read_note(path)}
    end
  end
end
