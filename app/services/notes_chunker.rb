# frozen_string_literal: true

class NotesChunker
  DEFAULT_MAX_LINES = 20

  def initialize(max_lines: DEFAULT_MAX_LINES)
    @max_lines = max_lines
  end

  def chunk(content)
    lines = String(content).lines(chomp: true)
    return [] if lines.empty?

    lines.each_slice(@max_lines).map { |slice| slice.join("\n") }
  end
end
