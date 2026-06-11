# shadcn_daisyui — color usage

How to *use* the semantic color tokens. The palette itself lives in the theme
(see `usage-rules/theming.md`); brands override tokens there, never in views.

## Rules

- Only semantic tokens, never literal colors. [web] No `bg-white`,
  `text-gray-500`, hex/oklch literals — use `bg-base-100`, `text-muted-foreground`,
  `btn-primary`, etc. [ios] Only the `ShadcnDaisyUI` Color tokens.
- One `primary` action per view region. Everything else steps down the emphasis
  ladder: primary → secondary → outline → ghost/link.
- `destructive`/`error` styling is only for irreversible actions and error
  states, always paired with a confirmation (see `foundations-interaction.md`).
  Never use it for emphasis.
- Status colors (`info`, `success`, `warning`, `error`) are the only non-neutral
  accents, and they always mean status — never decoration. Don't reach for raw
  green/yellow/red utilities.
- Surfaces step subtly: `base-100` page and cards, `base-200` subtle insets
  (wells, code blocks, hover), `base-300` for borders. Separation comes from
  1px borders, not from color blocks.
- Secondary text is `text-muted-foreground`; body text inherits the foreground.
  No other text colors except status and destructive.
- **Brand splash rule**: a brand recolors by overriding theme tokens in its own
  `[data-theme="<brand>"]` block (see `theming.md`) — never by inline brand
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
| Page / card surface | `bg-base-100`, `bg-card` | `sdBackground` / `sdCard` |
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
