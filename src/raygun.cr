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

  struct Event
    JSON.mapping(
      event: String,
      event_type: {type: EventType, key: "eventType"},
      error: Error,
      application: Application,
    )

    def error_notification? : Bool
      event == "error_notification"
    end

    def new? : Bool
      event_type == EventType::NewErrorOccurred
    end

    def id
      error.url
    end

    def application_id
      application.name # url is better!
    end

    def application_name : String
      application.name
    end

    def total_occurences : Int64
      error.total_occurences.not_nil!
    end

    def last_occured_at : Time
      error.last_occured_at.not_nil!
    end
  end

  struct Error
    JSON.mapping(
      url: String,
      last_occurred_at: {type: Time?, key: "lastOccurredOn"},
      total_occurences: {type: Int64?, key: "totalOccurrences"},
    )
  end

  struct Application
    JSON.mapping(
      name: String,
      url: String,
    )
  end
end
