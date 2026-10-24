---
name: release
description: Cut a shadcn_daisyui release - version bump, changelog, checks, release commit, tag, push, and the GitHub release - so every version has a tag and a GitHub release. Use when asked to release, publish, ship or tag a version, or to "push a release".
---

# Releasing shadcn_daisyui

Every version gets a `vX.Y.Z` tag **and** a GitHub release. The Release
workflow (`.github/workflows/release.yml`, running `scripts/github_release.sh`)
backs this up on every push to `main`: it tags the version in `mix.exs` if the
tag is missing and creates the GitHub release from the CHANGELOG if that's
missing. Still do every step below; the workflow is the safety net, not the
process.

## Steps

1. **Start clean**: on `main`, nothing uncommitted, up to date with
   `origin/main` (`git fetch && git status -sb`).
2. **Checks**: `mix format --check-formatted && mix test` in the root, then the
   same in `demo/`. Don't release on a red suite.
3. **Pick the version**: 0.x - new components or features bump the minor
   (`0.24.0` -> `0.25.0`), fixes only bump the patch (`0.24.1`). Breaking
   changes are allowed in a minor but must be called out in the CHANGELOG.
4. **Bump it in both places**: `@version` in `mix.exs` and `"version"` in
   `package.json`.
5. **CHANGELOG.md**: turn the `## [Unreleased]` content into
   `## [X.Y.Z] - YYYY-MM-DD` (today's date), with a one-paragraph summary
   under the heading, and leave an empty `## [Unreleased]` above it. The
   Release workflow refuses to tag or release a version without its section.
6. **Dry runs**: `mix hex.build` (then delete the `.tar`), and
   `DRY_RUN=1 scripts/github_release.sh` (says what it will tag and release).
7. **No app names**: nothing that names an app using the package (code, docs,
   CHANGELOG, commit messages) - check the diff since the last tag.
8. **Release commit**: `Release X.Y.Z - short summary` (lowercase summary of
   the headline changes; the GitHub release title is built from it), a body
   listing the changes, and the attribution line.
9. **Tag and push**: `git tag vX.Y.Z && git push origin main && git push origin vX.Y.Z`
   (lightweight tag on the release commit, like every earlier tag).
10. **Confirm the GitHub release**: `gh release view vX.Y.Z`. The Release
    workflow creates it within a minute of the push; if it isn't there, check
    the workflow run (`gh run list --workflow Release`) - a missing CHANGELOG
    section is the usual cause - or run `scripts/github_release.sh` yourself.
11. **Watch the runs** for the release commit: CI, Release and Deploy demo
    site should all pass (`gh run list --commit <sha>`).

Apps pin the package by git tag (`tag: "vX.Y.Z"` in their `mix.exs`); say
which version they need to move to.

## Older tags without a release

`scripts/github_release.sh --backfill` (or the Release workflow run by hand
with "backfill") creates releases for every older tag that has none, from its
CHANGELOG section.
