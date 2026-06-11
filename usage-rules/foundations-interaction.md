# shadcn_daisyui — interaction

Interactive states, touch targets, and input-method differences.

## Rules

- Every interactive control supports the full state ladder: default → hover
  ([web] pointer devices only) → focus-visible → active → disabled, plus loading
  where an action is async. The themed components already implement it — don't
  strip states when composing.
- Hover is an enhancement, never a requirement. Nothing is reachable only by
  hover (touch has none); menus open on click/tap, tooltips have non-hover
  equivalents (visible labels or help text on touch).
- Focus: `:focus-visible` ring only (3px at 50% ring color). Never `outline-none`
  without it; never show the ring on mouse click (that's what `:focus-visible`
  handles).
- Disabled keeps the variant's colors at 50% opacity — the theme deliberately
  diverges from daisyUI's grey wash. Don't re-grey disabled controls, and don't
  use disabled to hide unavailable features (explain instead).
- Async actions show progress in place: [web] `phx-disable-with` on submit
  buttons, spinner inside the button; [ios] swap label for `ProgressView` and
  disable. Never leave a button tappable twice.
- **Touch targets: 44 × 44 pt / 2.75rem minimum effective hit area** on any
  touch-capable surface.
  - The 36px (`h-9`) control height is fine for pointer-dense desktop UI.
  - On compact screens, primary actions use `btn-lg` (40px) and usually full
    width; adjacent small targets keep ≥ 8px between them so hit areas don't
    overlap.
  - The 16px checkbox/radio is NEVER a bare target — wrap it in its label row so
    the whole row (≥ 44px with `py-2`+) is tappable.
- Destructive actions: `destructive`/`error` variant + a confirmation that names
  the object (see `foundations-accessibility.md` for wording). One destructive
  action per surface, placed last.
- Dismissal: dialogs/sheets close via explicit control, Esc ([web]), backdrop
  click/swipe-down where the task is safely abandonable. Confirm before
  discarding unsaved input.

## Reference

### State ladder (what the theme does)

| State | Treatment |
|---|---|
| hover | subtle bg/opacity shift, pointer only |
| focus-visible | `0 0 0 3px` ring at 50% `--ring` |
| active | slight press effect |
| disabled | variant colors at `opacity: 0.5`, no shadow |
| loading | spinner in place, control disabled |

### Touch target recipes

[web] label-row checkbox (the whole row is the target):

```heex
<label class="flex items-center gap-2 py-2">
  <input type="checkbox" class="checkbox" />
  <span class="text-sm">Email me updates</span>
</label>
```

[ios] small visuals, full-size target:

```swift
Button { … } label: { Image(systemName: "xmark") }
  .frame(minWidth: 44, minHeight: 44)
  .contentShape(Rectangle())
```

## iOS / SwiftUI notes

- System components already meet the 44pt floor — the rule bites on custom rows,
  icon buttons, and tightly packed controls.
- Use `.disabled(isLoading)` + in-place `ProgressView`; never block the whole
  screen for a single control's async work.
- Haptics: light impact for confirmations, `.error` notification for failures —
  sparingly, mirroring the web's toast moments.
