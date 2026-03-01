# frozen_string_literal: true

class PatchParser
  class ParseError < StandardError; end

  HUNK_HEADER = /^@@\s+-(\d+)(?:,(\d+))?\s+\+(\d+)(?:,(\d+))?\s+@@/

  def parse(untrusted_patch)
    patch = String(untrusted_patch)
    lines = patch.lines(chomp: true)

    raise ParseError, "patch is required" if lines.empty?

    path, index = parse_file_header(lines)
    hunks = parse_hunks(lines, index)

    {path: path, hunks: hunks}
  rescue TypeError
    raise ParseError, "patch is required"
  end

  private

  def parse_file_header(lines)
    old_line = lines[0]
    new_line = lines[1]

    raise ParseError, "invalid patch header" unless old_line&.start_with?("--- ")
    raise ParseError, "invalid patch header" unless new_line&.start_with?("+++ ")

    old_path = normalize_prefixed_path(old_line.delete_prefix("--- "))
    new_path = normalize_prefixed_path(new_line.delete_prefix("+++ "))

    raise ParseError, "invalid patch header" if old_path != new_path

    [old_path, 2]
  end

  def normalize_prefixed_path(path_with_prefix)
    path = path_with_prefix.strip
    raise ParseError, "invalid patch header" if path == "/dev/null"

    prefix, relative_path = path.split("/", 2)
    raise ParseError, "invalid patch header" unless %w[a b].include?(prefix)
    raise ParseError, "invalid patch header" if relative_path.nil? || relative_path.empty?

    relative_path
  end

  def parse_hunks(lines, start_index)
    hunks = []
    index = start_index

    while index < lines.length
      line = lines[index]
      raise ParseError, "only single-file patches are supported" if line.start_with?("--- ", "+++ ")

      match = line.match(HUNK_HEADER)
      raise ParseError, "invalid hunk header" unless match

      index += 1
      raw_lines = []

      while index < lines.length && !lines[index].start_with?("@@")
        current = lines[index]
        raise ParseError, "only single-file patches are supported" if current.start_with?("--- ", "+++ ")

        raw_lines << current
        index += 1
      end

      hunks << {
        old_start: match[1].to_i,
        old_count: (match[2] || "1").to_i,
        new_start: match[3].to_i,
        new_count: (match[4] || "1").to_i,
        raw_lines: raw_lines
      }
    end

    raise ParseError, "patch must include at least one hunk" if hunks.empty?

    hunks
  end
end
