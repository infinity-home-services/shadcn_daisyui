# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
(0.x: minor versions may contain breaking changes, noted explicitly).

## [Unreleased]

## [0.6.0] - 2026-10-09

Dark-mode and CSP parity with shadcn-svelte's neutral dark theme
(`registry-base-colors.ts`, `style-vega.css` and its popover, dropdown-menu,
dialog, sheet, select, tooltip and command components). The shadcn token values
themselves are unchanged - they already matched. See the new **Dark mode & CSP**
docs page (`/docs/dark-mode`) for every change side by side in light and dark.

### Breaking

- **Requires `phoenix_live_view ~> 1.1`** (was `~> 1.0`). The overlay components
  now open/close through `Phoenix.LiveView.JS` and keep `open` with
  `JS.ignore_attributes/1`, both of which need 1.1. The page must call
  `liveSocket.connect()` (Phoenix's default `app.js` does; LiveView 1.1 runs JS
  commands on dead views too). Without a LiveSocket, open dialogs with
  `el.showModal()` or invoker commands (`<button commandfor="id" command="show-modal">`).
- **Brand themes generated before 0.6.0** carry a copy of the old dark block, so
  they keep the old dark field fill and base-200/base-300. To adopt the fixes,
  replace these three lines in your `[data-theme="<brand>-dark"]` block:
  `--input-background: color-mix(in oklab, var(--input) 30%, transparent);`,
  `--color-base-200: var(--muted);`, `--color-base-300: var(--border-color);`
  (or regenerate with `mix shadcn_daisyui.gen.theme`).

### Changed

- **Dark form fields** use shadcn's `dark:bg-input/30`.
  `--input-background` (dark): `var(--background)` (oklch 0.145, darker than
  cards and popovers) → `color-mix(in oklab, var(--input) 30%, transparent)`.
  Applies to `.input`, `.select`, `.textarea`, `.file-input`, the
  `<.select>` / `<.combobox>` / date-picker / date-range triggers and the OTP
  slots, on the page, on cards and inside sheets, dialogs and popovers. Light
  mode is unchanged.
- **Custom select / combobox / date-picker / date-range triggers**: border
  `var(--border-color)` → `var(--input)` (the field border; identical in light,
  white/10% → white/15% in dark); dark hover `var(--accent)` →
  `color-mix(in oklab, var(--input) 50%, transparent)` (shadcn `dark:hover:bg-input/50`).
- **OTP slot**: background `transparent` → `var(--input-background)`, and it now
  carries `shadow-xs` like the other fields.
- **`--color-base-200` (dark)**: `oklch(0.205 0 0)` → `var(--muted)` (0.269).
  It equalled `--card`/`--popover`, so `bg-base-200` hover and selected fills were
  invisible on cards and in popovers. Side effects: daisyUI's plain `.btn`,
  zebra rows, pinned table columns and disabled fields step up to 0.269 too.
- **`--color-base-300` (dark)**: `oklch(0.269 0 0)` → `var(--border-color)`
  (`oklch(1 0 0 / 10%)`), so `border-base-300` matches shadcn's translucent
  border. Nothing in the package uses base-300 as a fill except daisyUI's
  `.avatar-offline` dot, which is now pinned to `var(--muted)` in dark (it would
  have gone see-through), and the drawer grab handle, now `bg-muted`. Zebra-row
  hover and daisyUI tab borders become translucent, as intended.
- **One modal backdrop**: `.modal` `oklch(0 0 0 / 0.4)` and the `dialog.sheet`,
  `dialog.drawer-bottom`, `dialog.command-dialog` `::backdrop`s
  `rgb(0 0 0 / 0.5)` → all `oklch(0 0 0 / 0.5)`. This follows shadcn/ui's
  `bg-black/50` rather than vega's `bg-black/10` + `backdrop-blur-xs`: blur
  repaints everything behind the overlay on every frame of the 300ms
  sheet/drawer slide, and black/10 leaves too little separation for the flat
  surfaces this package uses elsewhere.
- **Floating content** (`.dropdown-content.menu`, non-menu `.dropdown-content`
  popovers, `.popover-panel` select/combobox/date panels, `.context-menu`):
  `1px solid var(--border-color)` + `shadow-sm` → no border, a 1px
  `ring-foreground/10` (`0 0 0 1px color-mix(in oklab, var(--foreground) 10%, transparent)`)
  + `shadow-md` (`0 4px 6px -1px / 0 2px 4px -2px`, 10% black).
- **`.modal-box`**: `rounded-lg` + 1px border + `shadow-sm` → `rounded-xl`, the
  same 1px ring, `shadow-lg`.
- **Command dialog**: `rounded-lg` + 1px border + `shadow-sm` → `rounded-xl`,
  ring, `shadow-lg` (vega's `rounded-xl` command dialog).
- **Sheet and drawer**: `shadow-sm` → `shadow-lg` (shadcn's sheet).
- **Tooltip**: background `var(--primary)` / text `var(--primary-foreground)` →
  `var(--foreground)` / `var(--background)` (`bg-foreground text-background`).
- New shadow tokens `--shadow-md` and `--shadow-lg` (Tailwind v4 values) beside
  `--shadow-xs`/`--shadow-sm`.
- Usage rules: the elevation ladder (`styles-shape-elevation.md`) now has a
  floating level (`shadow-md` + ring) and an overlay level (`bg-black/50` +
  `shadow-lg`); popovers and menus are `rounded-md` and dialogs `rounded-xl`, as
  the CSS already rendered. `styles-color.md`, the main Theme tokens section and
  the recipes now say `border-border` for borders, `bg-muted`/`bg-accent` for
  hover and selected states, and never `bg-base-300` as a fill.

### Fixed

- **Strict CSP**: no component renders an inline event handler any more, so they
  work under `script-src 'self' 'nonce-…'`. `<.dialog>`, `<.sheet>`, `<.drawer>`
  and `<.command>` triggers use `phx-click={show_modal(id)}`, the sheet's close
  button `hide_modal(id)`, and backdrop-click closing moved from per-element
  `onclick` into one delegated listener in `shadcn-daisyui.js` (for `.sheet`,
  `.drawer-bottom`, `.command-dialog`). Esc still closes natively.
- Clicking a sheet's or drawer's own padding no longer closes it. The old inline
  check (`event.target === this`) treated the panel's padding as backdrop; the
  listener now compares the click point with the panel rect.
- Every modal `<dialog>` carries `phx-mounted={JS.ignore_attributes(["open"])}`,
  so an open dialog stays open when a LiveView patch re-renders it.
- Docs recipes for dialog, alert dialog, sheet, drawer and command open/close
  with invoker commands (`commandfor` / `command`) instead of `onclick`.
- Docs site: the theme toggle no longer reverts to light on every page load (the
  root layout hardcoded `data-theme`, which made the stored choice unreachable).

### Docs

- New `/docs/dark-mode` page: the before/after table above, fields on page / card
  / popover, hover and selected fills, floating surfaces and all four overlays in
  light and dark, served under a strict nonce CSP (header + meta tag) with a live
  violation counter and an inline-handler canary that must be blocked.
- New `/lab/csp` LiveView (not part of the static export): overlays under the
  same policy, re-rendered every 500ms, to show an open dialog survives patches.

## [0.5.0] - 2026-10-04

### Added

Seven components shadcn-svelte added since this package was set up, matching its
default ("vega") style. The composition components are styled by `data-slot` /
`data-variant` attributes like upstream (zero-specificity selectors, so a utility
class on the element always wins), and each has a docs page with Specs,
Accessibility, and SwiftUI sections.

- **Item** - `<.item>`, `<.item_group>`, `<.item_separator>`: a row with media
  (`icon` / `image`), title, description, actions, and optional header/footer;
  `variant="default|outline|muted"`, `size="default|sm|xs"`, `href`/`navigate`/
  `patch` turn the row into a link.
- **Attachment** - `<.attachment>`, `<.attachment_group>`, `<.attachment_action>`:
  a file or image tile with `state="idle|uploading|processing|error|done"` (dashed,
  shimmering, dimmed, or destructive-tinted), three sizes, horizontal/vertical
  orientation, labeled icon actions, and an optional full-tile `<:trigger>`.
- **Message** - `<.message>`, `<.message_group>`: a conversation turn with avatar,
  header, content, footer, and `align="start|end"`.
- **Bubble** - `<.bubble>`, `<.bubble_group>`: seven variants (default, secondary,
  muted, tinted, outline, ghost, destructive), alignment, edge reactions, and
  `as="button"` / `as="a"` for suggested replies.
- **Marker** - `<.marker>`: an inline transcript line (default, separator, border)
  with an icon slot, `status` (role=status), and `shimmer`. Also ships a `.shimmer`
  utility class (respects reduced motion).
- **Sonner** - a real toast system replacing the docs-only `showToast()` stub:
  `toast()` / `toast.success|info|warning|error|loading()` / `toast.promise()` /
  `toast.dismiss()` exported from `shadcn-daisyui.js`, with descriptions, action
  and cancel buttons, per-toast position, a collapsed stack that expands on hover or
  focus, pause-on-hover timers, swipe to dismiss, and the Alt+T hotkey. Render
  `<.toaster />` (options: `position`, `rich_colors`, `close_button`, `expand`,
  `duration`) once in the root layout; from a LiveView use
  `push_toast(socket, "Saved", type: :success, action: %{label: "Undo", event: "undo"})`
  (needs the new `ShadcnToaster` hook).
- **Range Calendar** - `<.range_calendar>`: an inline date-range calendar (1 or 2
  months) that binds to two form fields via `start_name` / `end_name` (ISO dates in
  hidden inputs that dispatch `input` + `change`) and emits a `range-change` event.
  New `ShadcnRangeCalendar` hook.


### Changed

- **Surface-color guidance now matches shadcn and the theme CSS.** The rules said
  `bg-base-100` was for "page and cards", but in `shadcn-dark` `--background`
  (oklch 0.145) is darker than `--card` / `--popover` (oklch 0.205), so apps
  following them painted card-level surfaces darker than cards. `usage-rules.md`
  and `usage-rules/styles-color.md` now give each surface one role: page
  `bg-base-100` / `bg-background`; cards and opaque fills inside a card `bg-card`;
  overlays (sheets, dialogs, popovers, dropdown/command content) `bg-popover` +
  `text-popover-foreground`; subtle insets `bg-base-200` / `bg-muted`. New rule: a
  sticky `<thead>` (or sticky footer bar) inside a card uses `bg-card`, since the
  table header has no fill of its own. The token → SwiftUI table gains `sdCard` and
  `sdPopover` rows, and the docs-site examples that used `bg-base-100` for cards
  and dialog mocks now use `bg-card` / `bg-popover`.
- **Every calendar is keyboard navigable.** `<.calendar>`, `<.date_picker>`,
  `<.date_range>`, and `<.range_calendar>` now use a single roving tab stop with
  Arrow keys (day/week), Home/End (week edges), and PageUp/PageDown (month; Shift
  for year), the view following focus across months; day cells get the 3px focus
  ring and the month buttons get `aria-label`s.
- **Deprecated: `<.toast_host>` and `showToast()`.** `toast_host/1` now renders a
  `<.toaster>` (keeping the `toast-host` id) and `showToast(variant)` calls
  `toast()`, so existing layouts and calls keep working; move to `<.toaster />` and
  `toast()`. The docs-site Toast page is now Sonner (`/docs/components/toast`
  redirects).
- **`.drawer-side` panels use the popover surface.** `.drawer-side > .menu` and
  `.drawer-side > :where(aside, nav, div)` now paint `--popover` /
  `--popover-foreground` (was `--background` / `--foreground`), matching
  `dialog.sheet`, since a drawer slides over content. A persistent app sidebar
  should use `<.sidebar_layout>`, which stays on the page surface.

## [0.4.0] - 2026-10-04

### Upgrading from 0.3

The theme-toggle transition guard is now scoped to theme swaps (see Changed), so
anything that sets `data-theme` directly will fade-flicker on light/dark swap.
Re-run `mix shadcn_daisyui.install` (idempotent) - it now wraps Phoenix 1.8's
stock theme script in the guard - or switch your toggle to `setTheme` from
`shadcn-daisyui.js`. A hand-written theme script needs the same wrap:

```js
const setTheme = (theme) => {
  document.documentElement.classList.add("theme-transition");
  // ... set or remove data-theme as before ...
  requestAnimationFrame(() =>
    requestAnimationFrame(() => document.documentElement.classList.remove("theme-transition"))
  );
};
```

### Added

- **`priv/tokens.json`** - a machine-readable single source of truth for the
  color tokens (name, light value, dark value, role group), mirroring the values
  in `priv/static/shadcn-daisyui.css`. Intended to power a Tokens reference page,
  per-component specs, and the Swift-package sync. An agreement test in the demo
  fails CI if the JSON and the CSS drift apart.
- **Validated docs catalog schema** - the docs-site component catalog is now
  built through a `Catalog.Spec` struct that enforces required fields and rejects
  unknown/typo'd keys, with a test suite (schema validation, sidebar-group
  coverage, render-every-component-page) that fails CI on drift.
- **Per-component Specs, Accessibility, and Native (SwiftUI) sections** across all
  77 components in the docs site. Specs render anatomy, token-expressed
  measurements, and the tokens a component consumes as live color swatches;
  Accessibility renders the keyboard map plus role/ARIA, focus, screen-reader,
  touch-target, and reduced-motion notes (grounded in each component's real markup
  and JS); Native shows the SwiftUI equivalent with an honest parity badge
  (`ios_status`). All three are schema-validated and exported to the AI markdown /
  `design-guidelines.md` bundle. Design metadata lives in per-group enrichment
  files (`catalog/enrichment/*.ex`) merged onto the base catalog by slug.
- **Tokens reference page** (`/docs/tokens`) - every color token grouped by role,
  shown as light/dark swatch pairs with OKLCH values, read from `priv/tokens.json`.
- **Visual polish:** labeled SVG anatomy diagrams (numbered to match the anatomy
  list) on Button, Input, and Card; rendered Do/Don't example pairs on Button,
  Input, and Dialog; and interactive "Replay" motion demos on the Motion
  guidelines page driven by the Web Animations API (so they survive the
  instant-theme transition guard). Do/Don't pairs are schema-validated and
  exported to the AI markdown.
- **`setTheme(theme)` export in `shadcn-daisyui.js`** - switches the active theme
  flicker-free by adding the `theme-transition` class, swapping `data-theme`, and
  dropping the class on the next frame. Wire it to your theme control (or the
  standard `phx:set-theme` event) instead of setting `data-theme` directly.
- **`<.select>` and `<.combobox>` are now form-bindable.** Pass `name` (and
  `value`) and the component emits a hidden `<input>` the JS hook keeps in sync
  (dispatching `input` + `change` so LiveView `phx-change` fires), so the
  shadcn-style dropdowns can back a real changeset field. A preselected `value` is
  reflected in the trigger on mount, so edit forms show the current selection. Also
  fixes the combobox check icon, which never toggled (it queried `svg`, but the
  mark is a `hero-check` span).

### Changed

- **Repository moved to the `infinity-home-services` GitHub organization.** All
  three repos (`shadcn_daisyui`, `shadcn_daisyui_swift`, `shadcn_daisyui_design`)
  now live under `github.com/infinity-home-services`. Updated the package
  `@source_url`, install snippets in the README and docs site, the Pages URL
  (`infinity-home-services.github.io/shadcn_daisyui`), and the cross-repo
  references in the "Sync design guidelines" CI workflow. GitHub redirects the old
  `N00nDay/*` URLs for reads, but pushes and the design-sync workflow require the
  new owner. (The `SYNC_TOKEN` secret must be reissued as a fine-grained PAT scoped
  to the new org's consumer repos.)
- **Docs-site navigation & component pages.** The catalog sidebar now groups
  components by function (Forms & inputs, Actions, Navigation, Overlays, Feedback
  & status, Data display, Layout), alphabetized within each group, and every
  component page splits its content into Usage and Design & specs tabs.
- **`usage-rules.md`: documented the `context-menu` and bottom-`dock` recipes**
  (previously shipped in the JS/demo but absent from the consuming-app rules), and
  clarified that the `ShadcnDataTable` JS hook is docs-demo only - apps build data
  tables with `<.table>` + LiveView events.
- **Layout guidelines: content-width rationale + a dense/data-entry-form
  exception.** `usage-rules/foundations-layout.md` now explains *why* prose and
  forms are width-capped (the readable measure, not the container) and sanctions a
  wider `max-w-2xl`-`max-w-4xl` two-column field grid for data-entry-heavy forms
  (service tickets, work orders) on medium/expanded screens, while keeping the
  single-column `max-w-md` default for short/sequential forms and all compact
  screens.
- **Theme-toggle transition guard is now scoped, not global.** The rule that
  zeroes out `transition-duration` previously applied to every element at all
  times, silently killing any consumer hover/focus/micro transitions. It now fires
  only while `<html>` carries the `theme-transition` class (added for the duration
  of a swap by `setTheme`), so the toggle stays flicker-free while ordinary
  transitions work again. Apps that switch the theme by setting `data-theme`
  directly should move to `setTheme` to keep the swap from fading.
- **`mix shadcn_daisyui.install` patches Phoenix's stock theme script.** For root
  layouts using Phoenix 1.8's inline `phx:set-theme` script, the installer now
  wraps its `setTheme` in the `theme-transition` guard (add the class, swap
  `data-theme`, remove it after the next frame) instead of leaving the layout
  untouched. Already-guarded scripts are left alone.
- **Form controls no longer hard-set `background-color: transparent`.** `.input`,
  `.textarea`, `.select`, and `.file-input` (plus the custom `<.select>` /
  `<.combobox>` triggers) now use `var(--input-background)`, which defaults to
  `var(--background)`, so fields stay legible on tinted surfaces (e.g. inside a
  `.modal-box`). Retint all fields by overriding `--input-background` (per app or
  per `[data-theme]`); a one-off `bg-*` utility still needs `!` since the base
  rule lives in `@layer utilities`.

## [0.3.0] - 2026-06-11

### Added

- **Design guidelines layer** - ten platform-portable guideline files under
  `usage-rules/` covering Foundations (platforms, accessibility & content,
  layout, spacing, navigation, interaction) and Styles (color usage, typography
  & icons, shape & elevation, motion). Each file pairs terse agent rules with
  reference tables in dual units (rem/px for web, pt for iOS/iPadOS), tagged
  `[web]`/`[ios]` where platform-specific. `usage-rules.md` gains a
  "Design guidelines" section inlining the load-bearing values and indexing the
  files; ExDoc groups them under Foundations/Styles.

### Changed

- **Theme toggle is now instant** (no color fade). Fading between light and dark
  inherently flickers: a fading background sweeps through the lightness of the
  text/borders in front of it, so they cross at a gray midpoint and briefly lose
  contrast (text vanishes, borders trail). No fade - however synchronized -
  avoids that, so the theme switches instantly instead (flicker-free, like
  Tailwind's and GitHub's sites). One CSS rule forces `transition-duration: 0` on
  every element except the components whose own enter/exit animations must stay
  (dialog, drawer, tooltip, carousel, skeleton, countdown). Replaces the earlier
  JS transition window and the synchronized-CSS-fade attempts, both of which
  hit this inherent crossover. Hover/focus color changes are instant too (the
  cost of doing it without a JS guard).
- Docs site now imports the theme CSS/JS straight from the package source
  instead of keeping copies that drift.

## [0.2.0] - 2026-06-11

### Added

- `usage-rules.md` (+ `usage-rules/forms.md`, `usage-rules/theming.md`) - design-system
  rules consuming apps sync into their `AGENTS.md`/`CLAUDE.md` via the `usage_rules` package.
- `ShadcnDaisyui.FormComponents` - `Phoenix.HTML.FormField`-aware `input`, `checkbox`,
  `switch`, `radio_group`, `textarea`, `native_select`, `field`, `error` with
  configurable error translation (`config :shadcn_daisyui, :translate_error, {Mod, :fun}`).
- `ShadcnDaisyui.CoreComponents` - drop-in replacement for Phoenix 1.8 generated
  core components (`input`, `button`, `error`, `header`, `table`, `list`, `icon`,
  `flash`, `flash_group`) styled by the theme; generators work unmodified.
- New function components: dialog/modal, dropdown_menu, tabs, tooltip, accordion,
  breadcrumb, pagination, avatar, progress, skeleton, sheet, drawer, command,
  popover, sidebar, toast/flash bridge.
- `mix shadcn_daisyui.gen.theme NAME` - generates a brand theme override file
  (`[data-theme="NAME"]` / `"NAME-dark"`) and wires it into `app.css`.
- `mix shadcn_daisyui.upgrade` - refresh copied assets for `--copy` installs.
- Package test suite (component render tests, form field tests, installer patcher tests).
- Docs site: `/llms.txt`, `/llms-full.txt`, `/docs/components/:slug.md` markdown
  endpoints and a Cmd+K search palette.
- `package.json` so esbuild resolves `import { Hooks } from "shadcn_daisyui"` from deps.

### Changed

- **Breaking:** `mix shadcn_daisyui.install` now defaults to importing CSS/JS from
  `deps/` (upgradable via `mix deps.update`) instead of copying into `assets/`.
  Use `--copy` for the old behavior; `mix shadcn_daisyui.upgrade` refreshes copies.
- Installer now patches `assets/js/app.js` (hook registration) and the root layout
  (`data-theme`) automatically - no manual steps for a standard Phoenix 1.8 app.

## [0.1.0] - 2026-06-10

### Added

- Initial release: daisyUI v5 theme that reproduces shadcn/ui (neutral OKLCH palette,
  light `shadcn` + dark `shadcn-dark` themes, shadcn metrics override layer).
- 26 Phoenix function components (`ShadcnDaisyui.Components`), including interactive
  calendar, date picker/range, combobox, select, OTP input, carousel, resizable.
- Vanilla-JS interactivity: `initShadcnDaisyui()` for dead views + LiveView `Hooks`.
- `mix shadcn_daisyui.install` - copies assets and patches `app.css`.
- Docs/demo site (`demo/`) with 77-component gallery, installation and theming guides,
  interactive theme creator; static export + GitHub Pages deploy.
