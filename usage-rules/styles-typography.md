# shadcn_daisyui — typography & icons

The type ramp and iconography rules. Six roles cover every screen — if text
doesn't fit a role, it's probably the wrong text.

## Rules

- Use the ramp roles below; don't invent sizes between steps or stack multiple
  "title-ish" sizes on one screen.
- Weights: 500 (medium) for buttons/labels, 600 (semibold) for titles, 700 (bold)
  for the page title only. One bold weight per level — never bold body copy for
  emphasis (restructure instead).
- Controls and dense UI default to `text-sm` (14px) — this is the system-wide
  control size (buttons, inputs, tables, menus already use it). Prose uses
  `text-base` (16px).
- `text-xs` (12px) is the floor: labels, captions, badges only — never body text,
  never below it.
- Page titles use `tracking-tight`; nothing else gets letter-spacing tweaks.
- Line length for prose ~65ch (see `foundations-layout.md`).
- Icons: [web] heroicons — outline by default, solid for active/selected states.
  `size-4` (16px) inside controls and inline with text, `size-5` (20px)
  standalone. [ios] SF Symbols, scale matched to the adjacent text style.
- Icons never appear without meaning: decorative icons are hidden from assistive
  tech, functional icon-only buttons get accessible labels
  (`foundations-accessibility.md`).

## Reference

### Type ramp

| Role | Web | Size | Weight | iOS text style |
|---|---|---|---|---|
| Page title | `text-3xl font-bold tracking-tight` | 30px | 700 | Large Title (34pt) |
| Section title | `text-xl font-semibold tracking-tight` | 20px | 600 | Title 3 (20pt) |
| Subtitle / card title | `text-lg font-medium` | 18px | 500 | Headline (17pt semibold) |
| Body / prose | `text-base` | 16px | 400 | Body (17pt) |
| UI / controls | `text-sm` | 14px | 400–500 | Subheadline (15pt) |
| Label / caption | `text-xs font-medium` | 12px | 500 | Footnote (13pt) / Caption |

Sizes are at default scale; [ios] roles map to SF text styles so Dynamic Type
scales them — never pin fixed sizes for body content.

### Icon sizes

| Context | Web | iOS |
|---|---|---|
| Inside a control / inline with text | `size-4` (16px) | symbol matches text style |
| Standalone (nav items, empty states) | `size-5` (20px) | `.imageScale(.large)` |
| Hero / empty-state illustration | `size-8`+ | custom |

## iOS / SwiftUI notes

- Map roles via the Swift package's `Typography` Font extensions (built on SF
  text styles) rather than raw `Font.system(size:)`.
- SF Symbols: prefer the outline variants for parity with heroicons-outline;
  use `.fill` for selected/active states, mirroring the web's solid swap.
