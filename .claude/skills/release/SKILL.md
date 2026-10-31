---
name: release
description: Cut a shadcn_daisyui release - a release branch with the version bump and changelog, a pull request, a merge once its checks are green, and the tag and GitHub release that merge produces - so every version is tested and has a tag and a GitHub release. Use when asked to release, publish, ship or tag a version, or to "push a release".
---

# Releasing shadcn_daisyui

Every version gets a `vX.Y.Z` tag **and** a GitHub release, and a release goes
through a pull request like any other change. Merging it is what releases: the
Release workflow (`.github/workflows/release.yml`, running
`scripts/github_release.sh`) runs on every push to `main`, tags the version in
`mix.exs` if the tag is missing and creates the GitHub release from the
CHANGELOG if that's missing. Never tag or push to `main` by hand.

## Steps

1. **Start clean**: nothing uncommitted, then a branch from the latest `main`
   (`git fetch && git switch -c release/X.Y.Z --no-track origin/main`).
2. **Checks**: `mix format --check-formatted && mix test` in the root, then the
   same in `demo/`. Don't open a release on a red suite.
3. **Pick the version**: 0.x - new components or features bump the minor
   (`0.24.0` -> `0.25.0`), fixes only bump the patch (`0.24.1`). Breaking
   changes are allowed in a minor but must be called out in the CHANGELOG.
4. **Bump it in both places**: `@version` in `mix.exs` and `"version"` in
   `package.json`.
5. **CHANGELOG.md**: turn the `## [Unreleased]` content into
   `## [X.Y.Z] - YYYY-MM-DD` (today's date), with a one-paragraph summary
   under the heading, and leave an empty `## [Unreleased]` above it. CI's
   `release-check` fails a version without its section.
6. **Dry runs**: `mix hex.build` (then delete the `.tar`), and
   `DRY_RUN=1 scripts/github_release.sh` (says what it will tag and release).
7. **No app names**: nothing that names an app using the package (code, docs,
   CHANGELOG, commit messages) - check the diff since the last tag.
8. **Release commit**: `Release X.Y.Z - short summary` (lowercase summary of
   the headline changes; the GitHub release title is built from it), a body
   listing the changes, and the attribution line.
9. **Pull request**: `git push -u origin release/X.Y.Z`, then `gh pr create`
   with the release commit's subject as the title and its body as the
   description.
10. **Merge once green**: when the `test` and `release-check` checks pass,
    `gh pr merge --squash --delete-branch`. A red check gets fixed on the
    branch; nothing merges around it.
11. **Confirm the GitHub release**: `gh release view vX.Y.Z`. The Release
    workflow tags the merge commit and creates the release within a minute of
    the merge; if it isn't there, check the workflow run
    (`gh run list --workflow Release`).
12. **Watch the runs** for the merge commit: CI, Release and Deploy demo site
    should all pass (`gh run list --commit <sha>`).

Apps pin the package by git tag (`tag: "vX.Y.Z"` in their `mix.exs`); say
which version they need to move to.

## Older tags without a release

`scripts/github_release.sh --backfill` (or the Release workflow run by hand
with "backfill") creates releases for every older tag that has none, from its
CHANGELOG section.
