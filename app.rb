# frozen_string_literal: true

require "sinatra/base"
require "json"
require_relative "app/services/notes_reader"
require_relative "app/services/safe_notes_path"
require_relative "app/services/patch_validator"
require_relative "app/services/patch_applier"

class App < Sinatra::Base
  set :bind, "0.0.0.0"
  set :port, (ENV["PORT"] || "4567").to_i
  
  configure do
    set :notes_root, ENV.fetch("NOTES_ROOT", "/notes")
  end

  before do
    content_type :json
  end

  helpers do
    def render_error(status, code, message)
      halt status, { error: { code: code, message: message } }.to_json
    end

    def parsed_patch_payload
      request.body.rewind
      payload = JSON.parse(request.body.read)
      render_error(400, "invalid_patch", "patch is required") unless payload.is_a?(Hash)

      payload
    rescue JSON::ParserError
      render_error(400, "invalid_patch", "patch is required")
    end
  end

  get "/health" do
    { ok: true }.to_json
  end

  get "/config" do
    { notes_root: settings.notes_root }.to_json
  end

  get "/mcp/notes" do
    reader = NotesReader.new(notes_root: settings.notes_root)
    { notes: reader.list_notes }.to_json
  end

  get "/mcp/notes/read" do
    reader = NotesReader.new(notes_root: settings.notes_root)
    { path: params["path"], content: reader.read_note(params["path"]) }.to_json
  rescue SafeNotesPath::InvalidPathError => e
    render_error(400, "invalid_path", e.message)
  rescue SafeNotesPath::InvalidExtensionError => e
    render_error(400, "invalid_extension", e.message)
  rescue Errno::ENOENT
    render_error(404, "not_found", "note was not found")
  end

  post "/mcp/patch/propose" do
    payload = parsed_patch_payload
    validator = PatchValidator.new(notes_root: settings.notes_root)
    result = validator.validate(payload["patch"])
    result.slice(:path, :hunk_count, :net_line_delta).to_json
  rescue PatchValidator::InvalidPatchError => e
    render_error(400, "invalid_patch", e.message)
  rescue SafeNotesPath::InvalidPathError => e
    render_error(400, "invalid_path", e.message)
  rescue SafeNotesPath::InvalidExtensionError => e
    render_error(400, "invalid_extension", e.message)
  end

  post "/mcp/patch/apply" do
    payload = parsed_patch_payload
    applier = PatchApplier.new(notes_root: settings.notes_root)
    applier.apply(payload["patch"]).to_json
  rescue PatchValidator::InvalidPatchError => e
    render_error(400, "invalid_patch", e.message)
  rescue SafeNotesPath::InvalidPathError => e
    render_error(400, "invalid_path", e.message)
  rescue SafeNotesPath::InvalidExtensionError => e
    render_error(400, "invalid_extension", e.message)
  rescue Errno::ENOENT
    render_error(404, "not_found", "note was not found")
  rescue PatchApplier::ConflictError => e
    render_error(409, "conflict", e.message)
  rescue PatchApplier::CommitError
    render_error(500, "git_error", "failed to commit patch")
  end
end
