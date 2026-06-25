# shadcn_daisyui - layout

Breakpoints, window size classes, content widths, and the page scaffold.
Design mobile-first: base styles target the smallest screen; enhance upward.

## Rules

- Design for **compact first**. [web] Unprefixed utilities are the compact layout;
  add `md:` / `lg:` enhancements, never the reverse (`max-*` variants are a smell).
- Three window size classes drive every layout decision: **compact** (< 640px,
  phones), **medium** (640-1023px, large phones / portrait tablet splits),
  **expanded** (≥ 1024px, landscape iPad / desktop). Don't invent per-feature
  breakpoints.
- [web] Breakpoints are Tailwind defaults - `sm` 640, `md` 768, `lg` 1024,
  `xl` 1280, `2xl` 1536 px. `sm:` marks the compact→medium edge and `lg:` the
  medium→expanded edge; use `md:`/`xl:` only for fine-tuning within a class.
- [ios] Branch on size classes, not device idiom: horizontal compact ↔ compact;
  horizontal regular ↔ medium/expanded. Never `if iPad`.
- One column on compact. Multi-column layouts (sidebars, split views, grid > 1
  column for primary content) start at medium or expanded.
- Constrain content width on expanded: app shell `max-w-7xl` (80rem / 1280px),
  reading prose ~`65ch`, forms `max-w-md`-`max-w-lg` (28-32rem). Never let text or
  form fields span a full desktop viewport. **Why:** line length drives
  readability and form-completion speed - prose past ~75 characters is hard to
  track back, and a single full-width input invites overlong values and hides the
  field's expected size. The cap is about the *measure*, not the container.
- **Dense / data-entry forms are the exception.** A form that is mostly short,
  related fields (a service ticket, work order, customer record - common in IHS
  field apps) reads *faster* as a labeled grid than as one tall single-column
  stack. On medium/expanded, widen the container to `max-w-2xl`-`max-w-4xl` and
  lay fields out `grid grid-cols-1 sm:grid-cols-2 gap-4`; keep genuinely long or
  free-text fields (address, notes) spanning the full width (`sm:col-span-2`).
  Stay single column on compact. The `max-w-md` single-column default still wins
  for short, sequential, or wizard-style forms.
- [web] Page gutters: `px-4 sm:px-6 lg:px-8` (16 → 24 → 32px). Vertical rhythm:
  `py-8 lg:py-10` between the page chrome and content.
- [ios] Respect safe areas everywhere; default screen margins 16pt (system
  `.padding()` is on-grid).
- Scroll the content, not the chrome: headers/nav stay fixed, one scroll container
  per screen. Avoid nested scrolling in the same axis.

## Reference

### Window size classes

| Class | Web width | Devices | Layout |
|---|---|---|---|
| compact | < 640px | phones, iPad slide-over | single column, bottom nav, full-width actions |
| medium | 640-1023px | portrait iPad splits, large phones landscape | single column + top navbar, wider gutters |
| expanded | ≥ 1024px | iPad landscape, desktop | sidebar + content, multi-column allowed |

### Content widths

| Content | Width |
|---|---|
| App shell | `max-w-7xl` (80rem / 1280px / 1280pt), centered |
| Reading prose | ~65ch (the measure, not the box) |
| Forms / focused tasks | `max-w-md`-`max-w-lg` (28-32rem / 448-512px), single column |
| Dense / data-entry forms | `max-w-2xl`-`max-w-4xl`, 2-column field grid on `sm:`+ |
| Dialogs | the dialog component's own width - don't override |

### Page scaffold (web recipe)

```
header / navbar          (fixed chrome)
└─ main  px-4 sm:px-6 lg:px-8  py-8 lg:py-10  max-w-7xl mx-auto
   ├─ page title block   (see styles-typography.md)
   └─ sections           gap 24-48px (see foundations-spacing.md)
```

## iOS / SwiftUI notes

- expanded on iPad = `NavigationSplitView` (see `foundations-navigation.md`);
  compact = `TabView`. Let the system switch between them via size class.
- Use `ViewThatFits` / layout priorities rather than hardcoding widths; when you
  must cap line length, cap at ~65 characters with `frame(maxWidth:)`.
- Keyboard: scrollable forms use `.scrollDismissesKeyboard(.interactively)`;
  content never hides behind the keyboard.
