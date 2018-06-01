{% unless flag?(:release) %}
require "dotenv"; Dotenv.load(".env")
{% end %}
require "kemal"
require "logger"
require "./raygun"
require "./datadog"
require "./collector"

TAGS = Hash(String, Array(String)).from_json(ENV.fetch("TAGS"))

post "/webhook" do |env|
  unless env.params.query["secret"]? == ENV.fetch("WEBHOOK_SECRET")
    halt env, status_code: 403, response: "forbidden"
  end

  body = env.request.body.not_nil!.gets_to_end
  event = Raygun::Event.from_json(body)

  if event.error? && TAGS.has_key?(event.application_name)
    metric_name = event.new? ? "raygun.new_error_occurred" : "raygun.error_reoccurred"
    tags = TAGS[event.application_name] + event.prefixed_tags("raygun")
    Collector.enqueue(Datadog::Metric.gauge(metric_name, 1, tags))
  end

  "ok"
end

error 500 do
  "error"
end

Collector.run
Kemal.run
