# Working on shadcn_daisyui (the package)

This file is for agents developing the package itself. (Rules for *consuming* the
package live in `usage-rules.md` and are synced into consuming apps. The demo app has
its own `demo/AGENTS.md` with general Phoenix/Elixir guidelines.)

## What this is

A Hex package that makes daisyUI v5 look and behave like shadcn/ui in Phoenix:

- `priv/static/shadcn-daisyui.css` - the entire theme: OKLCH bridge tokens,
  daisyUI semantic mapping, `@theme inline` Tailwind utilities, and a
  `@layer utilities` override layer with shadcn metrics. Single self-contained file.
- `priv/static/shadcn-daisyui.js` - vanilla-JS interactivity: `initShadcnDaisyui()`
  for dead views and LiveView `Hooks` (one `Shadcn*` hook per interactive component).
- `priv/static/shadcn-daisyui-charts.js` - the optional chart kit's entry
  (`shadcn_daisyui/charts` through `package.json`'s `exports`): `ChartHooks`
  (`ShadcnChart`, one hook for every chart) and `initCharts()`. It imports
  Chart.js from `priv/static/vendor/` (pinned; see its README).
- `lib/shadcn_daisyui/` - Phoenix function components (`Components`,
  `FormComponents`, `CoreComponents`) and install/generator Mix tasks.
- `demo/` - separate Phoenix app: the docs site (catalog of all components with
  preview + code tabs), statically exported to GitHub Pages via `mix site.export`.

## Invariants

- **The package stays neutral.** No company or app brand tokens here - brands are
  separate theme packages/files layered via `[data-theme]` overrides.
- **CSS overrides live in `@layer utilities`** and must come after the daisyUI
  plugin in import order; daisyUI v5 emits there, same layer + later source wins.
- **daisyUI owns `--border` as a width**; the shadcn border *color* is
  `--border-color`. Don't confuse them.
- **Components are thin.** Styling belongs in the theme CSS, not in long class
  lists inside components. A component exists to encode structure/ARIA/hook markup.
- **Theme toggle is INSTANT (scoped CSS guard + `setTheme`).** Fading between
  light and dark inherently flickers - a fading background sweeps through the
  lightness of the text/borders in front of it, so they cross at a gray midpoint
  and lose contrast. No fade survives that, so one `html.theme-transition
  :not(...)` rule at the bottom of `shadcn-daisyui.css` forces
  `transition-duration: 0` on every non-excluded element, but only while `<html>`
  has the `theme-transition` class. `setTheme(theme)` (exported from
  `shadcn-daisyui.js`) adds the class, swaps `data-theme`, and removes the class
  on the next frame, so the swap is instant while hover/focus/micro transitions
  stay live the rest of the time. The `:not(...)` exclusion list (dialog,
  drawer, tooltip, carousel, skeleton, countdown) keeps those components' own
  enter/exit animations. Anything that sets `data-theme` must go through this
  guard (the demo's root layout and the installer-patched Phoenix theme script
  both do); don't reintroduce a color fade for theme changes or make the rule
  global again (that kills consumer transitions).
- **`shadcn-daisyui.js` stays free of outside code.** Chart.js is loaded only
  by the charts entry, from the vendored copy - never a CDN, never an npm
  dependency. Re-vendor with `scripts/vendor_chartjs.sh VERSION` (a pnpm fetch,
  so the machine's release-age and other gates apply; the script records the
  version, integrity and its one rewrite in `priv/static/vendor/README.md`).
- **Charts take their look from the tokens, set once in the hook.** Series are
  `--chart-1…5` in order (validated as a categorical palette, light and dark -
  re-run the check when changing them), text, grid, surface and font come from
  the theme, and the chart redraws on a theme change. Configs from the server
  carry data and structure, never colours.
- **The demo never copies package assets.** `demo/assets` imports
  `../../../priv/static/shadcn-daisyui.{css,js}` (and `shadcn-daisyui-charts.js`)
  directly - copies drift. `/lab/charts` is the chart kit in a LiveView.
- **Every interactive component needs `id`** and renders the exact markup its JS
  hook expects (`data-*` attributes). Keep component HEEx and JS in sync.
- **Public API**: `ShadcnDaisyui.Components`, `ShadcnDaisyui.FormComponents`,
  `ShadcnDaisyui.CoreComponents`, the Mix tasks, the two static assets, and the
  charts entry (`shadcn_daisyui/charts`).
  Anything else is internal.

## Conventions

- Variant/size maps as module attributes (`@variants`, `@sizes`); `attr :class, :any`
  merged last; `attr :rest, :global` passthrough; `@doc` with a copy-pasteable HEEx
  example on every public component.
- Keep `usage-rules.md` in sync when adding/changing components - that file is what
  agents in consuming apps see.
- Add a CHANGELOG entry (Keep a Changelog format) for every user-visible change.
- `mix format` before committing; CI runs `mix format --check-formatted` and tests.

## Commands

```bash
mix deps.get && mix test          # package tests
cd demo && mix setup && mix test  # demo/docs site tests
cd demo && mix phx.server        # docs site at localhost:4000
mix hex.build                     # package dry-run
```

## Changing main

Nothing goes straight to `main`. Every change, a release included, is a branch
from the latest `origin/main`, a pull request, and a squash merge once its
checks are green (`gh pr merge --squash --delete-branch`). A red check gets
fixed on the branch; nothing merges around it. There's no staging: the checks
are the gate.

- `test`: format, tests and `mix hex.build` for the package, format and tests
  for the demo.
- `release-check`: dry-runs `scripts/github_release.sh`, so a version that
  couldn't be released fails before it reaches `main`.

A merge to `main` deploys the docs site and, when the version in `mix.exs` is
new, tags it and creates its GitHub release.

## Releasing

Every version gets a `vX.Y.Z` tag **and** a GitHub release - no gaps (v0.20.0
to v0.23.0 once shipped with tags only). Release with the `/release` skill
(`.claude/skills/release/SKILL.md`): a `release/X.Y.Z` branch with the checks,
the version in `mix.exs` and `package.json`, the `## [X.Y.Z] - date` CHANGELOG
section and a `Release X.Y.Z - summary` commit, then a pull request, merged
once green. Never tag by hand. The Release workflow
(`.github/workflows/release.yml`) runs `scripts/github_release.sh` on every
push to `main`: it tags the version in `mix.exs` if the tag is missing and
creates the GitHub release from the CHANGELOG section if that's missing, and
it fails when the section isn't there. Confirm with `gh release view vX.Y.Z`.

```bash
DRY_RUN=1 scripts/github_release.sh   # what it would tag and release
scripts/github_release.sh --backfill  # releases for older tags that have none
```
