require "logger"
require "./datadog"
require "./raygun"

module Collector
  QUEUE_SIZE     = ENV.fetch("QUEUE_SIZE", "50").to_i
  QUEUE_DEADLINE = ENV.fetch("QUEUE_DEADLINE", "60").to_i.seconds

  @@queue : Array(Raygun::Event) = Array(Raygun::Event).new
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

  def self.run
    spawn do
      loop do
        process
        sleep 1
      end
    end

    logger.info("Started collecting metrics", "COLLECTOR")
  end

  def self.enqueue(metric : Raygun::Event)
    @@queue << metric
  end

  def self.process(force : Bool = false)
    return if queue_empty?
    return unless force || process?

    logger.debug("Delivering metrics", "COLLECTOR")

    error_events = @@queue.shift(@@queue.size)
    new_error_events = error_events.select(&.new?)

    total_occurences = error_events.reduce(0) { |memo, event| memo + event.error.total_occurences }

    metrics = Array(Datadog::Metric).new
    metrics << Datadog::Metric.count("raygun.error_occurred", total_occurences)
    # series = Datadog::Series.new(metrics)
    # series.create!


  rescue exception : Datadog::Error
    logger.error("A Datadog error occured: #{exception.message}", "COLLECTOR")
  rescue exception : Exception
    logger.error("An error occured: #{exception.inspect_with_backtrace}", "COLLECTOR")
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
  Collector.process(force: true)
  Collector.logger.info("CIAO", "COLLECTOR")
end
