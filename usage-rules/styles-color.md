# shadcn_daisyui - color usage

How to *use* the semantic color tokens. The palette itself lives in the theme
(see `usage-rules/theming.md`); brands override tokens there, never in views.

## Rules

- Only semantic tokens, never literal colors. [web] No `bg-white`,
  `text-gray-500`, hex/oklch literals - use `bg-base-100`, `text-muted-foreground`,
  `btn-primary`, etc. [ios] Only the `ShadcnDaisyUI` Color tokens.
- One `primary` action per view region. Everything else steps down the emphasis
  ladder: primary → secondary → outline → ghost/link.
- `destructive`/`error` styling is only for irreversible actions and error
  states, always paired with a confirmation (see `foundations-interaction.md`).
  Never use it for emphasis.
- Status colors (`info`, `success`, `warning`, `error`) are the only non-neutral
  accents, and they always mean status - never decoration. Don't reach for raw
  green/yellow/red utilities.
- Each surface has one role, matching shadcn. Page: `bg-base-100` /
  `bg-background`. Cards, plus anything inside a card that needs an opaque
  fill (a sticky table header, a sticky footer bar): `bg-card`. Overlays
  (sheets, dialogs, popovers, dropdown and command content): `bg-popover` with
  `text-popover-foreground`. Subtle insets (wells, code blocks, hover):
  `bg-base-200` / `bg-muted`. Borders: `border-base-300`. Separation comes from
  1px borders, not from color blocks.
- `bg-base-100` is the page, never a card or overlay. The tokens only look the
  same in light mode; in dark mode `--background` is darker than `--card` and
  `--popover`, so a card-level surface painted `bg-base-100` reads as a hole.
- A sticky `<thead>` inside a card uses `bg-card`. shadcn's table header has no
  background of its own, so a sticky one needs an opaque fill that matches the
  card behind it (the same goes for a sticky footer bar in a card).
- A persistent app sidebar is page chrome (`bg-base-100`, as `<.sidebar_layout>`
  renders it). A drawer that slides over content is an overlay (`bg-popover`).
- Secondary text is `text-muted-foreground`; body text inherits the foreground.
  No other text colors except status and destructive.
- **Brand splash rule**: a brand recolors by overriding theme tokens in its own
  `[data-theme="<brand>"]` block (see `theming.md`) - never by inline brand
  colors in templates or views. If a brand color appears in markup, it's a bug.
- Dark mode comes from the tokens. [web] Use `dark:` only for genuinely
  asymmetric cases (e.g. inverted artwork); if you're writing `dark:bg-*` for a
  surface, you used the wrong token.

## Reference

### Emphasis ladder

| Level | Web | Use |
|---|---|---|
| Primary | `btn-primary` | the one main action |
| Secondary | `btn-secondary` | supporting actions |
| Outline | `btn-outline` | tertiary, low-commitment |
| Ghost / link | `btn-ghost`, `btn-link` | toolbar icons, inline nav |
| Destructive | `btn-error` | irreversible, always confirmed |

### Token roles

| Role | Web | Swift |
|---|---|---|
| Page | `bg-base-100`, `bg-background` | `sdBackground` |
| Card (and opaque fills inside one: sticky thead, sticky footer) | `bg-card` | `sdCard` |
| Overlay (sheet, dialog, popover, dropdown, command) | `bg-popover` + `text-popover-foreground` | `sdPopover` / `sdPopoverForeground` |
| Subtle inset | `bg-base-200`, `bg-muted` | `sdMuted` |
| Border | `border-base-300`, `border-border` | `sdBorder` |
| Body text | inherits foreground | `sdForeground` |
| Secondary text | `text-muted-foreground` | `sdMutedForeground` |
| Status | `alert-info/success/warning/error`, `text-warning`, … | `sdInfo/…` |

## iOS / SwiftUI notes

- Define the same semantic roles as the Swift package's Color tokens with
  light/dark variants; never `Color(red:green:blue:)` in views.
- Tint: set the app accent to `sdPrimary` once; don't tint individual controls
  except to step down emphasis (`.buttonStyle(.bordered)` ≈ outline).
