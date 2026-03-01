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
require_relative "app/routes/core_routes"
require_relative "app/routes/mcp_routes"

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

  register Routes::Core
  register Routes::Mcp
end
