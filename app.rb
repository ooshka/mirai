# frozen_string_literal: true

require "sinatra/base"
require "json"
require_relative "app/services/notes_reader"
require_relative "app/services/safe_notes_path"

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
end
