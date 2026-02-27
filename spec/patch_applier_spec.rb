# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require "open3"
require_relative "../app/services/patch_applier"

RSpec.describe PatchApplier do
  around do |example|
    Dir.mktmpdir("notes-root") do |notes_root|
      @notes_root = notes_root
      init_git_repo
      example.run
    end
  end

  let(:applier) { described_class.new(notes_root: @notes_root) }

  it "applies a valid patch to a markdown note" do
    FileUtils.mkdir_p(File.join(@notes_root, "notes"))
    file_path = File.join(@notes_root, "notes/today.md")
    File.write(file_path, "line one\nline two\n")
    git!("add", "notes/today.md")
    git!("commit", "-m", "Seed note")

    patch = <<~PATCH
      --- a/notes/today.md
      +++ b/notes/today.md
      @@ -1,2 +1,3 @@
       line one
       line two
      +line three
    PATCH

    result = applier.apply(patch)

    expect(result[:path]).to eq("notes/today.md")
    expect(result[:hunk_count]).to eq(1)
    expect(result[:net_line_delta]).to eq(1)
    expect(File.read(file_path)).to eq("line one\nline two\nline three\n")
    expect(git!("log", "--format=%s", "-n", "1", "--", "notes/today.md").strip)
      .to eq("Apply patch to notes/today.md")
  end

  it "raises not found when target note does not exist" do
    patch = <<~PATCH
      --- a/notes/missing.md
      +++ b/notes/missing.md
      @@ -1 +1 @@
      -x
      +y
    PATCH

    expect { applier.apply(patch) }
      .to raise_error(Errno::ENOENT)
  end

  it "raises conflict when context does not match" do
    FileUtils.mkdir_p(File.join(@notes_root, "notes"))
    file_path = File.join(@notes_root, "notes/today.md")
    File.write(file_path, "current\n")

    patch = <<~PATCH
      --- a/notes/today.md
      +++ b/notes/today.md
      @@ -1 +1 @@
      -expected
      +updated
    PATCH

    expect { applier.apply(patch) }
      .to raise_error(PatchApplier::ConflictError)
    expect(File.read(file_path)).to eq("current\n")
  end

  it "raises commit error when git commit cannot run" do
    FileUtils.mkdir_p(File.join(@notes_root, "notes"))
    file_path = File.join(@notes_root, "notes/today.md")
    File.write(file_path, "alpha\n")
    git!("add", "notes/today.md")
    git!("commit", "-m", "Seed note")
    FileUtils.rm_rf(File.join(@notes_root, ".git"))

    patch = <<~PATCH
      --- a/notes/today.md
      +++ b/notes/today.md
      @@ -1 +1,2 @@
       alpha
      +beta
    PATCH

    expect { applier.apply(patch) }
      .to raise_error(PatchApplier::CommitError)
    expect(File.read(file_path)).to eq("alpha\n")
  end

  def init_git_repo
    git!("init")
    git!("config", "user.email", "agent@example.com")
    git!("config", "user.name", "Agent")
  end

  def git!(*args)
    stdout, stderr, status = Open3.capture3("git", *args, chdir: @notes_root)
    raise "git command failed: git #{args.join(' ')}\n#{stderr}" unless status.success?

    stdout
  end
end
