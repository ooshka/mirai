# frozen_string_literal: true

require_relative "../app/services/mcp/error_mapper"

RSpec.describe Mcp::ErrorMapper do
  it "maps invalid patch errors" do
    error = PatchValidator::InvalidPatchError.new("invalid patch header")

    expect(described_class.map(error)).to eq(
      {status: 400, code: "invalid_patch", message: "invalid patch header"}
    )
  end

  it "maps invalid path errors" do
    error = SafeNotesPath::InvalidPathError.new("path escapes notes root")

    expect(described_class.map(error)).to eq(
      {status: 400, code: "invalid_path", message: "path escapes notes root"}
    )
  end

  it "maps invalid extension errors" do
    error = SafeNotesPath::InvalidExtensionError.new("only .md files are allowed")

    expect(described_class.map(error)).to eq(
      {status: 400, code: "invalid_extension", message: "only .md files are allowed"}
    )
  end

  it "maps not found errors" do
    error = Errno::ENOENT.new("/notes/missing.md")

    expect(described_class.map(error)).to eq(
      {status: 404, code: "not_found", message: "note was not found"}
    )
  end

  it "maps conflict errors" do
    error = PatchApplier::ConflictError.new("patch does not apply cleanly")

    expect(described_class.map(error)).to eq(
      {status: 409, code: "conflict", message: "patch does not apply cleanly"}
    )
  end

  it "maps commit errors" do
    error = PatchApplier::CommitError.new("git failed")

    expect(described_class.map(error)).to eq(
      {status: 500, code: "git_error", message: "failed to commit patch"}
    )
  end

  it "maps invalid query errors" do
    error = Mcp::IndexQueryAction::InvalidQueryError.new("query is required")

    expect(described_class.map(error)).to eq(
      {status: 400, code: "invalid_query", message: "query is required"}
    )
  end

  it "maps invalid limit errors" do
    error = Mcp::IndexQueryAction::InvalidLimitError.new("limit must be an integer")

    expect(described_class.map(error)).to eq(
      {status: 400, code: "invalid_limit", message: "limit must be an integer"}
    )
  end

  it "maps invalid index artifact errors" do
    error = IndexStore::InvalidArtifactError.new("index artifact is invalid")

    expect(described_class.map(error)).to eq(
      {status: 500, code: "invalid_index_artifact", message: "index artifact is invalid"}
    )
  end

  it "returns nil for unknown errors" do
    expect(described_class.map(StandardError.new("no mapping"))).to be_nil
  end
end
