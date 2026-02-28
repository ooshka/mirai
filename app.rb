# frozen_string_literal: true

require "sinatra/base"
require "json"
require_relative "app/services/notes_reader"
require_relative "app/services/safe_notes_path"
require_relative "app/services/patch_validator"
require_relative "app/services/patch_applier"
require_relative "app/services/mcp/error_mapper"
require_relative "app/services/mcp/notes_list_action"
require_relative "app/services/mcp/notes_read_action"
require_relative "app/services/mcp/patch_propose_action"
require_relative "app/services/mcp/patch_apply_action"
require_relative "app/services/mcp/index_rebuild_action"
require_relative "app/services/mcp/index_query_action"
require_relative "app/services/mcp/index_status_action"
require_relative "app/services/mcp/index_invalidate_action"

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
      halt status, {error: {code: code, message: message}}.to_json
    end

    def parsed_patch_payload
      request.body.rewind
      payload = JSON.parse(request.body.read)
      render_error(400, "invalid_patch", "patch is required") unless payload.is_a?(Hash)

      payload
    rescue JSON::ParserError
      render_error(400, "invalid_patch", "patch is required")
    end

    def with_mcp_error_handling
      yield
    rescue => e
      mapped = Mcp::ErrorMapper.map(e)
      raise unless mapped

      render_error(mapped[:status], mapped[:code], mapped[:message])
    end
  end

  get "/health" do
    {ok: true}.to_json
  end

  get "/config" do
    {notes_root: settings.notes_root}.to_json
  end

  get "/mcp/notes" do
    with_mcp_error_handling do
      Mcp::NotesListAction.new(notes_root: settings.notes_root).call.to_json
    end
  end

  get "/mcp/notes/read" do
    with_mcp_error_handling do
      Mcp::NotesReadAction.new(notes_root: settings.notes_root).call(path: params["path"]).to_json
    end
  end

  post "/mcp/patch/propose" do
    payload = parsed_patch_payload
    with_mcp_error_handling do
      Mcp::PatchProposeAction.new(notes_root: settings.notes_root).call(patch: payload["patch"]).to_json
    end
  end

  post "/mcp/patch/apply" do
    payload = parsed_patch_payload
    with_mcp_error_handling do
      Mcp::PatchApplyAction.new(notes_root: settings.notes_root).call(patch: payload["patch"]).to_json
    end
  end

  post "/mcp/index/rebuild" do
    with_mcp_error_handling do
      Mcp::IndexRebuildAction.new(notes_root: settings.notes_root).call.to_json
    end
  end

  get "/mcp/index/status" do
    with_mcp_error_handling do
      Mcp::IndexStatusAction.new(notes_root: settings.notes_root).call.to_json
    end
  end

  post "/mcp/index/invalidate" do
    with_mcp_error_handling do
      Mcp::IndexInvalidateAction.new(notes_root: settings.notes_root).call.to_json
    end
  end

  get "/mcp/index/query" do
    with_mcp_error_handling do
      Mcp::IndexQueryAction.new(notes_root: settings.notes_root)
        .call(query: params["q"], limit: params["limit"])
        .to_json
    end
  end
end
