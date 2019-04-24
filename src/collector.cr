require "logger"
require "./datadog"
require "./raygun"
require "./application"

class Collector
  QUEUE_DEADLINE = ENV.fetch("QUEUE_DEADLINE", "60").to_i

  @queue : Hash(String, Application) = Hash(String, Application).new
  @logger : Logger = Logger.new(STDOUT).tap do |logger|
    logger.level = Logger::Severity.parse(ENV.fetch("LOG_LEVEL", "ERROR"))
    logger.formatter = Logger::Formatter.new do |severity, time, progname, message, io|
      io << time << " " << progname << " " << severity << " " << message
    end
  end

  def logger : Logger
    @logger
  end

  def initialize(run_on_init : Bool = true, process_on_exit : Bool = true)
    if run_on_init
      run
    end

    if process_on_exit
      at_exit do
        logger.info("Processing the enqueued metrics before shutting down...", "COLLECTOR")
        process
        logger.info("La revedere!", "COLLECTOR")
      end
    end
  end

  def enqueue(event : Raygun::Event)
    unless @queue[event.application_id]?
      logger.info("Registered a new application: #{event.application_name}")
      @queue[event.application_id] = Application.new(event.application_name)
    end

    @queue[event.application_id] << event
  end

  def run
    spawn do
      loop do
        sleep QUEUE_DEADLINE
        process
      end
    end

    logger.info("Started collecting metrics", "COLLECTOR")
  end

  def process
    logger.debug("Delivering metrics", "COLLECTOR")

    metrics = Array(Datadog::Metric).new
    @queue.each do |_, application|
      error_count = application.pop_error_count
      new_error_count = application.pop_new_error_count
      tags = application.tags

      if error_count > 0
        metrics << Datadog::Metric.gauge("raygun.error_count", error_count, tags)
      end

      if new_error_count > 0
        metrics << Datadog::Metric.gauge("raygun.new_error_count", new_error_count, tags)
      end
    end

    series = Datadog::Series.new(metrics)
    series.create!
  rescue exception : Datadog::Error
    logger.error(exception.message, "COLLECTOR")
  rescue exception : Exception
    logger.error(exception.inspect_with_backtrace, "COLLECTOR")
  else
    logger.debug("#{metrics.size} metrics delivered", "COLLECTOR")
  end
end
