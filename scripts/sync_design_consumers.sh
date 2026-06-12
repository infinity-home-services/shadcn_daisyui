#!/usr/bin/env bash
# Propagate the canonical design guidelines to every consumer that bundles a
# copy: the Claude plugin/skill repo and the Swift package's bundled aggregate.
#
# Canonical source: usage-rules/{foundations,styles}-*.md in THIS repo.
# The docs site and the Phoenix usage_rules sync read the canonical files
# directly, so they need no step here.
#
# You normally do NOT run this by hand: the "Sync design guidelines" GitHub
# Action (.github/workflows/sync-design-guidelines.yml) runs it automatically on
# every push that touches usage-rules/ and pushes the result to the consumers, so
# the bundled copies can never drift. Run it locally only to preview the output.
#
# Sibling repo paths default to ../<name> and can be overridden via env vars.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
src="$here/usage-rules"

plugin_repo="${PLUGIN_REPO:-$here/../shadcn_daisyui_design}"
swift_repo="${SWIFT_REPO:-$here/../shadcn_daisyui_swift}"

# Aggregate order - platforms first as the preamble (matches the docs site's
# Guides registry and /design-guidelines.md).
order=(
  foundations-platforms
  foundations-accessibility
  foundations-layout
  foundations-spacing
  foundations-navigation
  foundations-interaction
  styles-color
  styles-typography
  styles-shape-elevation
  styles-motion
)

build_aggregate() {
  cat <<'EOF'
<!--
shadcn_daisyui design guidelines - single-file bundle.
Source of truth: the usage-rules/*.md files shipped in the shadcn_daisyui
hex package. Rules tagged [web]/[ios] are platform-scoped; untagged rules
are universal.
-->

EOF
  local first=1
  for name in "${order[@]}"; do
    [ $first -eq 1 ] || printf '\n---\n\n'
    first=0
    # print up to the last non-blank line (trims trailing blank lines like the
    # Elixir aggregate's String.trim_trailing, preserving internal newlines)
    awk 'NF{last=NR} {line[NR]=$0} END{for (i=1;i<=last;i++) print line[i]}' "$src/$name.md"
  done
}

# 1. Plugin skill references (the 10 files verbatim).
plugin_refs="$plugin_repo/skills/design-system/references"
if [ -d "$plugin_refs" ]; then
  cp "$src"/foundations-*.md "$src"/styles-*.md "$plugin_refs/"
  echo "✓ synced 10 reference files → $plugin_refs"
else
  echo "- skipped plugin (no dir at $plugin_refs)"
fi

# 2. Swift package bundled aggregate.
swift_res="$swift_repo/Sources/ShadcnDaisyUI/Resources/design-guidelines.md"
if [ -d "$(dirname "$swift_res")" ]; then
  build_aggregate > "$swift_res"
  echo "✓ rebuilt aggregate → $swift_res"
else
  echo "- skipped Swift bundle (no dir at $(dirname "$swift_res"))"
fi

echo "Done. Commit the changes in each consumer repo."
