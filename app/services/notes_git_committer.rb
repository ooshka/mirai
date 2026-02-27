# frozen_string_literal: true

require "open3"

class NotesGitCommitter
  class CommitError < StandardError; end

  def initialize(notes_root:)
    @notes_root = notes_root
  end

  def commit_file(path:, message:)
    run_git!("rev-parse", "--is-inside-work-tree")
    run_git!("add", "--", path)
    run_git!("commit", "-m", message, "--", path)
  end

  private

  def run_git!(*args)
    _stdout, stderr, status = Open3.capture3("git", *args, chdir: @notes_root)
    return if status.success?

    raise CommitError, "git command failed: #{stderr.strip}"
  end
end
