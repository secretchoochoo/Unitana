# WeatherAPI key management (Unitana)

Unitana supports **two** ways to call WeatherAPI:

## 1) Direct to WeatherAPI (development only)

- Unitana sends the WeatherAPI key as a `key` query parameter.
- This is convenient for local testing, but it is not appropriate for a published mobile app because the key can be extracted.

### How to run locally

```bash
flutter run \
  --dart-define=WEATHERAPI_KEY=... \
  --dart-define=WEATHERAPI_BASE_URL=https://api.weatherapi.com \
  --dart-define=WEATHERAPI_SEND_KEY=true
```

## 2) Proxy mode (recommended for production)

- Unitana sends **no** WeatherAPI key from the client.
- Your proxy injects the key server-side.
- Unitana points `WEATHERAPI_BASE_URL` at your proxy.

### How to run locally against a proxy

```bash
flutter run \
  --dart-define=WEATHERAPI_BASE_URL=https://<your-proxy-host> \
  --dart-define=WEATHERAPI_SEND_KEY=false
```

### Proxy template included in this repo

A ready-to-deploy Cloudflare Worker proxy lives at:

- `tools/weather_proxy/cloudflare_worker/`

It proxies `GET /v1/forecast.json` and caches results for 10 minutes.
