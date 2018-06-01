require "logger"
require "./datadog"

module Collector
  QUEUE_SIZE     = ENV.fetch("QUEUE_SIZE", "50").to_i
  QUEUE_DEADLINE = ENV.fetch("QUEUE_DEADLINE", "60").to_i.seconds

  @@queue : Array(Datadog::Metric) = Array(Datadog::Metric).new
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

  def self.enqueue(metric : Datadog::Metric)
    @@queue << metric
  end

  def self.process(force : Bool = false)
    return if queue_empty?
    return unless force || process?

    logger.debug("Delivering metrics", "COLLECTOR")

    @@last_check = Time.now

    metrics = @@queue.shift(QUEUE_SIZE)
    series = Datadog::Series.new(metrics)
    series.create!
  rescue exception : Datadog::Error
    logger.error("A Datadog error occured: #{exception.message}", "COLLECTOR")
    @@queue += metrics if metrics
  rescue exception : Exception
    logger.error("An error occured: #{exception.inspect_with_backtrace}", "COLLECTOR")
  else
    logger.debug("#{metrics.size} metrics delivered", "COLLECTOR")
  end

  private def self.process?
    queue_full? || long_time_since_last_processed?
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
