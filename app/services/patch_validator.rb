# frozen_string_literal: true

require_relative "safe_notes_path"
require_relative "patch_parser"

class PatchValidator
  class InvalidPatchError < StandardError; end

  NO_NEWLINE_MARKER = "\\ No newline at end of file"

  def initialize(notes_root:)
    @safe_path = SafeNotesPath.new(notes_root: notes_root)
    @parser = PatchParser.new
  end

  def validate(untrusted_patch)
    parsed = @parser.parse(untrusted_patch)
    path = parsed[:path]
    absolute_path = @safe_path.resolve(path)
    hunks, net_line_delta = validate_hunks(parsed[:hunks])

    {
      path: path,
      absolute_path: absolute_path,
      hunk_count: hunks.size,
      net_line_delta: net_line_delta,
      hunks: hunks
    }
  rescue PatchParser::ParseError => e
    raise InvalidPatchError, e.message
  end

  private

  def validate_hunks(parsed_hunks)
    hunks = []
    net_line_delta = 0

    parsed_hunks.each do |parsed_hunk|
      hunk_lines = []

      parsed_hunk[:raw_lines].each do |current|
        if current == NO_NEWLINE_MARKER
          next
        end

        raise InvalidPatchError, "unsupported hunk metadata line" if current.start_with?("\\")

        prefix = current[0]
        raise InvalidPatchError, "unsupported hunk line prefix" unless [" ", "+", "-"].include?(prefix)

        hunk_lines << { op: prefix, text: current[1..] || "" }
      end

      validate_hunk_counts!(hunk_lines, parsed_hunk[:old_count], parsed_hunk[:new_count])

      hunks << {
        old_start: parsed_hunk[:old_start],
        old_count: parsed_hunk[:old_count],
        new_start: parsed_hunk[:new_start],
        new_count: parsed_hunk[:new_count],
        lines: hunk_lines
      }

      net_line_delta += (parsed_hunk[:new_count] - parsed_hunk[:old_count])
    end

    [hunks, net_line_delta]
  end

  def validate_hunk_counts!(hunk_lines, old_count, new_count)
    old_seen = hunk_lines.count { |line| line[:op] == " " || line[:op] == "-" }
    new_seen = hunk_lines.count { |line| line[:op] == " " || line[:op] == "+" }

    raise InvalidPatchError, "hunk line count does not match header" unless old_seen == old_count
    raise InvalidPatchError, "hunk line count does not match header" unless new_seen == new_count
  end
end
