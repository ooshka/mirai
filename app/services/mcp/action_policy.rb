# frozen_string_literal: true

require_relative "identity_context"

module Mcp
  class ActionPolicy
    MODE_ALLOW_ALL = "allow_all"
    MODE_READ_ONLY = "read_only"
    SUPPORTED_MODES = [MODE_ALLOW_ALL, MODE_READ_ONLY].freeze

    ACTION_NOTES_LIST = "notes.list"
    ACTION_NOTES_READ = "notes.read"
    ACTION_PATCH_PROPOSE = "patch.propose"
    ACTION_PATCH_APPLY = "patch.apply"
    ACTION_INDEX_REBUILD = "index.rebuild"
    ACTION_INDEX_STATUS = "index.status"
    ACTION_INDEX_INVALIDATE = "index.invalidate"
    ACTION_INDEX_QUERY = "index.query"
    ACTION_WORKFLOW_PLAN = "workflow.plan"

    READ_ONLY_ALLOWED_ACTIONS = [
      ACTION_NOTES_LIST,
      ACTION_NOTES_READ,
      ACTION_INDEX_STATUS,
      ACTION_INDEX_QUERY,
      ACTION_WORKFLOW_PLAN
    ].freeze

    class DeniedError < StandardError
      attr_reader :action, :mode, :identity_context

      def initialize(action:, mode:, identity_context: nil)
        @action = action
        @mode = mode
        @identity_context = identity_context
        super("action #{action} is denied in #{mode} mode")
      end
    end

    class InvalidModeError < StandardError
      attr_reader :mode

      def initialize(mode)
        @mode = mode
        super("invalid MCP policy mode: #{mode}")
      end
    end

    def self.supported_modes
      SUPPORTED_MODES
    end

    def self.normalize_mode(mode)
      normalized = mode.to_s.strip
      return MODE_ALLOW_ALL if normalized.empty?
      return normalized if SUPPORTED_MODES.include?(normalized)

      raise InvalidModeError, normalized
    end

    def initialize(mode: MODE_ALLOW_ALL, identity_context: nil)
      @mode = self.class.normalize_mode(mode)
      @identity_context = identity_context
    end

    def enforce!(action, identity_context: nil)
      resolved_identity_context = resolve_identity_context(identity_context)

      return if allowed?(action, identity_context: resolved_identity_context)

      raise DeniedError.new(
        action: action,
        mode: @mode,
        identity_context: resolved_identity_context
      )
    end

    private

    def allowed?(action, identity_context: _identity_context)
      case @mode
      when MODE_ALLOW_ALL
        true
      when MODE_READ_ONLY
        READ_ONLY_ALLOWED_ACTIONS.include?(action)
      end
    end

    def resolve_identity_context(identity_context)
      identity_context || @identity_context || IdentityContext.runtime_agent
    end
  end
end
