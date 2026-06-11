# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
(0.x: minor versions may contain breaking changes, noted explicitly).

## [Unreleased]

### Added

- **Design guidelines layer** — ten platform-portable guideline files under
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
  contrast (text vanishes, borders trail). No fade — however synchronized —
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

- `usage-rules.md` (+ `usage-rules/forms.md`, `usage-rules/theming.md`) — design-system
  rules consuming apps sync into their `AGENTS.md`/`CLAUDE.md` via the `usage_rules` package.
- `ShadcnDaisyui.FormComponents` — `Phoenix.HTML.FormField`-aware `input`, `checkbox`,
  `switch`, `radio_group`, `textarea`, `native_select`, `field`, `error` with
  configurable error translation (`config :shadcn_daisyui, :translate_error, {Mod, :fun}`).
- `ShadcnDaisyui.CoreComponents` — drop-in replacement for Phoenix 1.8 generated
  core components (`input`, `button`, `error`, `header`, `table`, `list`, `icon`,
  `flash`, `flash_group`) styled by the theme; generators work unmodified.
- New function components: dialog/modal, dropdown_menu, tabs, tooltip, accordion,
  breadcrumb, pagination, avatar, progress, skeleton, sheet, drawer, command,
  popover, sidebar, toast/flash bridge.
- `mix shadcn_daisyui.gen.theme NAME` — generates a brand theme override file
  (`[data-theme="NAME"]` / `"NAME-dark"`) and wires it into `app.css`.
- `mix shadcn_daisyui.upgrade` — refresh copied assets for `--copy` installs.
- Package test suite (component render tests, form field tests, installer patcher tests).
- Docs site: `/llms.txt`, `/llms-full.txt`, `/docs/components/:slug.md` markdown
  endpoints and a Cmd+K search palette.
- `package.json` so esbuild resolves `import { Hooks } from "shadcn_daisyui"` from deps.

### Changed

- **Breaking:** `mix shadcn_daisyui.install` now defaults to importing CSS/JS from
  `deps/` (upgradable via `mix deps.update`) instead of copying into `assets/`.
  Use `--copy` for the old behavior; `mix shadcn_daisyui.upgrade` refreshes copies.
- Installer now patches `assets/js/app.js` (hook registration) and the root layout
  (`data-theme`) automatically — no manual steps for a standard Phoenix 1.8 app.

## [0.1.0] - 2026-06-10

### Added

- Initial release: daisyUI v5 theme that reproduces shadcn/ui (neutral OKLCH palette,
  light `shadcn` + dark `shadcn-dark` themes, shadcn metrics override layer).
- 26 Phoenix function components (`ShadcnDaisyui.Components`), including interactive
  calendar, date picker/range, combobox, select, OTP input, carousel, resizable.
- Vanilla-JS interactivity: `initShadcnDaisyui()` for dead views + LiveView `Hooks`.
- `mix shadcn_daisyui.install` — copies assets and patches `app.css`.
- Docs/demo site (`demo/`) with 77-component gallery, installation and theming guides,
  interactive theme creator; static export + GitHub Pages deploy.
