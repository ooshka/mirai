#!/usr/bin/env ruby
# frozen_string_literal: true

require "open3"
require "optparse"
require "rbconfig"
require "shellwords"

DEFAULT_BASE_URL = ENV.fetch("BASE_URL", "http://localhost:4567")
DEFAULT_LOCAL_INSTRUCTION = "Add a short operator scenario note for the local profile."
DEFAULT_HOSTED_INSTRUCTION = "Add a short operator scenario note for the hosted profile."
SUPPORTED_PROFILES = %w[local hosted].freeze

class CliError < StandardError; end

def normalize_string(value)
  return nil if value.nil?

  normalized = value.to_s.strip
  return nil if normalized.empty?

  normalized
end

def parse_options(argv)
  options = {
    base_url: DEFAULT_BASE_URL,
    local_instruction: DEFAULT_LOCAL_INSTRUCTION,
    hosted_instruction: DEFAULT_HOSTED_INSTRUCTION,
    include_apply: false,
    apply_profile: "local",
    confirm_apply: true
  }

  parser = OptionParser.new do |opts|
    opts.banner = "Usage: ruby scripts/workflow_operator_mvp_scenarios.rb --path NOTE_PATH [options]"

    opts.on("--path NOTE_PATH", "Repo-relative markdown note path used for all scenarios") do |value|
      options[:path] = value
    end

    opts.on("--base-url URL", "mirai base URL (default: #{options[:base_url]})") do |value|
      options[:base_url] = value
    end

    opts.on("--local-instruction TEXT", "Instruction for the local-profile scenario") do |value|
      options[:local_instruction] = value
    end

    opts.on("--hosted-instruction TEXT", "Instruction for the hosted-profile scenario") do |value|
      options[:hosted_instruction] = value
    end

    opts.on("--include-apply", "Run one explicit apply scenario after the dry-run scenarios") do
      options[:include_apply] = true
    end

    opts.on("--apply-profile PROFILE", SUPPORTED_PROFILES, "Profile used for the optional apply scenario") do |value|
      options[:apply_profile] = value
    end

    opts.on("--yes", "Skip the apply confirmation prompt for the optional apply scenario") do
      options[:confirm_apply] = false
    end
  end

  parser.parse!(argv)
  [options, parser]
rescue OptionParser::ParseError => e
  raise CliError, e.message
end

def validate_options!(options, parser)
  path = normalize_string(options[:path])
  raise CliError, parser.to_s if path.nil?

  {
    path: path,
    base_url: normalize_string(options[:base_url]) || DEFAULT_BASE_URL,
    local_instruction: normalize_string(options[:local_instruction]) || DEFAULT_LOCAL_INSTRUCTION,
    hosted_instruction: normalize_string(options[:hosted_instruction]) || DEFAULT_HOSTED_INSTRUCTION,
    include_apply: options[:include_apply],
    apply_profile: options[:apply_profile],
    confirm_apply: options[:confirm_apply]
  }
end

def workflow_operator_path
  File.expand_path("workflow_operator.rb", __dir__)
end

def scenario_heading(title)
  puts
  puts "== #{title} =="
end

def print_checklist(profile:, apply:)
  puts "Inspect before continuing:"
  puts "- Requested profile: #{profile}"
  puts "- Resolved provider and model in the dry-run trace"
  puts "- Target path matches the intended note"
  puts "- Validation status and apply readiness are both acceptable"
  puts "- Patch output matches the intended note update"
  puts "- Apply remains explicit#{apply ? " for this scenario" : " unless you rerun with --include-apply"}"
end

def run_operator(base_url:, path:, instruction:, profile:, apply:, confirm_apply:)
  command = [
    RbConfig.ruby,
    workflow_operator_path,
    "--instruction", instruction,
    "--path", path,
    "--profile", profile,
    "--base-url", base_url
  ]

  if apply
    command << "--apply"
    command << "--yes" unless confirm_apply
  end

  puts "$ #{command.shelljoin}"
  stdout, stderr, status = Open3.capture3(*command)
  print stdout
  warn stderr unless stderr.empty?
  raise CliError, "scenario failed for profile #{profile}" unless status.success?
end

def instruction_for_profile(options, profile)
  case profile
  when "local"
    options.fetch(:local_instruction)
  when "hosted"
    options.fetch(:hosted_instruction)
  else
    raise CliError, "unsupported profile #{profile.inspect}"
  end
end

def run_scenarios(options)
  puts "Workflow operator MVP scenario pack"
  puts "Base URL: #{options.fetch(:base_url)}"
  puts "Target path: #{options.fetch(:path)}"
  puts "This pack stays profile-based and does not assert model-specific quality."

  %w[local hosted].each do |profile|
    scenario_heading("#{profile} dry run")
    print_checklist(profile: profile, apply: false)
    run_operator(
      base_url: options.fetch(:base_url),
      path: options.fetch(:path),
      instruction: instruction_for_profile(options, profile),
      profile: profile,
      apply: false,
      confirm_apply: true
    )
  end

  return unless options.fetch(:include_apply)

  apply_profile = options.fetch(:apply_profile)
  scenario_heading("#{apply_profile} explicit apply")
  print_checklist(profile: apply_profile, apply: true)
  run_operator(
    base_url: options.fetch(:base_url),
    path: options.fetch(:path),
    instruction: instruction_for_profile(options, apply_profile),
    profile: apply_profile,
    apply: true,
    confirm_apply: options.fetch(:confirm_apply)
  )
end

def main(argv)
  options, parser = parse_options(argv)
  validated = validate_options!(options, parser)
  run_scenarios(validated)
  0
rescue CliError => e
  warn e.message
  1
end

exit(main(ARGV))
