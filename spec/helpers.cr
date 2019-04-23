require "../src/raygun"

module Helpers
  def self.raygun_event(event_type : String = "NewErrorOccurred",
                        error_url : String = "error_url",
                        last_occurred_at : Time = 2.seconds.ago,
                        total_occurences : Int = 1,
                        application_name : String = "application_name",
                        application_url : String = "application_url")
    data =
      {
        "event"     => "error_notification",
        "eventType" => event_type,
        "error"     => {
          "url"              => error_url,
          "lastOccuredOn"    => last_occurred_at.to_s,
          "totalOccurrences" => total_occurences,
        },
        "application" => {
          "name" => application_name,
          "url"  => application_url,
        },
      }

    Raygun::Event.from_json(data.to_json)
  end
end
