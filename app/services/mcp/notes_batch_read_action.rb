# frozen_string_literal: true

require_relative "../notes_reader"

module Mcp
  class NotesBatchReadAction
    MAX_BATCH_SIZE = 20

    class InvalidPathsError < StandardError; end

    def initialize(notes_root:)
      @reader = NotesReader.new(notes_root: notes_root)
    end

    def call(paths:)
      validated_paths = validate_paths!(paths)
      {
        notes: validated_paths.map do |path|
          {path: path, content: @reader.read_note(path)}
        end
      }
    end

    private

    def validate_paths!(paths)
      raise InvalidPathsError, "paths must be an array" unless paths.is_a?(Array)
      raise InvalidPathsError, "paths must not be empty" if paths.empty?
      raise InvalidPathsError, "paths exceeds max batch size of #{MAX_BATCH_SIZE}" if paths.length > MAX_BATCH_SIZE

      paths.map do |path|
        raise InvalidPathsError, "each path must be a string" unless path.is_a?(String)

        normalized_path = path.strip
        raise InvalidPathsError, "paths must not contain empty entries" if normalized_path.empty?

        normalized_path
      end
    end
  end
end
