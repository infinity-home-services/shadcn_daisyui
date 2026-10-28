# Vendored code

The chart kit's only outside code, shipped inside the package so apps load it
from their own server (no CDN, no npm). Imported by
`priv/static/shadcn-daisyui-charts.js` only - `shadcn-daisyui.js` never
loads it. Update with `scripts/vendor_chartjs.sh VERSION`.

| Package | Version | Source | npm integrity | Licence |
|---|---|---|---|---|
| chart.js | 4.6.1 | https://registry.npmjs.org/chart.js/-/chart.js-4.6.1.tgz (`dist/chart.js`, `dist/chunks/index.js`) | `sha512-hJyniucsFmq//EvXYvJ6c6mahPoI3kaxdjVH8awTaJ/fDNWeSqqqArixMJWkWNN6fcYvPU3HneSANFNYtRi61g==` | MIT, `chart.js/LICENSE.md` |
| @kurkle/color | 0.3.4 | https://registry.npmjs.org/@kurkle/color/-/color-0.3.4.tgz (`dist/color.esm.js`) | `sha512-M5UknZPHRu3DEDWoipU6sE8PdkZ6Z/S+v4dD+Ke8IaNlpdSQah50lz1KtcFBa2vsdOnwbbnxJwVM4wty6udA5w==` | MIT, `kurkle-color/LICENSE.md` |

Changes to the upstream files: the bare `'@kurkle/color'` import in
`chart.js/chart.js` and `chart.js/chunks/index.js` points at
`kurkle-color/color.esm.js` (a relative path), and the
`//# sourceMappingURL` comments are dropped (the maps aren't shipped).
Nothing else.
