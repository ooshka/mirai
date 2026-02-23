# frozen_string_literal: true

require "pathname"

class SafeNotesPath
  class InvalidPathError < StandardError; end
  class InvalidExtensionError < StandardError; end

  def initialize(notes_root:)
    @notes_root = File.expand_path(notes_root)
    @notes_root_realpath = Pathname.new(@notes_root).realpath.to_s
  end

  def resolve(untrusted_path)
    value = String(untrusted_path).strip
    raise InvalidPathError, "path is required" if value.empty?
    raise InvalidPathError, "absolute paths are not allowed" if Pathname.new(value).absolute?

    absolute_path = File.expand_path(value, @notes_root)
    raise InvalidPathError, "path escapes notes root" unless contained?(absolute_path)
    raise InvalidExtensionError, "only .md files are allowed" unless markdown_file?(absolute_path)

    absolute_path
  rescue TypeError
    raise InvalidPathError, "path is required"
  end

  def list_markdown_files
    Dir.glob(File.join(@notes_root, "**", "*.md")).sort.filter_map do |absolute_path|
      next unless File.file?(absolute_path)

      Pathname.new(absolute_path).relative_path_from(Pathname.new(@notes_root)).to_s
    end
  end

  private

  def contained?(absolute_path)
    return false unless absolute_path.start_with?("#{@notes_root}/")

    candidate = canonical_candidate_path(absolute_path)
    candidate == @notes_root_realpath || candidate.start_with?("#{@notes_root_realpath}/")
  rescue Errno::ENOENT, Errno::EACCES
    false
  end

  def canonical_candidate_path(absolute_path)
    pathname = Pathname.new(absolute_path)
    return pathname.realpath.to_s if pathname.exist?

    # Preserve missing-file semantics (404) while still canonicalizing existing parents.
    parent = pathname.dirname
    return absolute_path unless parent.exist?

    parent.realpath.join(pathname.basename).to_s
  end

  def markdown_file?(absolute_path)
    File.extname(absolute_path).downcase == ".md"
  end
end
