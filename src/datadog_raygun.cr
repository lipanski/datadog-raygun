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
    halt env, status_code: 401, response: "Unauthorized."
  end

  body = env.request.body.not_nil!.gets_to_end
  event = Raygun::Event.from_json(body)

  if event.error_notification? && TAGS.has_key?(event.application_id)
    Collector.enqueue(event)
  end

  "Ok."
end

error 404 do
  "Not found."
end

error 500 do
  "An unknown error occured."
end

Collector.run(TAGS)
Kemal.run
