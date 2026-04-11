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

def response_keys(response)
  return "(non-object response)" unless response.is_a?(Hash)

  keys = response.keys.sort
  return "(no keys)" if keys.empty?

  keys.join(", ")
end

def fetch_required(hash, key, context:)
  return hash.fetch(key) if hash.is_a?(Hash) && hash.key?(key)

  raise CliError, "#{context} missing #{key.inspect}; got keys: #{response_keys(hash)}"
end

def print_dry_run(response:, profile:)
  trace = fetch_required(response, "trace", context: "dry-run response")
  validation = fetch_required(trace, "validation", context: "dry-run trace")
  target = fetch_required(trace, "target", context: "dry-run trace")
  audit = fetch_required(trace, "audit", context: "dry-run trace")

  puts "Dry run"
  puts "Requested profile: #{profile || "default"}"
  puts "Resolved provider: #{fetch_required(trace, "provider", context: "dry-run trace")}"
  puts "Model: #{fetch_required(trace, "model", context: "dry-run trace")}"
  puts "Target path: #{fetch_required(target, "path", context: "dry-run target")}"
  puts "Validation: #{fetch_required(validation, "status", context: "dry-run validation")} (hunks=#{fetch_required(validation, "hunk_count", context: "dry-run validation")}, net_line_delta=#{fetch_required(validation, "net_line_delta", context: "dry-run validation")})"
  puts "Apply ready: #{fetch_required(trace, "apply_ready", context: "dry-run trace")}"
  puts "Patch:"
  puts fetch_required(audit, "patch", context: "dry-run audit")
end

def print_apply(response:)
  audit = fetch_required(response, "audit", context: "apply response")

  puts
  puts "Apply result"
  puts "Path: #{fetch_required(response, "path", context: "apply response")}"
  puts "Hunks: #{fetch_required(response, "hunk_count", context: "apply response")}"
  puts "Net line delta: #{fetch_required(response, "net_line_delta", context: "apply response")}"
  puts "Provider: #{fetch_required(audit, "provider", context: "apply audit")}"
  puts "Model: #{fetch_required(audit, "model", context: "apply audit")}"
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
