{% unless flag?(:release) %}
require "dotenv"; Dotenv.load(".env")
{% end %}
require "kemal"
require "./raygun"
require "./datadog"
require "./collector"

COLLECTOR = Collector.new

post "/webhook/:secret" do |env|
  unless env.params.url["secret"] == ENV.fetch("WEBHOOK_SECRET")
    halt env, status_code: 401, response: "Unauthorized."
  end

  body = env.request.body.not_nil!.gets_to_end
  event = Raygun::Event.from_json(body)

  if event.error_notification?
    COLLECTOR.enqueue(event)
  end

  "Ok."
end

error 404 do
  "Not found."
end

error 500 do
  "An unknown error occured."
end

Kemal.run
