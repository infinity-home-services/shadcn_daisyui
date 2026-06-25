# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
(0.x: minor versions may contain breaking changes, noted explicitly).

## [Unreleased]

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
