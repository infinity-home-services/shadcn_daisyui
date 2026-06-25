# shadcn_daisyui - motion

Three durations, standard easing, opacity/transform only. Motion confirms an
action or orients a transition - it never decorates.

## Rules

- Three durations, by surface size:
  - **150ms** - micro state changes (color, background, border, shadow on
    hover/active).
  - **~180ms** - small surfaces entering/leaving (popovers, tooltips, command
    palette): opacity + slight transform.
  - **300ms** - large surfaces (sheets, drawers): translate + backdrop fade.
- Easing: `ease` / `ease-out`. No bounces, springs with overshoot, or custom
  cubic-beziers.
- Animate only `opacity` and `transform`/`translate` - never layout properties
  (width, height, top/left, margin) and never color *transitions* on theme
  switch.
- Theme switching is **instant by design** (no fade - fading light↔dark passes
  text through a grey crossover). [web] The theme CSS only zeroes out
  `transition-duration` while `<html>` carries the `theme-transition` class, so
  the swap itself never fades while hover/focus/micro transitions stay live the
  rest of the time. **Toggle the theme through the package's `setTheme(theme)`
  helper** (`shadcn-daisyui.js`) - it adds the class, flips `data-theme`, and
  drops it on the next frame. Setting `data-theme` directly skips the guard and
  the swap will fade-flicker.
- No entrance animations for page content - content appears immediately.
  Skeletons cover loading; don't add fade-ins on top.
- Respect reduced motion: [web] gate any added animation behind
  `prefers-reduced-motion`; [ios] check `accessibilityReduceMotion`. The themed
  components already comply.

## Reference

| Tier | Duration | Easing | Properties | Examples |
|---|---|---|---|---|
| micro | 150ms | ease | color, bg, border, shadow | button hover/active |
| small surface | 180ms | ease | opacity, transform | popover, tooltip, ⌘K palette |
| large surface | 300ms | ease | translate, backdrop | sheet, drawer |
| theme switch | 0ms | - | - | instant by design |

## iOS / SwiftUI notes

- The Swift package's `Motion` presets mirror the tiers: `.micro` (0.15s),
  `.surface` (0.18s), `.sheet` (0.30s) as `Animation.easeOut` curves.
- Prefer system presentation animations for sheets/covers - they're already in
  the right range; don't restyle them.
- Default SwiftUI implicit animations are acceptable for micro states; avoid
  `spring(response:dampingFraction:)` with visible overshoot.
