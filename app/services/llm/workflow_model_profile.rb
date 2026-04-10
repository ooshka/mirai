# frozen_string_literal: true

require_relative "workflow_patch_drafter"
require_relative "workflow_planner"

module Llm
  class WorkflowModelProfile
    HOSTED_PROFILE = "hosted"
    LOCAL_PROFILE = "local"
    AUTO_PROFILE = "auto"
    SUPPORTED_PROFILES = [HOSTED_PROFILE, LOCAL_PROFILE, AUTO_PROFILE].freeze

    class InvalidProfileError < StandardError; end

    Result = Struct.new(:profile, :planner_provider, :drafter_provider, keyword_init: true)

    def self.resolve!(profile:, default_planner_provider:, default_drafter_provider:)
      normalized = normalize_profile(profile)
      normalized_planner_provider = WorkflowPlanner.normalize_provider!(default_planner_provider)
      normalized_drafter_provider = WorkflowPatchDrafter.normalize_provider!(default_drafter_provider)

      case normalized
      when nil
        Result.new(
          profile: nil,
          planner_provider: normalized_planner_provider,
          drafter_provider: normalized_drafter_provider
        )
      when HOSTED_PROFILE
        Result.new(
          profile: HOSTED_PROFILE,
          planner_provider: WorkflowPlanner::DEFAULT_PROVIDER,
          drafter_provider: WorkflowPatchDrafter::DEFAULT_PROVIDER
        )
      when LOCAL_PROFILE
        Result.new(
          profile: LOCAL_PROFILE,
          planner_provider: WorkflowPlanner::LOCAL_PROVIDER,
          drafter_provider: WorkflowPatchDrafter::LOCAL_PROVIDER
        )
      when AUTO_PROFILE
        Result.new(
          profile: AUTO_PROFILE,
          planner_provider: normalized_planner_provider,
          drafter_provider: normalized_drafter_provider
        )
      else
        raise InvalidProfileError, "workflow model profile must be hosted, local, or auto"
      end
    end

    def self.normalize_profile(profile)
      return nil if profile.nil?
      raise InvalidProfileError, "workflow model profile must be a string" unless profile.is_a?(String)

      normalized = profile.strip
      return nil if normalized.empty?

      normalized
    end
    private_class_method :normalize_profile
  end
end
