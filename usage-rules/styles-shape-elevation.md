# shadcn_daisyui - shape & elevation

Radius roles and the elevation ladder. Surfaces are flat by design: borders do
the separation work, shadows are garnish.

## Rules

- Radius always comes from the theme scale - never hardcode pixel radii.
  [web] `rounded-sm/md/lg/xl/full` only (they resolve to the `--radius` scale).
- Radius roles: `md` for fields and buttons, `lg` for popovers/menus/modal boxes,
  `xl` for cards and dialogs, `full` for pills, badges, and avatars. `sm` is for
  small nested elements (checkboxes, menu items, kbd).
- Don't mix roles on one element family - every card on a screen has the same
  radius, every field the same.
- Elevation is minimal and fixed per role: page and most surfaces are **flat**;
  interactive controls carry `shadow-xs`; cards, popovers, menus, and modals
  carry `shadow-sm`. Nothing carries more.
- Overlays separate via the backdrop dim + `shadow-sm`, not bigger shadows.
  Never add `shadow-md/lg/xl` or custom shadows.
- Borders are 1px `border-base-300` (web) / `sdBorder` (iOS). Don't fake depth
  with darker borders or gradient edges.
- Hover/focus never change elevation - state feedback is color and ring
  (`foundations-interaction.md`), not lift.

## Reference

### Radius scale (base `--radius` = 0.625rem / 10px)

| Token | Value | Roles |
|---|---|---|
| `rounded-sm` | 6px / 6pt | checkboxes, menu items, kbd, nested chips |
| `rounded-md` | 8px / 8pt | buttons, inputs, selects, tabs triggers, tooltips, skeletons |
| `rounded-lg` | 10px / 10pt | popovers, dropdown/menu boxes, modal boxes, alerts, tab lists |
| `rounded-xl` | 14px / 14pt | cards, dialogs |
| `rounded-full` | pill | badges, avatars, progress bars, pills |

### Elevation ladder

| Level | Shadow | Used by |
|---|---|---|
| 0 - flat | none | page, sections, list rows, most surfaces |
| 1 - control | `shadow-xs` (0 1px 2px @5%) | buttons, inputs |
| 2 - raised | `shadow-sm` (0 1px 3px @10%) | cards, popovers, menus, modal boxes, toasts |
| overlay | backdrop dim + `shadow-sm` | dialogs, sheets, drawers |

## iOS / SwiftUI notes

- Use continuous corners: `RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)` -
  the Swift package's radius constants mirror the web scale (6/8/10/14pt).
- Prefer system materials (`.thinMaterial`, `.regularMaterial`) over drop
  shadows for overlay surfaces; when a shadow is needed, use the package's
  `Elevation` presets, nothing stronger.
