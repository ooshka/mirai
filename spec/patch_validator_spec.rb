# frozen_string_literal: true

require "tmpdir"
require_relative "../app/services/patch_validator"

RSpec.describe PatchValidator do
  around do |example|
    Dir.mktmpdir("notes-root") do |notes_root|
      @notes_root = notes_root
      example.run
    end
  end

  let(:validator) { described_class.new(notes_root: @notes_root) }

  it "accepts a single-file markdown unified diff" do
    patch = <<~PATCH
      --- a/notes/today.md
      +++ b/notes/today.md
      @@ -1 +1,2 @@
       hello
      +world
    PATCH

    result = validator.validate(patch)

    expect(result[:path]).to eq("notes/today.md")
    expect(result[:absolute_path]).to eq(File.join(@notes_root, "notes/today.md"))
    expect(result[:hunk_count]).to eq(1)
    expect(result[:net_line_delta]).to eq(1)
    expect(result[:hunks].size).to eq(1)
  end

  it "rejects traversal paths" do
    patch = <<~PATCH
      --- a/../secret.md
      +++ b/../secret.md
      @@ -1 +1 @@
      -x
      +y
    PATCH

    expect { validator.validate(patch) }
      .to raise_error(SafeNotesPath::InvalidPathError, "path escapes notes root")
  end

  it "rejects non-markdown files" do
    patch = <<~PATCH
      --- a/notes/today.txt
      +++ b/notes/today.txt
      @@ -1 +1 @@
      -x
      +y
    PATCH

    expect { validator.validate(patch) }
      .to raise_error(SafeNotesPath::InvalidExtensionError, "only .md files are allowed")
  end

  it "rejects absolute paths" do
    patch = <<~PATCH
      --- a//etc/passwd.md
      +++ b//etc/passwd.md
      @@ -1 +1 @@
      -x
      +y
    PATCH

    expect { validator.validate(patch) }
      .to raise_error(SafeNotesPath::InvalidPathError, "absolute paths are not allowed")
  end

  it "rejects multi-file patches" do
    patch = <<~PATCH
      --- a/one.md
      +++ b/one.md
      @@ -1 +1 @@
      -x
      +y
      --- a/two.md
      +++ b/two.md
      @@ -1 +1 @@
      -a
      +b
    PATCH

    expect { validator.validate(patch) }
      .to raise_error(PatchValidator::InvalidPatchError, "only single-file patches are supported")
  end

  it "rejects malformed hunks" do
    patch = <<~PATCH
      --- a/notes/today.md
      +++ b/notes/today.md
      @@ -1 +1 @@
      ?bad
    PATCH

    expect { validator.validate(patch) }
      .to raise_error(PatchValidator::InvalidPatchError, "unsupported hunk line prefix")
  end

  it "rejects malformed hunk headers" do
    patch = <<~PATCH
      --- a/notes/today.md
      +++ b/notes/today.md
      @@ bad @@
      -alpha
      +beta
    PATCH

    expect { validator.validate(patch) }
      .to raise_error(PatchValidator::InvalidPatchError, "invalid hunk header")
  end

  it "accepts no-newline marker metadata lines" do
    patch = <<~'PATCH'
      --- a/notes/today.md
      +++ b/notes/today.md
      @@ -1 +1 @@
      -alpha
      \ No newline at end of file
      +beta
      \ No newline at end of file
    PATCH

    result = validator.validate(patch)

    expect(result[:path]).to eq("notes/today.md")
    expect(result[:hunk_count]).to eq(1)
    expect(result[:net_line_delta]).to eq(0)
    expect(result[:hunks]).to eq(
      [
        {
          old_start: 1,
          old_count: 1,
          new_start: 1,
          new_count: 1,
          lines: [
            {op: "-", text: "alpha"},
            {op: "+", text: "beta"}
          ]
        }
      ]
    )
  end

  it "rejects unknown hunk metadata lines" do
    patch = <<~'PATCH'
      --- a/notes/today.md
      +++ b/notes/today.md
      @@ -1 +1 @@
      -alpha
      \ unsupported metadata
      +beta
    PATCH

    expect { validator.validate(patch) }
      .to raise_error(PatchValidator::InvalidPatchError, "unsupported hunk metadata line")
  end
end
