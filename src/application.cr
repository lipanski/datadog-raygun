require "./raygun"

class Application
  class Pair
    property first : Raygun::Event
    property last : Raygun::Event? = nil
    @counted : Bool = false

    def initialize(@first : Raygun::Event)
    end

    def count : Int64?
      return if last.nil? && first.followup?
      return if @counted
      return 1i64 if last.nil?

      last.not_nil!.total_occurences - first.total_occurences + 1
    end

    def first=(value : Raygun::Event)
      @counted = false
      @first = value
    end

    def swap
      @counted = true

      if last
        self.first = last.not_nil!
        self.last = nil
      end
    end
  end

  getter tags : Array(String)

  def initialize(@tags : Array(String) = Array(String).new)
    @grouped_events = Hash(String, Pair).new
    @new_error_count = 0
  end

  def <<(event : Raygun::Event)
    if event.new?
      @new_error_count += 1
    end

    if @grouped_events[event.id]?
      @grouped_events[event.id].last = event
    else
      @grouped_events[event.id] = Pair.new(event)
    end
  end

  def pop_error_count : Int64
    count = 0i64

    @grouped_events.each do |_, pair|
      if pair_count = pair.count
        count += pair_count
      end

      pair.swap
    end

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
