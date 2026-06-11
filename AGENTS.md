# Working on shadcn_daisyui (the package)

This file is for agents developing the package itself. (Rules for *consuming* the
package live in `usage-rules.md` and are synced into consuming apps. The demo app has
its own `demo/AGENTS.md` with general Phoenix/Elixir guidelines.)

## What this is

A Hex package that makes daisyUI v5 look and behave like shadcn/ui in Phoenix:

- `priv/static/shadcn-daisyui.css` — the entire theme: OKLCH bridge tokens,
  daisyUI semantic mapping, `@theme inline` Tailwind utilities, and a
  `@layer utilities` override layer with shadcn metrics. Single self-contained file.
- `priv/static/shadcn-daisyui.js` — vanilla-JS interactivity: `initShadcnDaisyui()`
  for dead views and LiveView `Hooks` (one `Shadcn*` hook per interactive component).
- `lib/shadcn_daisyui/` — Phoenix function components (`Components`,
  `FormComponents`, `CoreComponents`) and install/generator Mix tasks.
- `demo/` — separate Phoenix app: the docs site (catalog of all components with
  preview + code tabs), statically exported to GitHub Pages via `mix site.export`.

## Invariants

- **The package stays neutral.** No IHS or other brand tokens here — brands are
  separate theme packages/files layered via `[data-theme]` overrides.
- **CSS overrides live in `@layer utilities`** and must come after the daisyUI
  plugin in import order; daisyUI v5 emits there, same layer + later source wins.
- **daisyUI owns `--border` as a width**; the shadcn border *color* is
  `--border-color`. Don't confuse them.
- **Components are thin.** Styling belongs in the theme CSS, not in long class
  lists inside components. A component exists to encode structure/ARIA/hook markup.
- **Theme transitions are pure CSS (no JS).** At the bottom of
  `shadcn-daisyui.css`, one `:not(...)` rule forces the whole transition spec —
  property list, duration, easing, zero delay — with `!important` on every
  non-excluded element. Forcing the *property list* (not just duration) is the
  point: daisyUI/Tailwind give inconsistent lists (`.card` transitions only
  `outline`, card text omits `color`), so whatever they omit snaps while the
  rest tween — the flicker. The list includes movement props (transform, `left`,
  grid-template-columns/rows) so sliders/switches/accordions still animate. The
  `:not(...)` exclusion list (dialog, drawer, tooltip, carousel, skeleton,
  countdown) keeps the big deliberate animations untouched — never remove an
  entry, and never extend the force to all elements (that crushes those).
- **The demo never copies package assets.** `demo/assets` imports
  `../../../priv/static/shadcn-daisyui.{css,js}` directly — copies drift.
- **Every interactive component needs `id`** and renders the exact markup its JS
  hook expects (`data-*` attributes). Keep component HEEx and JS in sync.
- **Public API**: `ShadcnDaisyui.Components`, `ShadcnDaisyui.FormComponents`,
  `ShadcnDaisyui.CoreComponents`, the Mix tasks, and the two static assets.
  Anything else is internal.

## Conventions

- Variant/size maps as module attributes (`@variants`, `@sizes`); `attr :class, :any`
  merged last; `attr :rest, :global` passthrough; `@doc` with a copy-pasteable HEEx
  example on every public component.
- Keep `usage-rules.md` in sync when adding/changing components — that file is what
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
