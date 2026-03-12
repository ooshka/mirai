# frozen_string_literal: true

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
    @queued_paths = {}
    @processing_paths = {}
    @rerun_paths = {}
    @mutex = Mutex.new
    start_worker if @enabled && autostart
  end

  def enqueue_for_paths(paths:)
    return false unless @enabled

    normalized_paths = normalize_paths(paths)
    return false if normalized_paths.empty?

    @mutex.synchronize do
      normalized_paths.each do |path|
        if @queued_paths[path]
          next
        elsif @processing_paths[path]
          @rerun_paths[path] = true
        else
          @queued_paths[path] = true
          @queue << path
        end
      end
    end

    true
  rescue => e
    log_warn("semantic ingestion enqueue failed: #{e.class}: #{e.message}")
    false
  end

  def process
    return false unless @enabled

    path = @queue.pop(true)
    mark_processing(path)
    @processor.process(paths: [path])
    true
  rescue ThreadError
    false
  rescue => e
    log_warn("semantic ingestion processing failed: #{e.class}: #{e.message}")
    true
  ensure
    complete_processing(path) if defined?(path) && !path.nil?
  end

  private

  def mark_processing(path)
    @mutex.synchronize do
      @queued_paths.delete(path)
      @processing_paths[path] = true
    end
  end

  def complete_processing(path)
    requeue = false

    @mutex.synchronize do
      @processing_paths.delete(path)

      if @rerun_paths.delete(path) && !@queued_paths[path]
        @queued_paths[path] = true
        requeue = true
      end
    end

    @queue << path if requeue
  end

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
