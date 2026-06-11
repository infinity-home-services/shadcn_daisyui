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

Pure CSS, two rules (no JS):

1. every element gets a color transition (covers bare surfaces/text daisyUI
   leaves with none), in `@layer base` so components keep *which* properties
   they animate;
2. a duration pin (`transition-duration: var(--theme-transition) !important`)
   normalizes daisyUI's mixed per-component durations (0.2–0.3s) to the shared
   value so colors finish together — and it **excludes** components that have
   their own animations (dialog, drawer, tooltip, carousel, skeleton, countdown,
   …) so those keep their natural timing.

- NEVER add `transition-*`/`duration-*` utilities or CSS to make theme changes
  smooth — it's automatic. Giving a component its own color-transition duration
  is what causes the out-of-sync flicker.
- The single knob is `--theme-transition` (default 150ms) on `:root`/your theme
  block.
- Toggle themes only by changing `data-theme` on `<html>` (Phoenix's
  `phx:set-theme` does this) — not by swapping stylesheets or other classes.
