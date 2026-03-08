# frozen_string_literal: true

require "thread"

class NullSemanticIngestionService
  def enqueue_for_paths(paths:)
    false
  end

  def process
    false
  end
end

class AsyncSemanticIngestionService
  def initialize(enabled:, processor:, logger:, autostart: true, queue: Queue.new)
    @enabled = enabled
    @processor = processor
    @logger = logger
    @queue = queue
    @enqueued_paths = {}
    @mutex = Mutex.new
    start_worker if @enabled && autostart
  end

  def enqueue_for_paths(paths:)
    return false unless @enabled

    normalized_paths = normalize_paths(paths)
    return false if normalized_paths.empty?

    @mutex.synchronize do
      normalized_paths.each do |path|
        next if @enqueued_paths[path]

        @enqueued_paths[path] = true
        @queue << path
      end
    end

    true
  rescue StandardError => e
    log_warn("semantic ingestion enqueue failed: #{e.class}: #{e.message}")
    false
  end

  def process
    return false unless @enabled

    path = @queue.pop(true)
    @processor.process(paths: [path])
    true
  rescue ThreadError
    false
  rescue StandardError => e
    log_warn("semantic ingestion processing failed: #{e.class}: #{e.message}")
    true
  ensure
    @mutex.synchronize { @enqueued_paths.delete(path) } if defined?(path) && !path.nil?
  end

  private

  def start_worker
    Thread.new do
      loop do
        process
        sleep(0.05)
      end
    end
  end

  def normalize_paths(paths)
    Array(paths).filter_map do |path|
      next unless path.is_a?(String)

      normalized = path.strip
      next if normalized.empty?

      normalized
    end.uniq
  end

  def log_warn(message)
    if @logger.respond_to?(:warn)
      @logger.warn(message)
    elsif @logger.respond_to?(:puts)
      @logger.puts(message)
    end
  end
end
