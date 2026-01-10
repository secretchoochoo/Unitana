export default {
  async fetch(request, env, ctx) {
    const u = new URL(request.url);

    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: cors() });
    }

    if (request.method !== 'GET') {
      return new Response('Method Not Allowed', { status: 405, headers: cors() });
    }

    if (!u.pathname.endsWith('/v1/forecast.json')) {
      return new Response('Not Found', { status: 404, headers: cors() });
    }

    const q = (u.searchParams.get('q') || '').trim();
    if (!q) {
      return new Response('Missing required query parameter: q', {
        status: 400,
        headers: cors(),
      });
    }

    const apiKey = (env.WEATHERAPI_KEY || '').trim();
    if (!apiKey) {
      return new Response('Proxy is not configured (missing WEATHERAPI_KEY)', {
        status: 500,
        headers: cors(),
      });
    }

    const upstream = new URL('https://api.weatherapi.com/v1/forecast.json');
    upstream.searchParams.set('key', apiKey);
    upstream.searchParams.set('q', q);
    upstream.searchParams.set('days', u.searchParams.get('days') || '1');
    upstream.searchParams.set('aqi', u.searchParams.get('aqi') || 'no');
    upstream.searchParams.set('alerts', u.searchParams.get('alerts') || 'no');

    const cacheKey = new Request(upstream.toString(), { method: 'GET' });
    const cache = caches.default;

    const cached = await cache.match(cacheKey);
    if (cached) {
      return withCors(cached);
    }

    const resp = await fetch(upstream.toString(), {
      cf: { cacheTtl: 600, cacheEverything: true },
    });

    const out = new Response(resp.body, resp);
    out.headers.set('Cache-Control', 'public, max-age=600');

    ctx.waitUntil(cache.put(cacheKey, out.clone()));
    return withCors(out);
  },
};

function cors() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Max-Age': '86400',
  };
}

function withCors(resp) {
  const headers = new Headers(resp.headers);
  const c = cors();
  for (const k of Object.keys(c)) {
    headers.set(k, c[k]);
  }
  return new Response(resp.body, {
    status: resp.status,
    statusText: resp.statusText,
    headers,
  });
}
