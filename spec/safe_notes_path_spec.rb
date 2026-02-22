# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require_relative "../app/services/safe_notes_path"

RSpec.describe SafeNotesPath do
  around do |example|
    Dir.mktmpdir("notes-root") do |notes_root|
      @notes_root = notes_root
      example.run
    end
  end

  let(:safe_path) { described_class.new(notes_root: @notes_root) }

  it "resolves a relative markdown path under notes root" do
    resolved = safe_path.resolve("projects/todo.md")

    expect(resolved).to eq(File.join(@notes_root, "projects/todo.md"))
  end

  it "rejects traversal outside notes root" do
    expect { safe_path.resolve("../outside.md") }
      .to raise_error(SafeNotesPath::InvalidPathError, "path escapes notes root")
  end

  it "rejects absolute paths" do
    expect { safe_path.resolve("/etc/passwd.md") }
      .to raise_error(SafeNotesPath::InvalidPathError, "absolute paths are not allowed")
  end

  it "rejects non-markdown files" do
    expect { safe_path.resolve("projects/todo.txt") }
      .to raise_error(SafeNotesPath::InvalidExtensionError, "only .md files are allowed")
  end

  it "lists markdown files as relative paths" do
    File.write(File.join(@notes_root, "root.md"), "root")
    FileUtils.mkdir_p(File.join(@notes_root, "nested"))
    File.write(File.join(@notes_root, "nested/child.md"), "child")
    File.write(File.join(@notes_root, "nested/ignore.txt"), "ignore")

    expect(safe_path.list_markdown_files).to eq(["nested/child.md", "root.md"])
  end

  it "rejects symlink paths that resolve outside notes root" do
    Dir.mktmpdir("outside-notes-root") do |outside_root|
      outside_file = File.join(outside_root, "secret.md")
      File.write(outside_file, "secret")

      link_path = File.join(@notes_root, "escaped.md")
      File.symlink(outside_file, link_path)

      expect { safe_path.resolve("escaped.md") }
        .to raise_error(SafeNotesPath::InvalidPathError, "path escapes notes root")
    end
  end
end
