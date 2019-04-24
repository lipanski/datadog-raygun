require "./raygun"

class Application
  def initialize(@name : String = "")
    @grouped_events = Hash(String, {counter: Int32, previous: Raygun::Event}).new
    @new_error_count = 0
  end

  def tags : Array(String)
    @name.split(/\W+/).reject { |part| part.empty? }.map { |part| "raygun:" + part.downcase }
  end

  def <<(event : Raygun::Event)
    if event.new?
      @new_error_count += 1
    end

    if data = @grouped_events[event.id]?
      counter = data[:counter] + event.total_occurences - data[:previous].total_occurences
      @grouped_events[event.id] = {counter: counter, previous: event}
    elsif event.single?
      @grouped_events[event.id] = {counter: 1, previous: event}
    else
      @grouped_events[event.id] = {counter: 0, previous: event}
    end
  end

  def pop_error_count : Int32
    count = 0

    @grouped_events.each do |id, data|
      count += data[:counter]
      @grouped_events[id] = {counter: 0, previous: data[:previous]}
    end

    count
  end

  def pop_new_error_count
    @new_error_count.clone.tap do
      @new_error_count = 0
    end
  end
end
