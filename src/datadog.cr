require "json"
require "http/client"

module Datadog
  class Error < Exception; end

  class Unauthorized < Error; end

  class RequestPayloadTooLarge < Error; end

  class Series
    JSON.mapping(
      series: Array(Metric),
    )

    def initialize(@series : Array(Metric))
    end

    def create!
      response = HTTP::Client.post(
        "https://api.datadoghq.com/api/v1/series?api_key=" + ENV.fetch("DATADOG_API_KEY"),
        headers: HTTP::Headers{"Content-Type" => "application/json"},
        body: to_json
      )

      unless response.success?
        case response.status_code
        when 403 then raise Unauthorized.new("Authorization failed, check the DATADOG_API_KEY")
        when 413 then raise RequestPayloadTooLarge.new("The payload was too large")
        else          raise Error.new("Request to Datadog failed with status #{response.status_code}\n#{response.body}\n")
        end
      end
    end
  end

  class Metric
    JSON.mapping(
      metric: String,
      points: Array(Array(Int32)),
      type: String,
      tags: Array(String),
    )

    def self.gauge(metric : String, value : Int32, tags : Array(String))
      new(metric, "gauge", [[Time.now.to_s("%s").to_i, value]], tags)
    end

    def initialize(@metric : String, @type : String, @points : Array(Array(Int32)), @tags : Array(String))
    end
  end
end
