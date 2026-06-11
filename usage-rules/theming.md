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

The theme CSS gives every element one always-on color transition at a single
shared duration + easing, and normalizes daisyUI's per-component durations
(`!important`) onto that token. So a theme toggle moves every color in lockstep.
It's pure CSS — no JS, no class, no timing window — so it cannot desync.

- NEVER add `transition-*`/`duration-*` utilities or CSS to make theme changes
  smooth — it's automatic. Adding a different color-transition duration to a
  component is exactly what causes the out-of-sync flicker.
- The only knobs are `--theme-transition` (duration, default 150ms; `0ms`
  disables) and `--theme-transition-ease` on `:root`/your theme block. This is
  the one motion-duration token for the whole UI, interaction states included.
- Movement utilities/animations (a `transition-[left]` slider, a dialog's
  `transform`) keep their own property and just adopt the token duration — fine.
  If one element genuinely needs a different duration, set it with `!important`.
- Toggle themes only by changing `data-theme` on `<html>` (Phoenix's
  `phx:set-theme` does this) — not by swapping stylesheets or other classes.
