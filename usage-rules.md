<!--
usage-rules.md — synced into consuming apps' AGENTS.md / CLAUDE.md via the
`usage_rules` package:  mix usage_rules.sync AGENTS.md --all
Keep this file dense and imperative: it is read by AI coding agents, not humans.
-->

# shadcn_daisyui usage rules

This app's design system is `shadcn_daisyui` — daisyUI v5 themed to look and behave
like shadcn/ui. **Every UI decision goes through this package.**

## Non-negotiables

- ALL UI uses shadcn_daisyui components or themed daisyUI classes. Never hand-roll
  one-off Tailwind component markup (custom buttons, cards, inputs built from raw
  utilities) when a component or class recipe exists below.
- Never enable stock daisyUI themes (`@plugin "daisyui"` must keep `themes: false`)
  and never use daisyUI theme names (`light`, `dark`, `cupcake`, …) in `data-theme`.
- Never regenerate or restyle Phoenix's default `core_components.ex` styling — this
  package provides `ShadcnDaisyui.CoreComponents` as the drop-in replacement.
- Never use raw color utilities (`bg-white`, `text-gray-500`, `bg-zinc-900`,
  `border-neutral-200`, hex/oklch literals) in templates. Use semantic tokens only
  (see Theme tokens).
- Interactive components (combobox, select, date picker, calendar, OTP, carousel,
  resizable, command) REQUIRE a unique `id` attribute and the JS hooks registered
  on the LiveSocket (`import { Hooks } from "shadcn_daisyui"` … `hooks: { ...Hooks }`).

## Picking a component

Decision order:

1. **A function component exists → use it.** Import via `use ShadcnDaisyui.Components`
   (and `ShadcnDaisyui.CoreComponents` for form/table/flash, usually already imported
   in the app's `CoreComponents`).
2. **No function component → use the documented daisyUI class recipe** (table below).
   The theme styles every daisyUI class automatically.
3. **Neither exists → compose from tokens + primitives.** Match shadcn/ui metrics:
   `text-sm`, `rounded-md` fields / `rounded-lg` boxes, 1px `border-base-300` borders,
   flat surfaces with `shadow-sm` at most, `text-muted-foreground` for secondary text.
   Do not invent new colors, radii, or shadows.

### Function components

`use ShadcnDaisyui.Components` imports all of these (plus `ShadcnDaisyui.FormComponents`):

| Component | Signature sketch |
|---|---|
| `<.badge>` | `variant="default\|secondary\|outline\|destructive"` |
| `<.alert>` | `variant="default\|destructive"`, `<:title>` slot |
| `<.card>` / `<.card_body>` / `<.card_title>` / `<.card_description>` | compose |
| `<.separator>` | `orientation="horizontal\|vertical"` |
| `<.dialog>` | `id` req., `<:trigger>` `<:title>` `<:description>` `<:actions>`; open via `show_modal(id)` |
| `<.sheet>` / `<.drawer>` | `id` req., `<:trigger>` + content (right panel / bottom panel) |
| `<.popover>` | `<:trigger>` + content |
| `<.tooltip>` | `tip="..."` `position="top\|bottom\|left\|right"` wraps trigger |
| `<.dropdown_menu>` | `<:trigger>` `<:label>` `<:item>` slots, `align="start\|end"` |
| `<.command>` | `id` req. (hook), `<:trigger_label>`, `<:item group icon shortcut>` slots, ⌘K |
| `<.tabs>` | `id` req., `<:tab label="..." checked>` slots with panel content |
| `<.breadcrumb>` | `<:item navigate={...}>` slots; last item without link = current page |
| `<.pagination>` | `page` `total_pages` + `path={fn p -> ... end}` or `event="..."` |
| `<.sidebar_layout>` / `<.sidebar_group>` | app shell; `<:sidebar>` slot; items with `active` |
| `<.accordion>` | `id` req., `<:section title="..." open>` slots, `multiple` |
| `<.avatar>` / `<.avatar_group>` | `src` or `fallback="JD"`, `shape`, size via `class` |
| `<.progress>` / `<.skeleton>` / `<.spinner>` | sized via `class` |
| `<.toast_host>` | once in root layout; pairs with JS `showToast()` |
| `<.calendar>` | `id` required (hook) |
| `<.date_picker>` / `<.date_range>` | `id` required (hook), `placeholder` |
| `<.combobox>` / `<.select>` | `id` required (hook), `<:option value="...">` slots |
| `<.input_otp>` | `id` (hook), `length`, `group` |
| `<.carousel>` | `id` (hook), `<:slide>` slots |
| `<.resizable>` | `id` (hook), `<:start>` / `<:end_pane>` slots |

From your app's `CoreComponents` (delegating to `ShadcnDaisyui.CoreComponents`):
`<.button>` (variants + `navigate`), `<.input field={...}>`, `<.error>`, `<.header>`,
`<.table id rows>` with `<:col>` slots, `<.list>`, `<.icon name="hero-...">`, `<.flash>`.

### Form components (`ShadcnDaisyui.CoreComponents`)

Always bind form controls to changesets via `Phoenix.HTML.FormField`:

```heex
<.form for={@form} id="user-form" phx-change="validate" phx-submit="save">
  <.input field={@form[:email]} type="email" label="Email" />
  <.input field={@form[:role]} type="select" label="Role" options={["admin", "member"]} />
  <.input field={@form[:active]} type="checkbox" label="Active" />
  <.button phx-disable-with="Saving…">Save</.button>
</.form>
```

- NEVER write raw `<input>` / `<select>` / `<textarea>` inside a `<.form>`.
- Errors render automatically from the field (gated on `used_input?` like Phoenix 1.8).
- `phx.gen.live` / `phx.gen.html` generated templates work unmodified.
- See `usage-rules/forms.md` for the full form rules.

### Class-only recipes (no wrapper — use these exact classes)

| Need | Recipe |
|---|---|
| Tabs | `<div role="tablist" class="tabs tabs-box w-fit">` + `<input type="radio" name="…" class="tab" aria-label="…">` |
| Static table | `<div class="card w-full overflow-hidden"><table class="table">…` |
| Modal/dialog | native `<dialog class="modal"><div class="modal-box">…` + `id.showModal()`; backdrop: `<form method="dialog" class="modal-backdrop"><button>close</button></form>` |
| Tooltip | `<div class="tooltip" data-tip="…">` wrapping the trigger |
| Dropdown | `<div class="dropdown">` + `tabindex="0"` trigger + `<ul class="dropdown-content menu …">` |
| Progress | `<progress class="progress w-full" value="60" max="100">` |
| Skeleton | `<div class="skeleton h-4 w-48">` |
| Spinner | `<span class="loading loading-spinner">` |
| Kbd | `<kbd class="kbd kbd-sm">⌘K</kbd>` |
| Stat blocks | `<div class="stats w-full"><div class="stat"><div class="stat-title">…` |
| Steps | `<ul class="steps"><li class="step step-primary">…` |
| Avatar | `<div class="avatar"><div class="w-10 rounded-full"><img …></div></div>` |
| Breadcrumbs | `<div class="breadcrumbs text-sm"><ul><li>…` |
| Toggle/switch | `<input type="checkbox" class="toggle">` (forms: use `<.input type="checkbox">`) |
| Checkbox | `<input type="checkbox" class="checkbox">` |
| Radio | `<input type="radio" class="radio">` |
| Range slider | `<input type="range" class="range">` |
| Inline code | `<code class="rounded bg-muted px-1.5 py-0.5 font-mono text-sm">` |
| Headings | `text-3xl font-bold tracking-tight` (h1), `text-xl font-semibold tracking-tight` (h2, often with `border-b border-base-300 pb-2`) |
| Secondary text | `text-sm text-muted-foreground` |
| Page hero | `<div class="hero">`, navbar `<div class="navbar">`, footer `<footer class="footer">` |

Browse the full gallery (77 components) in the docs site (`demo/`) or
`/docs/components/:slug` — every entry has copy-pasteable markup.

## Theme tokens

- Theme activation: `<html data-theme="shadcn">` (light) / `"shadcn-dark"` (dark).
  Brand themes (e.g. `data-theme="ihs"`) override the same tokens — never bypass them.
- Surfaces: `bg-base-100` (page/card), `bg-base-200` (subtle), `border-base-300` (borders).
  Also available: `bg-card`, `bg-popover`, `bg-muted`, `border-border`, `bg-background`.
- Text: default foreground inherits; secondary text `text-muted-foreground`;
  destructive `text-destructive` / `text-error`.
- Action colors: `btn-primary`, `btn-secondary`, `badge-error`, etc. — daisyUI semantic
  modifiers, all mapped to the theme.
- Status colors: `info`, `success`, `warning`, `error` exist (`alert-success`,
  `text-warning`, …) — use them rather than green/yellow/red utilities.
- Radius comes from the theme (`rounded-md` fields, `rounded-lg` boxes, `rounded-xl`
  cards). Never hardcode pixel radii.
- Dark mode: the `dark:` variant works (mapped to `[data-theme=…-dark]`), but prefer
  tokens that adapt automatically; only use `dark:` for genuinely asymmetric cases.
- See `usage-rules/theming.md` for creating/overriding brand themes.

## Design guidelines

Platform-portable rules (web + native iOS/iPadOS). Load-bearing values:

- Spacing: 4px grid, blessed steps only — 4/8/12/16/24/32/48 (`gap-1/2/3/4/6/8/12`).
  Icon↔label 8px, form fields 16px apart, card interior 24px, page sections 24–48px.
- Window size classes: compact < 640px (phones), medium 640–1023, expanded ≥ 1024.
  Mobile-first: unprefixed = compact, enhance with `sm:`/`lg:`. One column on compact.
- Content widths: shell `max-w-7xl`, prose ~65ch, forms `max-w-md`–`max-w-lg`.
  Gutters `px-4 sm:px-6 lg:px-8`.
- Navigation: compact = bottom dock (3–5 destinations), expanded = sidebar (15rem).
  Primary destinations never hide behind a hamburger. Breadcrumbs ≥ medium only.
- Touch targets: 44pt / 2.75rem minimum effective hit area on touch surfaces.
  `h-9` controls are desktop-fine; compact primary actions use `btn-lg` full-width;
  checkboxes/radios always wrapped in a tappable label row.
- Type ramp: `text-3xl` bold page title, `text-xl` semibold section, `text-base`
  prose, `text-sm` controls/UI (default), `text-xs` labels. Weights: 500 controls,
  600 titles, 700 page title only.
- Motion: 150ms micro states, ~180ms small surfaces, 300ms sheets/drawers;
  opacity/transform only; respect reduced motion.
- Hover is an enhancement, never a requirement. Disabled = variant colors at 50%
  opacity (never grey-washed).

Full rules (each file: terse `## Rules` + reference tables, `[web]`/`[ios]` tags):

- See `usage-rules/foundations-platforms.md` — dual units, HIG arbitration, token→SwiftUI map
- See `usage-rules/foundations-accessibility.md` — contrast, focus, labels, writing basics
- See `usage-rules/foundations-layout.md` — breakpoints, size classes, scaffold
- See `usage-rules/foundations-spacing.md` — grid, blessed steps, standards table
- See `usage-rules/foundations-navigation.md` — nav per size class, destination limits
- See `usage-rules/foundations-interaction.md` — state ladder, touch targets, dismissal
- See `usage-rules/styles-color.md` — token usage semantics, brand splash rules
- See `usage-rules/styles-typography.md` — type ramp, iconography
- See `usage-rules/styles-shape-elevation.md` — radius roles, elevation ladder
- See `usage-rules/styles-motion.md` — durations, easings, patch guard

## Setup invariants (do not undo)

- `app.css` keeps: `@plugin "…daisyui" { themes: false; }`, the shadcn-daisyui CSS
  import, `@source` covering `deps/shadcn_daisyui/lib`, and the
  `@custom-variant dark (…)` line.
- `app.js` keeps the `Hooks` import and spreads them into the LiveSocket.
- The app's `CoreComponents` module delegates to `ShadcnDaisyui.CoreComponents`;
  override individual functions there if the app needs to, don't fork wholesale.
