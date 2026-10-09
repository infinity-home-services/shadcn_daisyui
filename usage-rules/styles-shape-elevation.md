# shadcn_daisyui - shape & elevation

Radius roles and the elevation ladder. Surfaces are flat by design: borders do
the separation work, shadows are garnish.

## Rules

- Radius always comes from the theme scale - never hardcode pixel radii.
  [web] `rounded-sm/md/lg/xl/full` only (they resolve to the `--radius` scale).
- Radius roles: `md` for fields, buttons, and floating content (popovers, menus,
  select panels, tooltips), `lg` for alerts and tab lists, `xl` for cards,
  dialogs/modal boxes, and the command palette, `full` for pills, badges, and
  avatars. `sm` is for small nested elements (checkboxes, menu items, kbd).
- Don't mix roles on one element family - every card on a screen has the same
  radius, every field the same.
- Elevation is fixed per role (shadcn's): page and most surfaces are **flat**;
  controls carry `shadow-xs`; cards `shadow-sm`; floating content (popover, menu,
  select/combobox/date panels, context menu) `shadow-md` plus a 1px
  `ring-foreground/10` instead of a border; dialogs, the command palette, sheets
  and drawers `shadow-lg`. The theme applies these - never add shadows in
  markup, and never `shadow-xl/2xl` or custom shadows.
- Every modal surface (dialog, sheet, drawer, command) uses the same backdrop:
  `bg-black/50`. Don't add blur or a second dim.
- Borders are 1px `border-border` (web) / `sdBorder` (iOS). Don't fake depth
  with darker borders or gradient edges.
- Hover/focus never change elevation - state feedback is color and ring
  (`foundations-interaction.md`), not lift.

## Reference

### Radius scale (base `--radius` = 0.625rem / 10px)

| Token | Value | Roles |
|---|---|---|
| `rounded-sm` | 6px / 6pt | checkboxes, menu items, kbd, nested chips |
| `rounded-md` | 8px / 8pt | buttons, inputs, selects, tabs triggers, tooltips, skeletons, popovers, dropdown/menu boxes |
| `rounded-lg` | 10px / 10pt | alerts, tab lists |
| `rounded-xl` | 14px / 14pt | cards, dialogs / modal boxes, command palette |
| `rounded-full` | pill | badges, avatars, progress bars, pills |

### Elevation ladder

| Level | Shadow | Used by |
|---|---|---|
| 0 - flat | none | page, sections, list rows, most surfaces |
| 1 - control | `shadow-xs` (0 1px 2px @5%) | buttons, inputs |
| 2 - raised | `shadow-sm` (0 1px 3px @10%) | cards |
| 3 - floating | `shadow-md` (0 4px 6px @10%) + 1px `ring-foreground/10` | popovers, menus, select/combobox/date panels, context menus |
| 4 - overlay | `bg-black/50` backdrop + `shadow-lg` (0 10px 15px @10%) | dialogs (+ ring), command palette (+ ring), sheets, drawers |

## iOS / SwiftUI notes

- Use continuous corners: `RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)` -
  the Swift package's radius constants mirror the web scale (6/8/10/14pt).
- Prefer system materials (`.thinMaterial`, `.regularMaterial`) over drop
  shadows for overlay surfaces; when a shadow is needed, use the package's
  `Elevation` presets, nothing stronger.
