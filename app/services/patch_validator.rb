# frozen_string_literal: true

require_relative "safe_notes_path"

class PatchValidator
  class InvalidPatchError < StandardError; end

  HUNK_HEADER = /^@@\s+-(\d+)(?:,(\d+))?\s+\+(\d+)(?:,(\d+))?\s+@@/

  def initialize(notes_root:)
    @safe_path = SafeNotesPath.new(notes_root: notes_root)
  end

  def validate(untrusted_patch)
    patch = String(untrusted_patch)
    lines = patch.lines(chomp: true)

    raise InvalidPatchError, "patch is required" if lines.empty?

    path, index = parse_file_header(lines)
    absolute_path = @safe_path.resolve(path)
    hunks, net_line_delta = parse_hunks(lines, index)

    {
      path: path,
      absolute_path: absolute_path,
      hunk_count: hunks.size,
      net_line_delta: net_line_delta,
      hunks: hunks
    }
  rescue TypeError
    raise InvalidPatchError, "patch is required"
  end

  private

  def parse_file_header(lines)
    old_line = lines[0]
    new_line = lines[1]

    raise InvalidPatchError, "invalid patch header" unless old_line&.start_with?("--- ")
    raise InvalidPatchError, "invalid patch header" unless new_line&.start_with?("+++ ")

    old_path = normalize_prefixed_path(old_line.delete_prefix("--- "))
    new_path = normalize_prefixed_path(new_line.delete_prefix("+++ "))

    raise InvalidPatchError, "invalid patch header" if old_path != new_path

    [old_path, 2]
  end

  def normalize_prefixed_path(path_with_prefix)
    path = path_with_prefix.strip
    raise InvalidPatchError, "invalid patch header" if path == "/dev/null"

    prefix, relative_path = path.split("/", 2)
    raise InvalidPatchError, "invalid patch header" unless %w[a b].include?(prefix)
    raise InvalidPatchError, "invalid patch header" if relative_path.nil? || relative_path.empty?

    relative_path
  end

  def parse_hunks(lines, start_index)
    hunks = []
    net_line_delta = 0
    index = start_index

    while index < lines.length
      line = lines[index]
      raise InvalidPatchError, "only single-file patches are supported" if line.start_with?("--- ", "+++ ")

      match = line.match(HUNK_HEADER)
      raise InvalidPatchError, "invalid hunk header" unless match

      old_start = match[1].to_i
      old_count = (match[2] || "1").to_i
      new_start = match[3].to_i
      new_count = (match[4] || "1").to_i

      index += 1
      hunk_lines = []

      while index < lines.length && !lines[index].start_with?("@@")
        current = lines[index]
        raise InvalidPatchError, "only single-file patches are supported" if current.start_with?("--- ", "+++ ")

        prefix = current[0]
        raise InvalidPatchError, "unsupported hunk line prefix" unless [" ", "+", "-"].include?(prefix)

        hunk_lines << { op: prefix, text: current[1..] || "" }
        index += 1
      end

      validate_hunk_counts!(hunk_lines, old_count, new_count)

      hunks << {
        old_start: old_start,
        old_count: old_count,
        new_start: new_start,
        new_count: new_count,
        lines: hunk_lines
      }

      net_line_delta += (new_count - old_count)
    end

    raise InvalidPatchError, "patch must include at least one hunk" if hunks.empty?

    [hunks, net_line_delta]
  end

  def validate_hunk_counts!(hunk_lines, old_count, new_count)
    old_seen = hunk_lines.count { |line| line[:op] == " " || line[:op] == "-" }
    new_seen = hunk_lines.count { |line| line[:op] == " " || line[:op] == "+" }

    raise InvalidPatchError, "hunk line count does not match header" unless old_seen == old_count
    raise InvalidPatchError, "hunk line count does not match header" unless new_seen == new_count
  end
end
