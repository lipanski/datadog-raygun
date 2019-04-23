require "./raygun"

class Application
  getter tags : Array(String)

  def initialize(@tags : Array(String) = Array(String).new)
    @error_count = 0
    @new_error_count = 0
    @grouped_events = Hash(String, Array(Raygun::Event)).new
  end

  def push_event(event : Raygun::Event)
    if event.new?
      @new_error_count += 1
    end

    @grouped_events[event.id] ||= Array(Raygun::Event).new
    @grouped_events[event.id] << event
  end

  def pop_error_count
    count = 0

    @grouped_events.each do |id, events|
      events.each do |event|
        if event.new?
          count += event.total_occurences
        else
        end
      end
    end

    @grouped_events.clear

    count
  end

  def pop_new_error_count
    @new_error_count.clone.tap do
      @new_error_count = 0
    end
  end

  def active? : Bool
    @grouped_events.any?
  end
end
