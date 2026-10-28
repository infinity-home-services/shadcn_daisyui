#!/usr/bin/env bash
# Vendor Chart.js into priv/static/vendor/ - the chart kit's only outside code
# (priv/static/shadcn-daisyui-charts.js imports it). Consuming apps run scripts
# only from their own server and have no npm, so the package ships the copy.
#
#   scripts/vendor_chartjs.sh 4.6.1                  # fetch with pnpm, then copy
#   scripts/vendor_chartjs.sh 4.6.1 path/node_modules # copy from an existing fetch
#
# The fetch is a plain `pnpm add` in a temp folder, so this machine's pnpm
# gates (release age, trust policy, exotic sources, build scripts) apply; a
# version they block stays blocked until they clear it.
#
# What's copied: Chart.js's ES module build (dist/chart.js + dist/chunks/) and
# its one dependency, @kurkle/color (dist/color.esm.js), with both licences.
# The only change to their code: the two bare `@kurkle/color` imports point at
# the vendored copy (a relative path), so the files load with no npm resolver.
# priv/static/vendor/README.md records the versions, the npm integrity hashes
# and that rewrite.
set -euo pipefail

version="${1:?usage: scripts/vendor_chartjs.sh VERSION [node_modules]}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
vendor="$here/priv/static/vendor"

if [ -n "${2:-}" ]; then
  modules="$(cd "$2" && pwd)"
else
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  printf '{ "name": "vendor-chartjs", "private": true }\n' > "$tmp/package.json"
  (cd "$tmp" && pnpm add "chart.js@$version")
  modules="$tmp/node_modules"
fi

chartjs="$(cd "$modules/chart.js" && pwd -P)"
# pnpm puts a package's dependencies beside it; a flat node_modules at the top
kurkle="$(dirname "$chartjs")/@kurkle/color"
[ -d "$kurkle" ] || kurkle="$modules/@kurkle/color"
[ -f "$kurkle/dist/color.esm.js" ] || { echo "@kurkle/color not found next to $chartjs" >&2; exit 1; }
got="$(node -p "require('$chartjs/package.json').version")"
[ "$got" = "$version" ] || { echo "expected chart.js $version, found $got" >&2; exit 1; }
kurkle_version="$(node -p "require('$kurkle/package.json').version")"

rm -rf "$vendor/chart.js" "$vendor/kurkle-color"
mkdir -p "$vendor/chart.js/chunks" "$vendor/kurkle-color"
cp "$chartjs/dist/chart.js" "$vendor/chart.js/chart.js"
cp "$chartjs/dist/chunks/index.js" "$vendor/chart.js/chunks/index.js"
cp "$chartjs/LICENSE.md" "$vendor/chart.js/LICENSE.md"
cp "$kurkle/dist/color.esm.js" "$vendor/kurkle-color/color.esm.js"
cp "$kurkle/LICENSE.md" "$vendor/kurkle-color/LICENSE.md"

# the bare specifier -> the vendored copy (and drop the source map comments:
# the maps aren't shipped)
rewrite() {
  local file="$1" path="$2"
  local before after
  before="$(grep -c "'@kurkle/color'" "$file" || true)"
  sed -i.bak -e "s#'@kurkle/color'#'$path'#" -e '/^\/\/# sourceMappingURL=/d' "$file"
  rm -f "$file.bak"
  after="$(grep -c "'$path'" "$file" || true)"
  [ "$before" = "1" ] && [ "$after" = "1" ] || { echo "unexpected @kurkle/color imports in $file" >&2; exit 1; }
}
rewrite "$vendor/chart.js/chart.js" "../kurkle-color/color.esm.js"
rewrite "$vendor/chart.js/chunks/index.js" "../../kurkle-color/color.esm.js"
sed -i.bak -e '/^\/\/# sourceMappingURL=/d' "$vendor/kurkle-color/color.esm.js" && rm -f "$vendor/kurkle-color/color.esm.js.bak"

chart_integrity="$(pnpm view "chart.js@$version" dist.integrity 2>/dev/null || echo unknown)"
kurkle_integrity="$(pnpm view "@kurkle/color@$kurkle_version" dist.integrity 2>/dev/null || echo unknown)"

cat > "$vendor/README.md" <<EOF
# Vendored code

The chart kit's only outside code, shipped inside the package so apps load it
from their own server (no CDN, no npm). Imported by
\`priv/static/shadcn-daisyui-charts.js\` only - \`shadcn-daisyui.js\` never
loads it. Update with \`scripts/vendor_chartjs.sh VERSION\`.

| Package | Version | Source | npm integrity | Licence |
|---|---|---|---|---|
| chart.js | $version | https://registry.npmjs.org/chart.js/-/chart.js-$version.tgz (\`dist/chart.js\`, \`dist/chunks/index.js\`) | \`$chart_integrity\` | MIT, \`chart.js/LICENSE.md\` |
| @kurkle/color | $kurkle_version | https://registry.npmjs.org/@kurkle/color/-/color-$kurkle_version.tgz (\`dist/color.esm.js\`) | \`$kurkle_integrity\` | MIT, \`kurkle-color/LICENSE.md\` |

Changes to the upstream files: the bare \`'@kurkle/color'\` import in
\`chart.js/chart.js\` and \`chart.js/chunks/index.js\` points at
\`kurkle-color/color.esm.js\` (a relative path), and the
\`//# sourceMappingURL\` comments are dropped (the maps aren't shipped).
Nothing else.
EOF

echo "✓ vendored chart.js $version (+ @kurkle/color $kurkle_version) → $vendor"
