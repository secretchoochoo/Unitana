# Unitana WeatherAPI Proxy (Cloudflare Worker)

This worker is an optional production hardening step. It keeps your shared WeatherAPI key off the mobile client and adds edge caching.

## What it does

- Proxies `GET /v1/forecast.json` to WeatherAPI
- Requires a `WEATHERAPI_KEY` secret stored in the Worker
- Caches responses for 10 minutes

## Deploy

1. Install Wrangler and authenticate:
   - `npm install -g wrangler`
   - `wrangler login`
2. Copy `wrangler.toml.example` to `wrangler.toml` and set `name` (and `account_id` if required).
3. Store your WeatherAPI key as a secret:
   - `wrangler secret put WEATHERAPI_KEY`
4. Deploy:
   - `wrangler deploy`

## Configure Unitana

Run Unitana in proxy mode (do not send the key from the app):

```bash
flutter run \
  --dart-define=WEATHERAPI_BASE_URL=https://<your-worker-host> \
  --dart-define=WEATHERAPI_SEND_KEY=false
```

If you want to allow the proxy to accept any WeatherAPI query params beyond `q/days/aqi/alerts`, update `worker.js` accordingly.
