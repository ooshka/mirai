# frozen_string_literal: true

require "sinatra/base"
require "json"
require_relative "app/services/notes_reader"
require_relative "app/services/safe_notes_path"
require_relative "app/services/patch_validator"
require_relative "app/services/patch_applier"
require_relative "app/services/runtime_config"
require_relative "app/services/mcp/action_policy"
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
require_relative "app/routes/mcp_helpers"

class App < Sinatra::Base
  set :bind, "0.0.0.0"
  set :port, (ENV["PORT"] || "4567").to_i

  configure do
    runtime_config = RuntimeConfig.from_env
    set :notes_root, runtime_config.notes_root
    set :mcp_policy_mode, runtime_config.mcp_policy_mode
    set :mcp_retrieval_mode, runtime_config.mcp_retrieval_mode
    set :mcp_semantic_provider_enabled, runtime_config.mcp_semantic_provider_enabled
  end

  before do
    content_type :json
  end

  helpers Routes::McpHelpers

  register Routes::Core
  register Routes::Mcp
end
