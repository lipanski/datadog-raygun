{% unless flag?(:release) %}
require "dotenv"; Dotenv.load(".env")
{% end %}
require "kemal"
require "./raygun"
require "./datadog"
require "./collector"

TAGS = Hash(String, Array(String)).from_json(ENV.fetch("TAGS"))

post "/webhook/:secret" do |env|
  unless env.params.url["secret"] == ENV.fetch("WEBHOOK_SECRET")
    halt env, status_code: 401, response: "unauthorized"
  end

  body = env.request.body.not_nil!.gets_to_end
  event = Raygun::Event.from_json(body)

  if event.error? && TAGS.has_key?(event.application_name)
    metric_name = event.new? ? "raygun.new_error_occurred" : "raygun.error_reoccurred"
    tags = TAGS[event.application_name] + event.prefixed_tags("raygun")
    # Collector.enqueue(Datadog::Metric.count(metric_name, 1, tags))
    Collector.enqueue(event)
  end

  "ok"
end

error 404 do
  "not found"
end

error 500 do
  "error"
end

Collector.run
Kemal.run
