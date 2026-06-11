# shadcn_daisyui — theming rules

## Architecture

One self-contained CSS file (`priv/static/shadcn-daisyui.css`):

1. **Bridge vars** — real shadcn/ui OKLCH tokens (`--background`, `--primary`,
   `--muted-foreground`, `--border-color`, `--radius`, …) declared per theme block:
   `:root, [data-theme="shadcn"]` (light) and `[data-theme="shadcn-dark"], .dark`.
2. **daisyUI mapping** — daisyUI semantic vars (`--color-primary`, `--color-base-100`,
   `--radius-field`, …) point at the bridge vars, so every daisyUI class is themed.
3. **`@theme inline`** — exposes tokens as Tailwind utilities
   (`text-muted-foreground`, `bg-card`, `border-border`, `text-destructive`, …).
4. **Override layer** — `@layer utilities` rules re-stating shadcn metrics
   (h-9 controls, rounded-md, 3px focus ring, flat surfaces).

## Brand themes

A brand theme is two more `[data-theme]` blocks overriding bridge vars — nothing else.
Generate one with:

```bash
mix shadcn_daisyui.gen.theme acme --primary "oklch(0.55 0.2 250)" --radius 0.5rem
```

This writes `assets/css/themes/acme.css` with `[data-theme="acme"]` and
`[data-theme="acme-dark"]`, patches `app.css` (import + dark `@custom-variant`), and
tells you to set `data-theme="acme"` in the root layout.

Rules:

- Override only bridge vars (`--primary`, `--radius`, fonts, chart colors…). Never
  fork or edit the base CSS file.
- Always provide BOTH light and dark blocks; unset vars inherit from the base theme.
- The dark `@custom-variant` in `app.css` must list every `*-dark` theme name.
- IHS apps: use the `ihs_theme` package (`data-theme="ihs"`) — do not re-derive IHS
  brand colors per app.

## Theme switching

- Set `data-theme` on `<html>`. Toggle buttons: `data-phx-theme="shadcn"` /
  `"shadcn-dark"` (or brand equivalents) with the standard Phoenix theme JS.
  Phoenix 1.8's stock `light`/`dark` values are aliased and work too.
- `color-scheme` is set by the theme blocks — don't set it separately.
- Never use `.dark` class toggling as the primary mechanism; it exists only so raw
  shadcn `dark:` utilities work.

## Theme-change transitions (synchronized — do not fight this)

When `data-theme` changes, the bundled JS puts `theme-transitioning` on `<html>`
for one window and the theme CSS forces a SINGLE transition spec on every
element — all colors change at the same duration/easing simultaneously.

- NEVER add `transition-*`/`duration-*` utilities or CSS to make theme changes
  smooth — it's automatic, and per-element transitions are exactly what causes
  out-of-sync flicker. Transition utilities are for interaction states
  (hover/press/open) only.
- The only knobs are `--theme-transition` (duration, default 150ms; `0ms`
  disables) and `--theme-transition-ease` on `:root`/your theme block.
- Don't suppress or reuse the `theme-transitioning` class for other purposes,
  and don't toggle themes by swapping stylesheets or classes other than
  `data-theme` — the watcher only sees `data-theme` on `<html>`.
