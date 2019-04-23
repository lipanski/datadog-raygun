# datadog-raygun

An app to help you pipe Raygun metrics into DataDog:

- `raygun.error_count`: The total error count for a particular period of time and Raygun application.
- `raygun.new_error_count`: The new error count for a particular period of time and Raygun application.

> Note that because of [the way](https://raygun.com/documentation/product-guides/crash-reporting/integrations/webhooks/) this information is provided by Raygun, results might not always be reliable or up-to-date. While working on this project, I've experienced both delays and missing callbacks when dealing with the Raygun webhooks.

## Installation

The app is provided as a Docker image: https://hub.docker.com/r/lipanski/datadog-raygun

Alternatively you can build it from source, which requires [Crystal](https://crystal-lang.org/):

```sh
shards install --production
crystal build --release src/datadog_raygun.cr
```

## Usage

The app consists of a web server and a background job processor. The web server exposes an endpoint `POST /webhook/[SECRET]` which is to be used with Raygun's webhook integration. The background job processor records all the error details coming from Raygun, computes the metrics and sends them periodically to DataDog.

The application is configured via environment variables:

- `WEBHOOK_SECRET`: The *secret* used inside the `POST /webhook/[SECRET]` endpoint for authentication.
- `DATADOG_API_KEY`: A DataDog API key, used to push the metrics to DataDog.
- `TAGS`: A JSON String where every key is a Raygun application name and every value is an Array of DataDog labels, that will be added to the metrics of every application.
- `QUEUE_DEADLINE`: A value in seconds, which determines how often the metrics will be delivered to DataDog (defaults to 60 seconds).
- `LOG_LEVEL`: The log level (defaults to INFO).

Here's an example of how to run the app:

```sh
# The webhook endpoint will be available at http://localhost:3000/webhook/my-secret
WEBHOOK_SECRET=my-secret \
  DATADOG_API_KEY=your-datadog-api-key \
  TAGS='{"Some Raygun Project": ["some-datadog-label", "some-other-datadog-label"], "Some Other Raygun Project": []}' \
  QUEUE_DEADLINE=60 \
  LOG_LEVEL=DEBUG \
  datadog_raygun
```

> By default the server will run on port 3000, but you can override this via the `--port` argument.

Once you've installed the app and ensured it's running, go over to Raygun and enable the Webhook integration for every Raygun application you are interested in collecting metrics from.

## Development

Get a copy of the `.env` file and fill in the gaps:

```sh
cp .env.example .env
```

Install dependencies:

```sh
shards install
```

Run the thing:

```sh
crystal src/datadog_raygun.cr
```

...or use `sentry` to rebuild the thing on every change:

```sh
# Build sentry
crystal build lib/sentry/src/sentry_cli.cr

# Run sentry
./sentry_cli
```

The easiest way to test your local build in integration with Raygun would be via [ngrok](https://ngrok.com/):

```sh
ngrok http 3000
```

Then you can configure your Raygun project to point to the ngrok host and trigger an error:

```sh
curl -XPOST https://api.raygun.com/entries -H "X-ApiKey: <RAYGUN API KEY>" -H "Content-Type: application/json" -d @examples/full.json -i
```

If you want to trigger a *new* error, change the `groupingKey` in `examples/full.json`.

If you don't want to expose your local server, you can simulate the Raygun callback to localhost:

```sh
curl -XPOST http://localhost:3000/webhook\?secret\=secret -H "Content-Type: application/json" -d @examples/error_reoccurred.json -i
```

## Docker

Build the image:

```sh
docker build -t datadog-raygun .
```

Run a container:

```sh
docker run -it \
  -e WEBHOOK_SECRET=secret \
  -e DATADOG_API_KEY=your-datadog-api-key \
  -e TAGS='{"Some Raygun Project": ["some-datadog-label", "some-other-datadog-label"]}' \
  -e QUEUE_DEADLINE=60 \
  -e LOG_LEVEL=DEBUG \
  -p 3000:3000 \
  datadog-raygun
```

Your container will be reachable over port 3000.
