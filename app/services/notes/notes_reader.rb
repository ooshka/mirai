# frozen_string_literal: true

require_relative "safe_notes_path"

class NotesReader
  def initialize(notes_root:)
    @safe_path = SafeNotesPath.new(notes_root: notes_root)
  end

  def list_notes
    @safe_path.list_markdown_files
  end

  def read_note(untrusted_path)
    absolute_path = @safe_path.resolve(untrusted_path)
    raise Errno::ENOENT, absolute_path unless File.file?(absolute_path)

    File.read(absolute_path)
  end
end
