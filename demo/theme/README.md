# shadcn-daisyui

A single, self-contained CSS file - [`shadcn-daisyui.css`](./shadcn-daisyui.css) - that makes
[daisyUI v5](https://daisyui.com) components look like [shadcn/ui](https://ui.shadcn.com)
(the **neutral** palette, light + dark). Drop it into any Tailwind v4 + daisyUI v5 project and you
write `btn btn-primary` / `card` / `input` and get the shadcn look.

It does three things:

1. **Tokens** - declares shadcn/ui's real OKLCH values and maps daisyUI's semantic colour variables
   (`--color-primary`, `--color-base-100`, …) onto them, for both a light theme (`shadcn`) and a
   dark theme (`shadcn-dark`).
2. **Utilities** - exposes the shadcn token names as Tailwind utilities (`text-muted-foreground`,
   `bg-card`, `border-border`, `text-destructive`, `rounded-lg`, …) via `@theme inline`, so they
   stay theme-reactive.
3. **Component overrides** - restates shadcn's signature metrics on daisyUI components: `h-9`
   controls, `rounded-md` fields / `rounded-xl` cards, the `ring-[3px] ring/50` focus ring,
   `shadow-xs` / `shadow-sm`, flat surfaces (no daisyUI depth/noise).

## Requirements

- Tailwind CSS **v4**
- daisyUI **v5**

## Install (any Tailwind v4 + daisyUI v5 project)

Copy `shadcn-daisyui.css` into your project, then in your main stylesheet:

```css
@import "tailwindcss";
@plugin "daisyui" {
  themes: false;            /* we ship our own themes; don't emit daisyUI's defaults */
}
@import "./shadcn-daisyui.css";   /* MUST come after @plugin "daisyui" */
```

> Order matters. daisyUI emits its component CSS into Tailwind's **utilities** layer, so the
> override layer in this file is also `@layer utilities` and must be imported **after** the daisyUI
> plugin to win the cascade.

### Phoenix (1.8+) note

Phoenix 1.8 already vendors daisyUI v5 + Tailwind v4. Use the vendored plugin path and keep the
file at the repo root:

```css
@plugin "../vendor/daisyui" { themes: false; }
@import "../../theme/shadcn-daisyui.css";
```

This repo's demo (`/`) is wired exactly this way - see
[`assets/css/app.css`](../assets/css/app.css).

## Activate the theme

Set `data-theme` on `<html>`:

```html
<html data-theme="shadcn">       <!-- light -->
<html data-theme="shadcn-dark">  <!-- dark  -->
```

`shadcn` is also bound to `:root`, so a page with no `data-theme` falls back to light.
For convenience the dark tokens are mirrored onto a `.dark` class too, so a `.dark`-based toggle
and Tailwind `dark:` utilities work. The demo's `dark:` variant is configured in `app.css` as:

```css
@custom-variant dark (&:where([data-theme=shadcn-dark], [data-theme=shadcn-dark] *, .dark, .dark *));
```

Toggle it however you like - flip `data-theme` between `shadcn` / `shadcn-dark`. The demo reuses
Phoenix's built-in `phx:set-theme` mechanism.

## What you can use

Standard daisyUI classes, restyled: `btn` (`btn-primary` = shadcn *default*, plus `btn-secondary`,
`btn-outline`, `btn-ghost`, `btn-link`, `btn-error`; sizes `btn-sm/btn-lg`, `btn-square`),
`badge`, `card` / `card-body` / `card-title`, `input` / `textarea` / `select` / `file-input`,
`checkbox`, `radio`, `toggle`, `alert` / `alert-error`, `tabs tabs-box` / `tab` (use radio inputs
for clickable tabs), `table`, `menu` / `dropdown-content`, `modal` / `modal-box`, `progress`,
`tooltip`, `kbd`, `skeleton`, `collapse collapse-arrow` (accordion), `avatar` / `avatar-group` /
`avatar-placeholder`, `breadcrumbs`, `divider` (separator), `range` (slider), `join` + `join-item`
(pagination), `loading loading-spinner`, non-menu `dropdown-content` (popover), `toast`.

Plus shadcn-named utilities: `bg-background`, `text-foreground`, `bg-card`, `text-muted-foreground`,
`text-destructive`, `border-border`, `bg-popover`, etc.

## Gotcha: `--border`

shadcn uses `--border` as a **colour**; daisyUI uses `--border` as a **width** (it appears inside
component size `calc()`s). They collide, so in this file:

- `--border` = `1px` (daisyUI's width - leave it alone)
- `--border-color` = the shadcn border colour (use this, or the `border-border` utility)

## Customising

- **Radius**: change `--radius` (default `0.625rem`); `--radius-sm/md/lg/xl` derive from it.
- **Different base palette** (zinc/stone/slate): swap the grayscale OKLCH lightness values in the
  token blocks. shadcn's neutral is fully grey (chroma 0) except `--destructive`.
- **Accent colour**: point `--primary` / `--color-primary` at a hue instead of near-black.
