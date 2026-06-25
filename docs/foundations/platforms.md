# shadcn_daisyui - platforms

How these guidelines apply across web (mobile-first, scales to desktop) and native
iOS / iPadOS (SwiftUI). Read this file first; every other guideline file uses its
conventions.

## Rules

- Untagged rules in any guideline file are universal. Rules prefixed `[web]` or
  `[ios]` apply only to that platform.
- All values are stated in dual units: `rem / px` for web, `pt` for iOS.
  Conversion: `1rem = 16px`; `1pt = 1px` at 1× scale. A value written
  `1rem / 16px / 16pt` is the same physical size everywhere.
- [ios] Never reference literal colors, sizes, or fonts in views. Use the design
  tokens (semantic colors, spacing, radius, type roles) defined by the
  `ShadcnDaisyUI` Swift package.
- [web] Never use raw color utilities or hardcoded radii/shadows. Use the semantic
  theme tokens (see `styles-color.md` and the main usage rules).
- When Apple's Human Interface Guidelines and these guidelines conflict, use the
  arbitration table below. Do not invent a third option.

## Reference

### HIG arbitration

| Area | Winner | Examples |
|---|---|---|
| Navigation chrome | **HIG** | Tab bars, navigation bars, `NavigationSplitView`, back button placement |
| System gestures | **HIG** | Swipe-back, pull-to-refresh, swipe actions |
| System surfaces | **HIG** | Alerts, action sheets, share sheets, context menus, keyboards |
| Spacing scale | **These guidelines** | 4pt grid, blessed steps (`foundations-spacing.md`) |
| Type roles & weights | **These guidelines** | Ramp in `styles-typography.md`, mapped to SF text styles |
| Color semantics | **These guidelines** | Semantic roles (`primary`, `destructive`, status colors) |
| Radius scale | **These guidelines** | 6 / 8 / 10 / 14 pt roles (`styles-shape-elevation.md`) |
| Touch target floor | **Both agree** | 44pt minimum (`foundations-interaction.md`) |

### Token → SwiftUI mapping

| Web token | Swift token | iOS system analogue |
|---|---|---|
| `--background` / `bg-base-100` | `Color.sdBackground` | `systemBackground` |
| `--foreground` | `Color.sdForeground` | `label` |
| `--muted` / `bg-base-200` | `Color.sdMuted` | `secondarySystemBackground` |
| `--muted-foreground` | `Color.sdMutedForeground` | `secondaryLabel` |
| `--primary` | `Color.sdPrimary` | accent color role |
| `--destructive` | `Color.sdDestructive` | `systemRed` role |
| `--border-color` / `border-base-300` | `Color.sdBorder` | `separator` |
| `--ring` | `Color.sdRing` | focus indication |
| `--radius-md` (8px) | `Radius.md` (8pt) | continuous corners |
| `--radius-xl` (14px) | `Radius.xl` (14pt) | continuous corners |

### Window size classes ↔ iOS size classes

| Guideline class | Web width | iOS |
|---|---|---|
| compact | < 640px | compact width (iPhone, iPad slide-over) |
| medium | 640-1023px | regular width, constrained (iPad portrait split) |
| expanded | ≥ 1024px | regular width (full-screen iPad, desktop) |

See `foundations-layout.md` for how layout changes per class.

## iOS / SwiftUI notes

- Distribute tokens via the `ShadcnDaisyUI` Swift package (SPM); it bundles a copy
  of these guidelines as `design-guidelines.md`.
- Dynamic Type: type roles map to SF text styles so they scale automatically -
  never use fixed `Font.system(size:)` for body content.
- Dark mode: every semantic color has light and dark variants baked into the token;
  never branch on `colorScheme` to pick colors manually.
