# frozen_string_literal: true

require_relative "../safe_notes_path"
require_relative "../patch_validator"
require_relative "../patch_applier"
require_relative "index_query_action"

module Mcp
  class ErrorMapper
    def self.map(error)
      case error
      when PatchValidator::InvalidPatchError
        {status: 400, code: "invalid_patch", message: error.message}
      when SafeNotesPath::InvalidPathError
        {status: 400, code: "invalid_path", message: error.message}
      when SafeNotesPath::InvalidExtensionError
        {status: 400, code: "invalid_extension", message: error.message}
      when Errno::ENOENT
        {status: 404, code: "not_found", message: "note was not found"}
      when PatchApplier::ConflictError
        {status: 409, code: "conflict", message: error.message}
      when PatchApplier::CommitError
        {status: 500, code: "git_error", message: "failed to commit patch"}
      when Mcp::IndexQueryAction::InvalidQueryError
        {status: 400, code: "invalid_query", message: error.message}
      when Mcp::IndexQueryAction::InvalidLimitError
        {status: 400, code: "invalid_limit", message: error.message}
      end
    end
  end
end
