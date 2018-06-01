# datadog_raygun

## Usage

```
WEBHOOK_SECRET=secret \
  DATADOG_API_KEY=your-datadog-api-key \
  TAGS='{"Florin": ["stack:production", "application:florin"]}' \
  QUEUE_DEADLINE=60 \
  QUEUE_SIZE=50 \
  LOG_LEVEL=DEBUG \
  datadog_raygun --port 8080
```

## Development

```sh
crystal deps
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
