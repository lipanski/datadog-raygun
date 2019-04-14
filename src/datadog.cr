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
        else          raise Error.new("Request to Datadog failed with status #{response.status_code} and body:\n#{response.body}\n")
        end
      end
    end
  end

  class Metric
    JSON.mapping(
      metric: String,
      type: String,
      interval: Int32?,
      points: Array(Array(Int32)),
      tags: Array(String),
    )

    def self.count(metric : String, value : Int32, interval : Int32, tags : Array(String))
      new(metric, "count", interval, [[Time.now.to_s("%s").to_i, value]], tags)
    end

    def self.gauge(metric : String, value : Int32, tags : Array(String))
      new(metric, "gauge", nil, [[Time.now.to_s("%s").to_i, value]], tags)
    end

    def initialize(@metric : String, @type : String, @interval : Int32?, @points : Array(Array(Int32)), @tags : Array(String))
    end
  end
end
