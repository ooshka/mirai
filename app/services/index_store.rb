# frozen_string_literal: true

require "json"
require "fileutils"
require "time"

class IndexStore
  class InvalidArtifactError < StandardError; end

  ARTIFACT_VERSION = 1
  ARTIFACT_DIR = ".mirai"
  ARTIFACT_FILENAME = "index.json"

  def initialize(notes_root:)
    @notes_root = notes_root
  end

  def read
    return nil unless File.exist?(artifact_path)

    payload = JSON.parse(File.read(artifact_path))
    validate_payload!(payload)
    symbolize_payload(payload)
  rescue JSON::ParserError
    raise InvalidArtifactError, "index artifact is invalid"
  end

  def status
    payload = read
    return {present: false, generated_at: nil, notes_indexed: nil, chunks_indexed: nil} unless payload

    {
      present: true,
      generated_at: payload.fetch(:generated_at),
      notes_indexed: payload.fetch(:notes_indexed),
      chunks_indexed: payload.fetch(:chunks_indexed)
    }
  end

  def delete
    return false unless File.exist?(artifact_path)

    File.delete(artifact_path)
    true
  end

  def write(index_data, generated_at: Time.now.utc)
    payload = {
      "version" => ARTIFACT_VERSION,
      "generated_at" => generated_at.utc.iso8601,
      "notes_indexed" => index_data.fetch(:notes_indexed),
      "chunks_indexed" => index_data.fetch(:chunks_indexed),
      "chunks" => index_data.fetch(:chunks).map do |chunk|
        {
          "path" => chunk.fetch(:path),
          "chunk_index" => chunk.fetch(:chunk_index),
          "content" => chunk.fetch(:content)
        }
      end
    }

    FileUtils.mkdir_p(artifact_dir)
    tmp_path = "#{artifact_path}.tmp-#{Process.pid}-#{Thread.current.object_id}"
    File.write(tmp_path, JSON.pretty_generate(payload))
    File.rename(tmp_path, artifact_path)
  rescue KeyError, TypeError
    raise InvalidArtifactError, "index artifact is invalid"
  ensure
    File.delete(tmp_path) if defined?(tmp_path) && File.exist?(tmp_path)
  end

  private

  def artifact_dir
    File.join(@notes_root, ARTIFACT_DIR)
  end

  def artifact_path
    File.join(artifact_dir, ARTIFACT_FILENAME)
  end

  def validate_payload!(payload)
    raise InvalidArtifactError, "index artifact is invalid" unless payload.is_a?(Hash)
    raise InvalidArtifactError, "index artifact is invalid" unless payload["version"] == ARTIFACT_VERSION
    raise InvalidArtifactError, "index artifact is invalid" unless payload["generated_at"].is_a?(String)

    Time.iso8601(payload["generated_at"])

    notes_indexed = payload["notes_indexed"]
    chunks_indexed = payload["chunks_indexed"]
    chunks = payload["chunks"]

    raise InvalidArtifactError, "index artifact is invalid" unless notes_indexed.is_a?(Integer) && notes_indexed >= 0
    raise InvalidArtifactError, "index artifact is invalid" unless chunks_indexed.is_a?(Integer) && chunks_indexed >= 0
    raise InvalidArtifactError, "index artifact is invalid" unless chunks.is_a?(Array)

    chunks.each do |chunk|
      raise InvalidArtifactError, "index artifact is invalid" unless chunk.is_a?(Hash)
      raise InvalidArtifactError, "index artifact is invalid" unless chunk["path"].is_a?(String)
      raise InvalidArtifactError, "index artifact is invalid" unless chunk["chunk_index"].is_a?(Integer)
      raise InvalidArtifactError, "index artifact is invalid" unless chunk["content"].is_a?(String)
    end
  rescue ArgumentError
    raise InvalidArtifactError, "index artifact is invalid"
  end

  def symbolize_payload(payload)
    {
      version: payload["version"],
      generated_at: payload["generated_at"],
      notes_indexed: payload["notes_indexed"],
      chunks_indexed: payload["chunks_indexed"],
      chunks: payload["chunks"].map do |chunk|
        {
          path: chunk["path"],
          chunk_index: chunk["chunk_index"],
          content: chunk["content"]
        }
      end
    }
  end
end
