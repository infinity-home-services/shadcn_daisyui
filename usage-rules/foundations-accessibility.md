# shadcn_daisyui - accessibility & content

Accessibility floor and writing basics for every screen, both platforms.

## Rules

- Text contrast: ≥ 4.5:1 for body text, ≥ 3:1 for large text (≥ 24px / 19px bold)
  and for UI element boundaries. The theme's token pairs already pass - this rule
  exists so you don't defeat them (e.g. muted text on muted surfaces).
- `text-muted-foreground` (iOS: `sdMutedForeground`) is for secondary text only.
  Never use it for primary content or below 12px / 12pt.
- Never remove or restyle focus indication. [web] The focus ring is
  `0 0 0 3px` at 50% `--ring`, applied on `:focus-visible` - never `outline: none`
  without a replacement, never gate it behind hover.
- Every interactive control has an accessible name. [web] Form controls get labels
  via the form components (see `forms.md`); icon-only buttons get `aria-label`.
  [ios] Every tappable element gets `.accessibilityLabel` unless its text is the label.
- Decorative icons are hidden from assistive tech. [web] `aria-hidden="true"`
  (the icon-span convention does this). [ios] `.accessibilityHidden(true)`.
- Honor reduced motion. [web] Respect `prefers-reduced-motion` for any animation
  you add. [ios] Check `accessibilityReduceMotion` before custom animations.
- Don't convey state by color alone - pair status colors with an icon or text
  (e.g. error messages render text, not just a red border).
- [web] Use semantic elements and landmarks: `<main>`, `<nav>`, `<header>`,
  `<button>` for actions, `<a>` for navigation. Never a clickable `<div>`.
- [ios] Support Dynamic Type at least one step up and down without clipping or
  overlapping; test at the accessibility XL size for critical flows.

## Content basics

- Sentence case everywhere: headings, buttons, labels, menu items. No Title Case,
  no ALL CAPS (the theme never uppercases for you).
- Buttons start with a verb and name the action: "Save changes", "Delete project" -
  never "OK", "Yes", or "Click here".
- Error messages state what happened and how to fix it: "Email is already taken -
  try signing in instead", not "Invalid input".
- Destructive confirmations name the object: "Delete 'Q3 report'?" with actions
  "Delete" / "Cancel" - never "Are you sure?" with "Yes" / "No".
- Empty states say what belongs there and offer the first action, in one or two
  sentences.

## Reference

| Check | Target |
|---|---|
| Body text contrast | 4.5:1 |
| Large text / UI boundaries | 3:1 |
| Touch target | 44 × 44 pt / 2.75rem effective hit area (`foundations-interaction.md`) |
| Smallest text size | 12px / 12pt (`text-xs`), labels only |
| Focus ring | 3px at 50% ring color, `:focus-visible` only |

## iOS / SwiftUI notes

- VoiceOver: group composite rows with `.accessibilityElement(children: .combine)`
  so a card reads as one element, not five.
- Prefer system controls (Toggle, Picker, Button) - they carry traits, labels, and
  Dynamic Type behavior for free; custom controls must re-implement all of it.
