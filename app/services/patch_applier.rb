# frozen_string_literal: true

require_relative "patch_validator"
require_relative "notes_git_committer"

class PatchApplier
  class ConflictError < StandardError; end
  class CommitError < StandardError; end

  def initialize(notes_root:)
    @validator = PatchValidator.new(notes_root: notes_root)
    @committer = NotesGitCommitter.new(notes_root: notes_root)
  end

  def apply(untrusted_patch)
    validated_patch = @validator.validate(untrusted_patch)
    absolute_path = validated_patch[:absolute_path]

    raise Errno::ENOENT, absolute_path unless File.file?(absolute_path)

    original = File.read(absolute_path)
    updated = apply_hunks(original, validated_patch[:hunks])
    File.write(absolute_path, updated)
    @committer.commit_file(
      path: validated_patch[:path],
      message: "Apply patch to #{validated_patch[:path]}"
    )

    validated_patch.slice(:path, :hunk_count, :net_line_delta)
  rescue NotesGitCommitter::CommitError => e
    File.write(absolute_path, original) if defined?(absolute_path) && defined?(original)
    raise CommitError, e.message
  end

  private

  def apply_hunks(content, hunks)
    lines = content.lines(chomp: true)
    offset = 0

    hunks.each do |hunk|
      current_index = (hunk[:old_start] - 1) + offset
      raise ConflictError, "patch does not apply cleanly" if current_index.negative?

      hunk[:lines].each do |line|
        case line[:op]
        when " "
          verify_line!(lines, current_index, line[:text])
          current_index += 1
        when "-"
          verify_line!(lines, current_index, line[:text])
          lines.delete_at(current_index)
          offset -= 1
        when "+"
          lines.insert(current_index, line[:text])
          current_index += 1
          offset += 1
        end
      end
    end

    return "" if lines.empty?

    "#{lines.join("\n")}\n"
  end

  def verify_line!(lines, index, expected)
    actual = lines[index]
    raise ConflictError, "patch does not apply cleanly" unless actual == expected
  end
end
