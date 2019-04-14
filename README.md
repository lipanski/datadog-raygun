# datadog_raygun

## Usage

```
WEBHOOK_SECRET=secret \
  DATADOG_API_KEY=your-datadog-api-key \
  TAGS='{"Some Raygun Project": ["some-datadog-label", "some-other-datadog-label"]}' \
  QUEUE_DEADLINE=60 \
  QUEUE_SIZE=50 \
  LOG_LEVEL=DEBUG \
  datadog_raygun --port 3000
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
  -e QUEUE_SIZE=50 \
  -e LOG_LEVEL=DEBUG \
  -p 3000:80 \
  datadog-raygun
```

Your container will be reachable over port 3000.

## Development

```sh
shards install
```

```sh
crystal src/datadog_raygun.cr
```

...or use `sentry`:

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
