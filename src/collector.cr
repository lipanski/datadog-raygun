require "logger"
require "./datadog"
require "./raygun"

class Application
  getter tags : Array(String)

  def initialize(@tags : Array(String))
    @error_count = 0
    @new_error_count = 0
    @active = false
    @events = Hash(String, Array(Raygun::Event)).new
  end

  def push_event(event : Raygun::Event)
    @active = true

    if event.new?
      increment_new_error_count
    end

    @events[event.id] ||= Array(Raygun::Event).new
    @events[event.id] << event
  end

  # def push_error_count(value : Int64)
  #   @active = true
  #   @error_count += value
  # end

  def pop_error_count
    @active = false
    @error_count.clone.tap do
      @error_count = 0
    end
  end

  def increment_new_error_count
    @new_error_count += 1
  end

  def pop_new_error_count
    @active = false
    @new_error_count.clone.tap do
      @new_error_count = 0
    end
  end

  def active? : Bool
    @events.any?
  end
end

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

  def initialize(applications : Hash(String, Array(String)), run_on_init : Bool = true, process_on_exit : Bool = true)
    applications.each do |application_id, tags|
      @queue[application_id] = Application.new(tags)
    end

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

  def run
    spawn do
      loop do
        sleep QUEUE_DEADLINE
        process
      end
    end

    logger.info("Started collecting metrics", "COLLECTOR")
  end

  def enqueue(event : Raygun::Event)
    @queue[event.application_id].push_event(event)
    # @queue[event.application_id].push_error_count(event.total_occurences)
    # @queue[event.application_id].increment_new_error_count if event.new?
  end

  def process
    logger.debug("Delivering metrics", "COLLECTOR")

    metrics = Array(Datadog::Metric).new
    @queue.each do |_, application|
      next unless application.active?
      metrics << Datadog::Metric.gauge("raygun.error_count", application.pop_error_count, application.tags)
      metrics << Datadog::Metric.gauge("raygun.new_error_count", application.pop_new_error_count, application.tags)
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
