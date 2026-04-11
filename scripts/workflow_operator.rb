#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "net/http"
require "optparse"
require "uri"

DEFAULT_BASE_URL = ENV.fetch("BASE_URL", "http://localhost:4567")
SUPPORTED_PROFILES = %w[local hosted auto].freeze

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
    profile: nil,
    apply: false,
    confirm_apply: true
  }

  parser = OptionParser.new do |opts|
    opts.banner = "Usage: ruby scripts/workflow_operator.rb --instruction TEXT --path NOTE_PATH [options]"

    opts.on("--instruction TEXT", "Workflow instruction to draft/apply") do |value|
      options[:instruction] = value
    end

    opts.on("--path NOTE_PATH", "Repo-relative markdown path") do |value|
      options[:path] = value
    end

    opts.on("--base-url URL", "mirai base URL (default: #{options[:base_url]})") do |value|
      options[:base_url] = value
    end

    opts.on("--profile PROFILE", SUPPORTED_PROFILES, "Workflow profile (#{SUPPORTED_PROFILES.join(", ")})") do |value|
      options[:profile] = value
    end

    opts.on("--context JSON", "Optional JSON object passed to params.context") do |value|
      options[:context] = value
    end

    opts.on("--apply", "Apply after dry-run (prompts unless --yes is also set)") do
      options[:apply] = true
    end

    opts.on("--yes", "Skip the apply confirmation prompt") do
      options[:confirm_apply] = false
    end
  end

  parser.parse!(argv)
  [options, parser]
rescue OptionParser::ParseError => e
  raise CliError, e.message
end

def validate_options!(options, parser)
  instruction = normalize_string(options[:instruction])
  raise CliError, parser.to_s if instruction.nil?

  path = normalize_string(options[:path])
  raise CliError, parser.to_s if path.nil?

  context =
    if options[:context]
      parsed = JSON.parse(options[:context])
      raise CliError, "--context must decode to a JSON object" unless parsed.is_a?(Hash)

      parsed
    end

  {
    instruction: instruction,
    path: path,
    base_url: normalize_string(options[:base_url]) || DEFAULT_BASE_URL,
    profile: options[:profile],
    context: context,
    apply: options[:apply],
    confirm_apply: options[:confirm_apply]
  }
rescue JSON::ParserError => e
  raise CliError, "--context must be valid JSON: #{e.message}"
end

def request_payload(options)
  params = {
    instruction: options.fetch(:instruction),
    path: options.fetch(:path)
  }
  params[:context] = options[:context] unless options[:context].nil?
  params[:profile] = options[:profile] unless options[:profile].nil?

  {
    action: "workflow.draft_patch",
    params: params
  }
end

def post_json(base_url:, path:, payload:)
  uri = URI.join("#{base_url}/", path.sub(%r{\A/}, ""))
  request = Net::HTTP::Post.new(uri)
  request["Content-Type"] = "application/json"
  request.body = JSON.generate(payload)

  response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
    http.request(request)
  end

  body = response.body.to_s
  parsed = body.empty? ? {} : JSON.parse(body)
  return parsed if response.is_a?(Net::HTTPSuccess)

  error = parsed["error"] if parsed.is_a?(Hash)
  raise CliError, "#{path} failed: #{error.fetch("code")}: #{error.fetch("message")}" if error.is_a?(Hash)

  raise CliError, "#{path} failed with status #{response.code}"
rescue JSON::ParserError => e
  raise CliError, "#{path} returned invalid JSON: #{e.message}"
rescue SocketError, SystemCallError, IOError => e
  raise CliError, "#{path} request failed: #{e.message}"
end

def print_dry_run(response:, profile:)
  trace = response.fetch("trace")
  validation = trace.fetch("validation")
  target = trace.fetch("target")
  audit = trace.fetch("audit")

  puts "Dry run"
  puts "Requested profile: #{profile || "default"}"
  puts "Resolved provider: #{trace.fetch("provider")}"
  puts "Model: #{trace.fetch("model")}"
  puts "Target path: #{target.fetch("path")}"
  puts "Validation: #{validation.fetch("status")} (hunks=#{validation.fetch("hunk_count")}, net_line_delta=#{validation.fetch("net_line_delta")})"
  puts "Apply ready: #{trace.fetch("apply_ready")}"
  puts "Patch:"
  puts audit.fetch("patch")
end

def print_apply(response:)
  audit = response.fetch("audit")

  puts
  puts "Apply result"
  puts "Path: #{response.fetch("path")}"
  puts "Hunks: #{response.fetch("hunk_count")}"
  puts "Net line delta: #{response.fetch("net_line_delta")}"
  puts "Provider: #{audit.fetch("provider")}"
  puts "Model: #{audit.fetch("model")}"
end

def confirm_apply!
  print "Apply patch? [y/N]: "
  answer = $stdin.gets
  answer&.strip&.downcase == "y"
end

def main(argv)
  options, parser = parse_options(argv)
  validated = validate_options!(options, parser)
  payload = request_payload(validated)

  dry_run = post_json(
    base_url: validated.fetch(:base_url),
    path: "/mcp/workflow/draft_patch",
    payload: payload
  )
  print_dry_run(response: dry_run, profile: validated[:profile])

  return 0 unless validated.fetch(:apply)
  return 0 if validated.fetch(:confirm_apply) && !confirm_apply!

  apply = post_json(
    base_url: validated.fetch(:base_url),
    path: "/mcp/workflow/apply_patch",
    payload: payload
  )
  print_apply(response: apply)
  0
rescue CliError => e
  warn e.message
  1
end

exit(main(ARGV))
