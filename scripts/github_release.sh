#!/usr/bin/env bash
# Every version gets a tag and a GitHub release - no gaps.
#
# For the version in mix.exs (or the tag given as $1, e.g. v0.25.0):
#   - no vX.Y.Z tag yet: tag the commit that set that version in mix.exs and
#     push the tag;
#   - no GitHub release for the tag: create one, titled from the release
#     commit's subject ("Release 0.25.0 - summary (#12)" -> "v0.25.0 - summary"),
#     with CHANGELOG.md's "## [0.25.0]" section as the notes.
# Fails (before tagging) when CHANGELOG.md has no section for the version or
# package.json has another version, so a version can't ship without its
# changelog. --backfill also creates releases for older v* tags that never got
# one.
#
#   scripts/github_release.sh              # the version in mix.exs
#   scripts/github_release.sh v0.25.0      # a given tag
#   scripts/github_release.sh --backfill   # ...and every older tag missing a release
#   DRY_RUN=1 scripts/github_release.sh    # say what it would do, change nothing
#
# Needs git and an authenticated gh (GH_TOKEN in CI). The Release workflow
# (.github/workflows/release.yml) runs it on every push to main, and CI dry-runs
# it on every pull request.
set -euo pipefail
cd "$(dirname "$0")/.."

backfill=false
tag=""
for arg in "$@"; do
  case "$arg" in
    --backfill) backfill=true ;;
    v*) tag="$arg" ;;
    *) echo "usage: $0 [vX.Y.Z] [--backfill]" >&2; exit 2 ;;
  esac
done

run() { if [ -n "${DRY_RUN:-}" ]; then echo "would run: $*"; else "$@"; fi; }

# the CHANGELOG section for a version, without its heading
notes() { awk -v v="$1" 'index($0, "## [" v "]") == 1 { f = 1; next } /^## \[/ { f = 0 } f' CHANGELOG.md; }

has_notes() { [ -n "$(notes "$1" | tr -d '[:space:]')" ]; }

# release TAG [extra gh flags]
release() {
  local t="$1" v="${1#v}" subject title file
  shift
  if gh release view "$t" >/dev/null 2>&1; then
    echo "$t: release exists"
    return 0
  fi
  if ! has_notes "$v"; then
    echo "::error::CHANGELOG.md has no '## [$v]' section for $t" >&2
    return 1
  fi
  subject=$(git log -1 --format=%s "$t")
  subject="${subject% (#*)}" # a squash merge adds the PR number
  if [[ "$subject" =~ ^Release\ [0-9][^\ ]*\ -\ (.+)$ ]]; then title="$t - ${BASH_REMATCH[1]}"; else title="$t"; fi
  file=$(mktemp)
  notes "$v" > "$file"
  run gh release create "$t" --title "$title" --notes-file "$file" --verify-tag "$@"
  rm -f "$file"
  echo "$t: ${DRY_RUN:+would be }released ($title)"
}

if [ -z "$tag" ]; then
  version=$(sed -n 's/^  @version "\(.*\)"$/\1/p' mix.exs)
  [ -n "$version" ] || { echo "::error::no @version in mix.exs" >&2; exit 1; }
  package_version=$(sed -n 's/^  "version": "\(.*\)",$/\1/p' package.json)
  [ "$package_version" = "$version" ] || { echo "::error::package.json has version '$package_version', mix.exs has '$version'" >&2; exit 1; }
  tag="v$version"
  if ! git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
    has_notes "$version" || { echo "::error::CHANGELOG.md has no '## [$version]' section; not tagging $tag" >&2; exit 1; }
    # the commit that set this version (the release commit), else HEAD
    commit=$(git log -1 --format=%H -S "@version \"$version\"" -- mix.exs)
    commit=${commit:-$(git rev-parse HEAD)}
    run git tag "$tag" "$commit"
    run git push origin "$tag"
    echo "$tag: ${DRY_RUN:+would be }tagged at $(git rev-parse --short "$commit")"
  fi
fi

if [ -n "${DRY_RUN:-}" ] && ! git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
  echo "$tag: would release once tagged"
else
  release "$tag"
fi

if $backfill; then
  status=0
  for t in $(git tag -l 'v*' --sort=v:refname); do
    [ "$t" = "$tag" ] && continue
    # an older version created today mustn't become the repo's "Latest"
    release "$t" --latest=false || status=1
  done
  exit $status
fi
