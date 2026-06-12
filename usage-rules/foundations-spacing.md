# shadcn_daisyui - spacing

All spacing comes from a 4px / 4pt grid. The component CSS already follows it;
these rules keep layouts on it.

## Rules

- Use only the blessed steps: **4, 8, 12, 16, 24, 32, 48** (px / pt).
  [web] That's `gap-1/2/3/4/6/8/12`, `p-1/2/3/4/6/8/12`, `space-y-*` same scale.
- Never use off-grid values (5px, 10px, 18px, arbitrary `p-[18px]`). If a design
  seems to need one, pick the nearest step.
- Related ↔ unrelated: tighter gaps group, wider gaps separate. Icon-to-label 8px;
  controls in a cluster 8px; fields in a form 16px; sections on a page 24-48px.
- Don't add padding inside components that already have it (cards pad 24px,
  buttons pad themselves, alerts pad 12/16px). Component padding is theirs;
  you only space *between* components.
- On compact screens you may drop one step (24 → 16, 48 → 32) - never below,
  and never off-grid.
- [web] Prefer `gap` on flex/grid parents over margins on children; avoid
  margin-top/bottom mixing (`space-y-*` or `gap` keeps rhythm consistent).

## Reference

### Standards (derived from the component CSS - do not fight them)

| Spacing role | Value | Web |
|---|---|---|
| Icon ↔ label inside a control | 0.5rem / 8px / 8pt | `gap-2` (buttons already do this) |
| Buttons / controls in a cluster | 0.5rem / 8px / 8pt | `gap-2` |
| Form fields stacked | 1rem / 16px / 16pt | `space-y-4` |
| Label ↔ its control | 0.375-0.5rem / 6-8px | form components handle it |
| Card interior | 1.5rem / 24px / 24pt | `card-body` pads itself |
| Between cards / list items | 1rem / 16px / 16pt | `gap-4` |
| Page sections | 1.5-2rem / 24-32px | `space-y-6` or `space-y-8` |
| Major page regions | 3rem / 48px / 48pt | `space-y-12` |
| Page gutters | 16 → 24 → 32px | `px-4 sm:px-6 lg:px-8` |

### Blessed steps

| Step | rem | px / pt | Tailwind |
|---|---|---|---|
| 1 | 0.25 | 4 | `*-1` |
| 2 | 0.5 | 8 | `*-2` |
| 3 | 0.75 | 12 | `*-3` |
| 4 | 1 | 16 | `*-4` |
| 6 | 1.5 | 24 | `*-6` |
| 8 | 2 | 32 | `*-8` |
| 12 | 3 | 48 | `*-12` |

## iOS / SwiftUI notes

- The same numbers are pt: `Spacing.s1`...`Spacing.s12` in the Swift package
  (4/8/12/16/24/32/48).
- SwiftUI's default `.padding()` is 16pt - on-grid; keep it. Set explicit stack
  spacing (`VStack(spacing: Spacing.s4)`) instead of accepting ad-hoc defaults
  where rhythm matters.
- List/Form rows: prefer system insets (they're HIG territory); apply the grid to
  custom layouts.
