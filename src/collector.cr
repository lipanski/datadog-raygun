require "logger"
require "./datadog"
require "./raygun"

module Collector
  QUEUE_SIZE     = ENV.fetch("QUEUE_SIZE", "50").to_i
  QUEUE_DEADLINE = ENV.fetch("QUEUE_DEADLINE", "60").to_i.seconds

  class Application
    getter tags : Array(String)

    def initialize(@tags : Array(String))
      @grouped_error_count = Hash(String, Int64).new
      @new_error_count = 0
    end

    def push_error_count(error_id : String, value : Int64)
      @grouped_error_count[error_id] = (@grouped_error_count[error_id]? || 0i64) + value
    end

    def pop_error_count
      @grouped_error_count.clear.reduce(0) { |acc, (_, value)| acc += value }
    end

    def increment_new_error_count
      @new_error_count += 1
    end

    def pop_new_error_count
      @new_error_count.tap do |count|
        count = 0
      end
    end
  end

  @@queue : Hash(String, Application) = Hash(String, Application).new
  @@last_check = Time.now
  @@logger : Logger = Logger.new(STDOUT).tap do |logger|
    logger.level = Logger::Severity.parse(ENV.fetch("LOG_LEVEL", "ERROR"))
    logger.formatter = Logger::Formatter.new do |severity, time, progname, message, io|
      io << time << " " << progname << " " << severity << " " << message
    end
  end

  def self.logger : Logger
    @@logger
  end

  def self.init(applications : Hash(String, Array(String)))
    applications.each do |application_id, tags|
      @@queue[application_id] = Application.new(tags)
    end
  end

  def self.run(applications : Hash(String, Array(String)))
    init(applications)
    spawn do
      loop do
        try_process
        sleep 1
      end
    end

    logger.info("Started collecting metrics", "COLLECTOR")
  end

  def self.enqueue(event : Raygun::Event)
    @@queue[event.application_id].push_error_count(event.id, event.total_occurences)
    @@queue[event.application_id].increment_new_error_count if event.new?
  end

  def self.try_process
    return unless process?

    process
  end

  def self.process
    return if queue_empty?

    logger.debug("Delivering metrics", "COLLECTOR")

    metrics = Array(Datadog::Metric).new
    @@queue.each do |_, application|
      metrics << Datadog::Metric.gauge("raygun.error_occurred", application.pop_error_count, application.tags)
      metrics << Datadog::Metric.gauge("raygun.new_errors", application.pop_new_error_count, application.tags)
    end

    # series = Datadog::Series.new(metrics)
    # series.create!


  rescue exception : Datadog::Error
    logger.error(exception.message, "COLLECTOR")
  rescue exception : Exception
    logger.error(exception.inspect_with_backtrace, "COLLECTOR")
  else
    @@last_check = Time.now
    # logger.debug("#{metrics.size} metrics delivered", "COLLECTOR")
  end

  private def self.process?
    long_time_since_last_processed?
  end

  private def self.queue_empty?
    @@queue.empty?
  end

  private def self.queue_full?
    @@queue.size > QUEUE_SIZE
  end

  private def self.long_time_since_last_processed?
    Time.now - @@last_check > QUEUE_DEADLINE
  end
end

at_exit do
  Collector.logger.info("Processing the enqueued metrics before shutting down...", "COLLECTOR")
  Collector.process
  Collector.logger.info("LA REVEDERE!", "COLLECTOR")
end
