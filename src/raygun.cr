require "json"

module Raygun
  enum EventType
    # error_notification
    NewErrorOccurred
    ErrorReoccurred
    OneMinuteFollowUp
    FiveMinuteFollowUp
    TenMinuteFollowUp
    ThirtyMinuteFollowUp
    HourlyFollowUp
    # error_activity
    StatusChanged
    AssignedToUser
    CommentAdded
  end

  class Event
    JSON.mapping(
      event: String,
      event_type: {type: EventType, key: "eventType"},
      error: Error,
      tags: Array(String)?,
      application: Application,
    )

    def error? : Bool
      [
        EventType::NewErrorOccurred,
        EventType::ErrorReoccurred,
        EventType::OneMinuteFollowUp,
        EventType::FiveMinuteFollowUp,
        EventType::TenMinuteFollowUp,
        EventType::ThirtyMinuteFollowUp,
        EventType::HourlyFollowUp,
      ].includes?(event_type)
    end

    def new? : Bool
      event_type == EventType::NewErrorOccurred
    end

    def application_name : String
      application.name
    end

    def error_message : String
      error.message
    end

    def prefixed_tags(prefix : String) : Array(String)
      (tags || Array(String).new).map { |tag| prefix + ":" + tag }
    end
  end

  class Error
    JSON.mapping(
      url: String,
      message: String,
      first_occurred_at: {type: Time?, key: "firstOccurredOn"},
      last_occurred_at: {type: Time?, key: "lastOccurredOn"},
      total_occurences: {type: Int64?, key: "totalOccurrences"},
    )

    def total_occurences : Int64
      @total_occurences || 1
    end
  end

  class Application
    JSON.mapping(
      name: String,
    )
  end
end
