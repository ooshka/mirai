# frozen_string_literal: true

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

    READ_ONLY_ALLOWED_ACTIONS = [
      ACTION_NOTES_LIST,
      ACTION_NOTES_READ,
      ACTION_INDEX_STATUS,
      ACTION_INDEX_QUERY
    ].freeze

    class DeniedError < StandardError
      attr_reader :action, :mode

      def initialize(action:, mode:)
        @action = action
        @mode = mode
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

    def initialize(mode: MODE_ALLOW_ALL)
      @mode = self.class.normalize_mode(mode)
    end

    def enforce!(action)
      raise DeniedError.new(action: action, mode: @mode) unless allowed?(action)
    end

    private

    def allowed?(action)
      case @mode
      when MODE_ALLOW_ALL
        true
      when MODE_READ_ONLY
        READ_ONLY_ALLOWED_ACTIONS.include?(action)
      end
    end
  end
end
