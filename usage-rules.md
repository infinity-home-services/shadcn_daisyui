<!--
usage-rules.md - synced into consuming apps' AGENTS.md / CLAUDE.md via the
`usage_rules` package:  mix usage_rules.sync AGENTS.md --all
Keep this file dense and imperative: it is read by AI coding agents, not humans.
-->

# shadcn_daisyui usage rules

This app's design system is `shadcn_daisyui` - daisyUI v5 themed to look and behave
like shadcn/ui. **Every UI decision goes through this package.**

## Non-negotiables

- ALL UI uses shadcn_daisyui components or themed daisyUI classes. Never hand-roll
  one-off Tailwind component markup (custom buttons, cards, inputs built from raw
  utilities) when a component or class recipe exists below.
- Never enable stock daisyUI themes (`@plugin "daisyui"` must keep `themes: false`)
  and never use daisyUI theme names (`light`, `dark`, `cupcake`, …) in `data-theme`.
- Never regenerate or restyle Phoenix's default `core_components.ex` styling - this
  package provides `ShadcnDaisyui.CoreComponents` as the drop-in replacement.
- Never use raw color utilities (`bg-white`, `text-gray-500`, `bg-zinc-900`,
  `border-neutral-200`, hex/oklch literals) in templates. Use semantic tokens only
  (see Theme tokens).
- Multi-value pickers and filters (status, labels, the data-table faceted filter) are
  `<.select multiple>` (short lists) or `<.combobox multiple>` (long lists, search).
  Never build a checkbox-dropdown by hand.
- Rows that can outgrow their width are `<.tab_nav>` (link tabs → More menu)
  and `<.chip_row>` (removable chips → "+N" popover). Never let a tab or chip
  row wrap or scroll sideways, and never hand-roll an overflow menu.
- Rows that appear and disappear in place (filter chips, inline alerts) slide
  with `<.reveal open={…}>`. Never hand-animate `height` / `max-height`, and
  never `:if` the chip row inside the reveal - `open` drives it, and the chips
  animate in and out on their own.
- Interactive components (combobox, select, date picker, calendar, range calendar,
  OTP, carousel, resizable, command, context-menu, toaster, tab nav, chip row)
  REQUIRE a unique `id` attribute and the JS hooks
  registered on the LiveSocket (`import { Hooks } from "shadcn_daisyui"` …
  `hooks: { ...Hooks }`).
- Never write inline event handlers (`onclick=`, `onsubmit=`, …) or `javascript:`
  URLs - they break under a strict `script-src` CSP. Open/close overlays with
  `phx-click={show_modal("id")}` / `hide_modal("id")` (the components do this
  for you), or in plain HTML with invoker commands
  (`<button commandfor="id" command="show-modal">`, `command="close"`).

## Picking a component

Decision order:

1. **A function component exists → use it.** Import via `use ShadcnDaisyui.Components`
   (and `ShadcnDaisyui.CoreComponents` for form/table/flash, usually already imported
   in the app's `CoreComponents`).
2. **No function component → use the documented daisyUI class recipe** (table below).
   The theme styles every daisyUI class automatically.
3. **Neither exists → compose from tokens + primitives.** Match shadcn/ui metrics:
   `text-sm`, `rounded-md` fields and floating content / `rounded-xl` cards and dialogs,
   1px `border-border` borders, flat surfaces (`shadow-sm` on cards, the overlay
   recipes carry their own elevation), `text-muted-foreground` for secondary text.
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
| `<.sheet>` / `<.drawer>` | `id` req., `<:trigger>` `<:title>` `<:description>` `<:header>` (stays put, e.g. search) + body + `<:footer>` (pinned actions: ghost "Clear all" left, primary `ml-auto grow sm:grow-0`); only the body scrolls, lines show only while content is under the header/footer - never add your own sticky header/footer, borders or shadows; right panel / bottom panel; sheet `size="sm\|default\|lg\|xl"` (20/24/32/40rem from `sm`, 75% on phones, ≤90vw), or a width class (`sm:w-[28rem]`) |
| `<.popover>` | `<:trigger>` + content |
| `<.tooltip>` | `tip="..."` `position="top\|bottom\|left\|right"` wraps trigger |
| `<.dropdown_menu>` | `<:trigger>` `<:label>` `<:item>` slots, `align="start\|end"`; icon-only ⋯ trigger: `trigger_class="btn btn-ghost btn-square btn-sm" chevron={false} aria-label="More actions"`; opt-in item attrs (items without them render as before): `variant="destructive"`, `confirm="Remove Acme Marketing from Pat?"` (`data-confirm`, name the object), `values={%{user_id: …}}` (one `phx-value-<key>` each, wins over `phx-value-id` for its own keys), `id`, `disabled` (`aria-disabled`, no click, 50%); opt-in menu attr `close_on_select` closes it after a choice |
| `<.command>` | `id` req. (hook), `<:trigger_label>`, `<:item group icon shortcut>` slots, ⌘K |
| `<.tabs>` | `id` req., `<:tab label="..." checked>` slots with panel content |
| `<.tab_nav>` | `id` (hook), link tabs `<:tab navigate\|patch active count>`; overflow moves into a More menu that also takes `<:menu_item group icon active navigate\|patch>`; active tab always visible (too narrow for it + More: every tab folds into the menu and More names the active tab + count) |
| `<.breadcrumb>` | `<:item navigate={...}>` slots; last item without link = current page |
| `<.pagination>` | `page` `total_pages` + `path={fn p -> ... end}` or `event="..."` |
| `<.sidebar_layout>` / `<.sidebar_group>` | app shell; `<:sidebar>` slot; items with `active` |
| `<.accordion>` | `id` req., `<:section title="..." open>` slots, `multiple`; opt in to a section card: `<:header>` (content above the rows in the same card: `card_title`, `card_description`, an action) and `flush` (rows edge to edge, 24px inset inside each row, 1px line under the header and between rows) |
| `<.avatar>` / `<.avatar_group>` | `src` or `fallback="JD"`, `shape`, size via `class` |
| `<.progress>` / `<.skeleton>` / `<.spinner>` | sized via `class` |
| `<.toaster>` | once in root layout (`position`, `rich_colors`, `close_button`); toasts via JS `toast()` / `toast.success()` / `toast.promise()` or LiveView `push_toast(socket, msg, type: :success)`; toasts render in the top layer and follow into an open sheet/dialog/drawer/command, so they show above it and stay clickable - never raise them with z-index |
| `<.flash>` / `<.flash_group>` | CoreComponents; renders as a Sonner toast (info = success check, clears after 5s, paused on hover/focus; error stays until closed), above open modals; `position` same values as `<.toaster>` (default `bottom-right`); keep Phoenix's `Layouts.flash_group`, don't override `flash/1` |
| `<.calendar>` | `id` required (hook) |
| `<.date_picker>` | `id` required (hook), `placeholder` |
| `<.date_range>` | `id` (hook), popover range; form-bind with `start_name`/`end_name` + `start`/`end` (ISO dates); `<:preset label start end>` or `<:preset label days={7}>` |
| `<.range_calendar>` | `id` (hook), inline range picker; `months`, `start`/`end`; form-bind with `start_name`/`end_name` (ISO dates) |
| `<.item>` / `<.item_group>` / `<.item_separator>` | row with `<:media variant="icon\|image">` `<:title>` `<:description>` `<:actions>` (`<:header>`/`<:footer>`); `variant="default\|outline\|muted"`, `size="default\|sm\|xs"`, `href`/`navigate` makes it a link |
| `<.attachment>` / `<.attachment_group>` / `<.attachment_action>` | file tile: `state="idle\|uploading\|processing\|error\|done"`, `size`, `orientation`, `<:media>` `<:title>` `<:description>` `<:actions>` `<:trigger label>` |
| `<.message>` / `<.message_group>` | chat turn: `align="start\|end"`, `<:avatar>` `<:header>` `<:footer>`; `role="log"` on the group for live transcripts |
| `<.bubble>` / `<.bubble_group>` | `variant="default\|secondary\|muted\|tinted\|outline\|ghost\|destructive"`, `align`, `as="button"` for suggested replies, `<:reactions label>` |
| `<.marker>` | in-transcript status/note: `variant="default\|separator\|border"`, `status`, `shimmer`, `<:icon>` |
| `<.chip_row>` | `id` (hook), one line of `<:chip value on_remove remove_label>` (badge + ×); overflow collapses into "+N" (popover, each removable); `<:action>` stays visible; `variant="secondary\|outline"`; chips scale/fade in and out and neighbours slide - always pass `value` (it keys the chip) |
| `<.reveal>` | `open` (server-owned) or `id` + `client` with `<button data-reveal-toggle="id">`; slides a row 0fr↔1fr + opacity, 180ms; put spacing in `class`; keep the content rendered (a chip row: no `:if`) and let `open` drive it, so it collapses around the last chip |
| `<.combobox>` / `<.select>` | `id` required (hook), `<:option value="..." count={n}>` slots; form-bind with `field={@form[:x]}` (or `name`/`value`); `multiple` = checkbox rows + Clear, value is a list, posts `x[]` (cleared posts `x=""`); `full_width` in sheets/compact forms |
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

### Class-only recipes (no wrapper - use these exact classes)

| Need | Recipe |
|---|---|
| Tabs | `<div role="tablist" class="tabs tabs-box w-fit">` + `<input type="radio" name="…" class="tab" aria-label="…">` |
| Static table | `<div class="card w-full overflow-hidden"><table class="table">…` |
| Data table (sortable/faceted/paged) | Build with `<.table>` + LiveView `phx-click` sort/filter/page events. The `ShadcnDataTable` JS hook is docs-demo only (fixed dataset) - do not wire it in apps. |
| Sheet sections (raw HTML) | `<dialog class="sheet">` with direct children `.sheet-header` (close button, `h3.sheet-title`, description, `.sheet-header-content`), `.sheet-body` (one wrapper `div` inside), `.sheet-footer`; drawer: `.drawer-handle` `.drawer-header` `.drawer-body` `.drawer-footer` |
| Modal/dialog | native `<dialog id="d" class="modal"><div class="modal-box">…`, opened by `<button commandfor="d" command="show-modal">` (no inline JS); backdrop: `<form method="dialog" class="modal-backdrop"><button>close</button></form>` |
| Tooltip | `<div class="tooltip" data-tip="…">` wrapping the trigger |
| Dropdown | `<div class="dropdown">` + `tabindex="0"` trigger + `<ul class="dropdown-content menu z-50 …">` |
| Context menu | trigger `<div data-context-menu-trigger>` + `<ul data-context-menu class="context-menu hidden">`; needs `id` + `phx-hook="ShadcnContextMenu"` (one per page) |
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
| Headings | `text-3xl font-bold tracking-tight` (h1), `text-xl font-semibold tracking-tight` (h2, often with `border-b border-border pb-2`) |
| Secondary text | `text-sm text-muted-foreground` |
| Page hero | `<div class="hero">`, navbar `<div class="navbar">`, footer `<footer class="footer">` |
| Collapsing row | `<div class="reveal" data-open><div class="reveal-track"><div>…</div></div></div>` (toggle `data-open`; `<button data-reveal-toggle="id">` for dead views) |
| Bottom dock (compact nav) | `<div class="dock"><button class="dock-active"><span class="hero-…"></span><span class="dock-label">…` (3-5 items; mark the current route's button `dock-active`) |

Browse the full gallery (88 components) in the docs site (`demo/`) or
`/docs/components/:slug` - every entry has copy-pasteable markup.

## Theme tokens

- Theme activation: `<html data-theme="shadcn">` (light) / `"shadcn-dark"` (dark).
  Brand themes (e.g. `data-theme="ihs"`) override the same tokens - never bypass them.
- Surfaces (one role each, as in shadcn): page `bg-base-100` / `bg-background`;
  cards and opaque fills inside a card (sticky table header, sticky footer bar)
  `bg-card`; overlays (sheets, dialogs, popovers, dropdown/command content)
  `bg-popover` + `text-popover-foreground`; subtle insets `bg-muted`; hover and
  selected rows/items `bg-accent` (or `bg-muted`); borders `border-border`.
  `bg-base-200` is an alias of muted and `border-base-300` of the border colour -
  in dark mode base-300 is translucent (white/10%), so never use `bg-base-300` as
  a fill. Never paint a card or overlay `bg-base-100` - in dark mode the page is
  darker than cards and popovers.
- A sticky `<thead>` inside a card needs `bg-card` (the table header has no fill
  of its own).
- Stacking: sticky headers / toolbars / bottom bars `z-10`, floating content
  (menus, popovers, picker panels) `z-50`, modals in the top layer, toasts and
  flashes in the top layer above modals (the package handles it). Never use
  arbitrary z values (see `usage-rules/styles-shape-elevation.md`).
- Text: default foreground inherits; secondary text `text-muted-foreground`;
  destructive `text-destructive` / `text-error`.
- Action colors: `btn-primary`, `btn-secondary`, `badge-error`, etc. - daisyUI semantic
  modifiers, all mapped to the theme.
- Status colors: `info`, `success`, `warning`, `error` exist (`alert-success`,
  `text-warning`, …) - use them rather than green/yellow/red utilities.
- Radius comes from the theme (`rounded-md` fields, `rounded-lg` boxes, `rounded-xl`
  cards). Never hardcode pixel radii.
- Dark mode: the `dark:` variant works (mapped to `[data-theme=…-dark]`), but prefer
  tokens that adapt automatically; only use `dark:` for genuinely asymmetric cases.
- See `usage-rules/theming.md` for creating/overriding brand themes.

## Design guidelines

Platform-portable rules (web + native iOS/iPadOS). Load-bearing values:

- Spacing: 4px grid, blessed steps only - 4/8/12/16/24/32/48 (`gap-1/2/3/4/6/8/12`).
  Icon↔label 8px, form fields 16px apart, card interior 24px, page sections 24-48px.
- Window size classes: compact < 640px (phones), medium 640-1023, expanded ≥ 1024.
  Mobile-first: unprefixed = compact, enhance with `sm:`/`lg:`. One column on compact.
- Content widths: shell `max-w-7xl`, prose ~65ch, forms `max-w-md`-`max-w-lg`.
  Gutters `px-4 sm:px-6 lg:px-8`.
- Navigation: compact = bottom dock (3-5 destinations), expanded = sidebar (15rem).
  Primary destinations never hide behind a hamburger. Breadcrumbs ≥ medium only.
- Touch targets: 44pt / 2.75rem minimum effective hit area on touch surfaces.
  `h-9` controls are desktop-fine; compact primary actions use `btn-lg` full-width;
  checkboxes/radios always wrapped in a tappable label row.
- Type ramp: `text-3xl` bold page title, `text-xl` semibold section, `text-base`
  prose, `text-sm` controls/UI (default), `text-xs` labels. Weights: 500 controls,
  600 titles, 700 page title only.
- Motion: 150ms micro states, ~180ms small surfaces, 300ms sheets/drawers;
  opacity/transform only, except the 180ms row reveal (`<.reveal>`); respect
  reduced motion.
- Hover is an enhancement, never a requirement. Disabled = variant colors at 50%
  opacity (never grey-washed).

Full rules (each file: terse `## Rules` + reference tables, `[web]`/`[ios]` tags):

- See `usage-rules/foundations-platforms.md` - dual units, HIG arbitration, token→SwiftUI map
- See `usage-rules/foundations-accessibility.md` - contrast, focus, labels, writing basics
- See `usage-rules/foundations-layout.md` - breakpoints, size classes, scaffold
- See `usage-rules/foundations-spacing.md` - grid, blessed steps, standards table
- See `usage-rules/foundations-navigation.md` - nav per size class, destination limits
- See `usage-rules/foundations-interaction.md` - state ladder, touch targets, dismissal
- See `usage-rules/styles-color.md` - token usage semantics, brand splash rules
- See `usage-rules/styles-typography.md` - type ramp, iconography
- See `usage-rules/styles-shape-elevation.md` - radius roles, elevation ladder
- See `usage-rules/styles-motion.md` - durations, easings, patch guard

## Setup invariants (do not undo)

- `app.css` keeps: `@plugin "…daisyui" { themes: false; }`, the shadcn-daisyui CSS
  import, `@source` covering `deps/shadcn_daisyui/lib`, and the
  `@custom-variant dark (…)` line.
- `app.js` keeps the `Hooks` import and spreads them into the LiveSocket.
- The app's `CoreComponents` module delegates to `ShadcnDaisyui.CoreComponents`;
  override individual functions there if the app needs to, don't fork wholesale.
