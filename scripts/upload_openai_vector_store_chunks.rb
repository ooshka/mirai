#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "net/http"
require "optparse"
require "securerandom"
require "time"
require "uri"
require "tmpdir"

require_relative "../app/services/indexing/notes_indexer"

DEFAULT_BASE_URL = "https://api.openai.com"
DEFAULT_NOTES_ROOT = File.expand_path("../notes_repo/notes", __dir__)
DEFAULT_MANIFEST_PATH = File.expand_path("../tmp/vector_store_upload_manifest.json", __dir__)

def normalize_string(value)
  return nil if value.nil?

  normalized = value.to_s.strip
  return nil if normalized.empty?

  normalized
end

def parse_options(argv)
  options = {
    notes_root: ENV.fetch("NOTES_ROOT", DEFAULT_NOTES_ROOT),
    vector_store_id: ENV["MCP_OPENAI_VECTOR_STORE_ID"],
    api_key: ENV["OPENAI_API_KEY"],
    base_url: ENV.fetch("MCP_OPENAI_BASE_URL", DEFAULT_BASE_URL),
    manifest_path: ENV.fetch("VECTOR_UPLOAD_MANIFEST_PATH", DEFAULT_MANIFEST_PATH),
    dry_run: false,
    max_chunks: nil,
    path_prefix: nil
  }

  parser = OptionParser.new do |opts|
    opts.banner = "Usage: ruby scripts/upload_openai_vector_store_chunks.rb [options]"

    opts.on("--notes-root PATH", "Notes root (default: #{options[:notes_root]})") do |value|
      options[:notes_root] = value
    end

    opts.on("--vector-store-id ID", "OpenAI vector store id (default: MCP_OPENAI_VECTOR_STORE_ID)") do |value|
      options[:vector_store_id] = value
    end

    opts.on("--api-key KEY", "OpenAI API key (default: OPENAI_API_KEY)") do |value|
      options[:api_key] = value
    end

    opts.on("--base-url URL", "OpenAI base URL (default: #{options[:base_url]})") do |value|
      options[:base_url] = value
    end

    opts.on("--path-prefix PREFIX", "Only upload chunks whose path starts with PREFIX") do |value|
      options[:path_prefix] = value
    end

    opts.on("--max-chunks N", Integer, "Upload at most N chunks") do |value|
      options[:max_chunks] = value
    end

    opts.on("--manifest PATH", "Write upload manifest JSON to PATH") do |value|
      options[:manifest_path] = value
    end

    opts.on("--dry-run", "Print chunk plan without uploading") do
      options[:dry_run] = true
    end
  end

  parser.parse!(argv)
  options
end

def validate_options!(options)
  notes_root = normalize_string(options[:notes_root])
  raise ArgumentError, "notes root is required" if notes_root.nil?
  raise ArgumentError, "notes root does not exist: #{notes_root}" unless Dir.exist?(notes_root)

  vector_store_id = normalize_string(options[:vector_store_id])
  raise ArgumentError, "vector store id is required (--vector-store-id or MCP_OPENAI_VECTOR_STORE_ID)" if vector_store_id.nil?

  api_key = normalize_string(options[:api_key])
  raise ArgumentError, "api key is required (--api-key or OPENAI_API_KEY)" if api_key.nil?

  base_url = normalize_string(options[:base_url]) || DEFAULT_BASE_URL
  manifest_path = normalize_string(options[:manifest_path]) || DEFAULT_MANIFEST_PATH
  max_chunks = options[:max_chunks]
  raise ArgumentError, "max chunks must be positive" if !max_chunks.nil? && max_chunks <= 0

  {
    notes_root: notes_root,
    vector_store_id: vector_store_id,
    api_key: api_key,
    base_url: base_url,
    manifest_path: manifest_path,
    dry_run: options[:dry_run],
    max_chunks: max_chunks,
    path_prefix: normalize_string(options[:path_prefix])
  }
end

def post_json(base_url:, path:, api_key:, payload:)
  uri = URI.join(base_url, path)
  request = Net::HTTP::Post.new(uri)
  request["Authorization"] = "Bearer #{api_key}"
  request["Content-Type"] = "application/json"
  request.body = JSON.generate(payload)

  response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
    http.request(request)
  end

  unless response.is_a?(Net::HTTPSuccess)
    raise "openai request failed (#{path}) status=#{response.code} body=#{response.body}"
  end

  JSON.parse(response.body)
rescue JSON::ParserError => e
  raise "openai response parse error (#{path}): #{e.message}"
end

def post_file(base_url:, path:, api_key:, file_path:, purpose:)
  uri = URI.join(base_url, path)
  boundary = "----mirai-#{SecureRandom.hex(16)}"
  file_name = File.basename(file_path)
  file_bytes = File.binread(file_path)

  body = +""
  body << "--#{boundary}\r\n"
  body << "Content-Disposition: form-data; name=\"purpose\"\r\n\r\n"
  body << "#{purpose}\r\n"
  body << "--#{boundary}\r\n"
  body << "Content-Disposition: form-data; name=\"file\"; filename=\"#{file_name}\"\r\n"
  body << "Content-Type: text/plain\r\n\r\n"
  body << file_bytes
  body << "\r\n--#{boundary}--\r\n"

  request = Net::HTTP::Post.new(uri)
  request["Authorization"] = "Bearer #{api_key}"
  request["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
  request.body = body

  response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
    http.request(request)
  end

  unless response.is_a?(Net::HTTPSuccess)
    raise "openai file upload failed status=#{response.code} body=#{response.body}"
  end

  JSON.parse(response.body)
rescue JSON::ParserError => e
  raise "openai file upload parse error: #{e.message}"
end

def chunk_rows(notes_root:, path_prefix:, max_chunks:)
  indexer = NotesIndexer.new(notes_root: notes_root)
  chunks = indexer.index.fetch(:chunks)
  chunks = chunks.select { |chunk| chunk.fetch(:path).start_with?(path_prefix) } unless path_prefix.nil?
  chunks = chunks.first(max_chunks) unless max_chunks.nil?

  chunks.map do |chunk|
    {
      path: chunk.fetch(:path),
      chunk_index: Integer(chunk.fetch(:chunk_index)),
      content: chunk.fetch(:content)
    }
  end
end

def write_manifest(path:, payload:)
  dir = File.dirname(path)
  Dir.mkdir(dir) unless Dir.exist?(dir)
  File.write(path, JSON.pretty_generate(payload) + "\n")
end

options = validate_options!(parse_options(ARGV))
chunks = chunk_rows(
  notes_root: options.fetch(:notes_root),
  path_prefix: options.fetch(:path_prefix),
  max_chunks: options.fetch(:max_chunks)
)

puts "notes_root=#{options.fetch(:notes_root)}"
puts "vector_store_id=#{options.fetch(:vector_store_id)}"
puts "chunk_count=#{chunks.size}"
puts "dry_run=true" if options.fetch(:dry_run)

if options.fetch(:dry_run)
  preview = chunks.first(5).map { |row| row.slice(:path, :chunk_index) }
  puts "preview=#{JSON.generate(preview)}"
  exit 0
end

manifest_rows = []

Dir.mktmpdir("mirai-vector-upload") do |tmp_dir|
  chunks.each_with_index do |chunk, idx|
    temp_file_path = File.join(tmp_dir, "chunk-#{idx}.txt")
    File.write(temp_file_path, chunk.fetch(:content))

    uploaded_file = post_file(
      base_url: options.fetch(:base_url),
      path: "/v1/files",
      api_key: options.fetch(:api_key),
      file_path: temp_file_path,
      purpose: "assistants"
    )
    file_id = uploaded_file.fetch("id")

    attachment = post_json(
      base_url: options.fetch(:base_url),
      path: "/v1/vector_stores/#{options.fetch(:vector_store_id)}/files",
      api_key: options.fetch(:api_key),
      payload: {
        file_id: file_id,
        attributes: {
          path: chunk.fetch(:path),
          chunk_index: chunk.fetch(:chunk_index)
        }
      }
    )

    manifest_rows << {
      file_id: file_id,
      vector_store_file_id: attachment["id"],
      path: chunk.fetch(:path),
      chunk_index: chunk.fetch(:chunk_index)
    }

    puts format("uploaded %<current>d/%<total>d %<path>s#%<chunk_index>d", {
      current: idx + 1,
      total: chunks.size,
      path: chunk.fetch(:path),
      chunk_index: chunk.fetch(:chunk_index)
    })
  end
end

manifest = {
  created_at: Time.now.utc.iso8601,
  vector_store_id: options.fetch(:vector_store_id),
  notes_root: options.fetch(:notes_root),
  chunks_uploaded: manifest_rows.size,
  uploads: manifest_rows
}

write_manifest(path: options.fetch(:manifest_path), payload: manifest)
puts "manifest_written=#{options.fetch(:manifest_path)}"
