# frozen_string_literal: true

require "fileutils"

class NotesOperationLock
  LOCK_DIR = ".mirai"
  LOCK_FILENAME = "operations.lock"

  def initialize(notes_root:)
    @lock_path = File.join(notes_root, LOCK_DIR, LOCK_FILENAME)
  end

  def with_exclusive_lock
    raise ArgumentError, "block is required" unless block_given?

    FileUtils.mkdir_p(File.dirname(@lock_path))
    File.open(@lock_path, "a") do |file|
      file.flock(File::LOCK_EX)
      yield
    ensure
      file.flock(File::LOCK_UN)
    end
  end
end
