<!--
shadcn_daisyui design guidelines - single-file bundle.
Source of truth: the usage-rules/*.md files shipped in the shadcn_daisyui
hex package. Rules tagged [web]/[ios] are platform-scoped; untagged rules
are universal.
-->

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

---

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

---

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

---

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

---

# shadcn_daisyui - navigation

Where navigation lives at each window size class, and how deep structures travel.

## Rules

- Navigation pattern follows the window size class (`foundations-layout.md`):
  - **compact** → bottom navigation. [web] `dock` recipe. [ios] `TabView`.
  - **medium** → top navbar ([web] `navbar`) or the bottom nav carried over -
    pick one per app and keep it.
  - **expanded** → sidebar. [web] `<.sidebar_layout>` (15rem / 240px sidebar).
    [ios] `NavigationSplitView`.
- Bottom navigation holds **3-5 destinations**, each with icon + label, always
  visible. More than 5 → rethink the IA or move items behind a "More"
  destination; never scroll a tab bar.
- Primary destinations are never hidden behind a hamburger on compact. A drawer
  may hold secondary items (settings, account) - not the main sections.
- One primary navigation surface per screen. Tabs within a page are for peer
  content views, not navigation - and never nest tab bars.
- Breadcrumbs appear at medium and expanded only, never on compact.
- Keep destination order, icons, and labels identical across platforms - the web
  bottom dock and the iOS tab bar should read the same.
- Deep navigation: drill-down pushes (detail screens) vs. self-contained tasks
  as modal sheets/dialogs. Pushing = "going somewhere"; sheet = "doing something
  and coming back". See `foundations-interaction.md` for dismissal rules.
- [ios] The system back gesture and back button are sacred - never custom back
  buttons, never block swipe-back.

## Reference

| Class | Primary nav | Secondary nav | Detail |
|---|---|---|---|
| compact | bottom dock / `TabView`, 3-5 items | drawer for overflow (settings etc.) | push / full-screen |
| medium | navbar (or carried-over bottom nav) | dropdown menus in navbar | push / dialog |
| expanded | sidebar 15rem, grouped sections | sidebar groups + collapsible | content pane / dialog |

Web recipes: bottom dock `<div class="dock">…`, navbar `<div class="navbar">…`,
sidebar via the `<.sidebar_layout>` component with `<.sidebar_group>` sections,
breadcrumbs `<.breadcrumb>` (last item = current page, no link).

## iOS / SwiftUI notes

- `TabView` on compact and `NavigationSplitView` on regular width; let size class
  drive the switch, don't hardcode device checks.
- Sheets: use `.sheet` with detents for sub-tasks; `.fullScreenCover` only for
  flows that must own the screen (onboarding, capture).
- Tab bar items use SF Symbols matching the web icon's meaning (not necessarily
  its exact glyph) - keep labels identical.

---

# shadcn_daisyui - interaction

Interactive states, touch targets, and input-method differences.

## Rules

- Every interactive control supports the full state ladder: default → hover
  ([web] pointer devices only) → focus-visible → active → disabled, plus loading
  where an action is async. The themed components already implement it - don't
  strip states when composing.
- Hover is an enhancement, never a requirement. Nothing is reachable only by
  hover (touch has none); menus open on click/tap, tooltips have non-hover
  equivalents (visible labels or help text on touch).
- Focus: `:focus-visible` ring only (3px at 50% ring color). Never `outline-none`
  without it; never show the ring on mouse click (that's what `:focus-visible`
  handles).
- Disabled keeps the variant's colors at 50% opacity - the theme deliberately
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
  - The 16px checkbox/radio is NEVER a bare target - wrap it in its label row so
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

- System components already meet the 44pt floor - the rule bites on custom rows,
  icon buttons, and tightly packed controls.
- Use `.disabled(isLoading)` + in-place `ProgressView`; never block the whole
  screen for a single control's async work.
- Haptics: light impact for confirmations, `.error` notification for failures -
  sparingly, mirroring the web's toast moments.

---

# shadcn_daisyui - color usage

How to *use* the semantic color tokens. The palette itself lives in the theme
(see `usage-rules/theming.md`); brands override tokens there, never in views.

## Rules

- Only semantic tokens, never literal colors. [web] No `bg-white`,
  `text-gray-500`, hex/oklch literals - use `bg-base-100`, `text-muted-foreground`,
  `btn-primary`, etc. [ios] Only the `ShadcnDaisyUI` Color tokens.
- One `primary` action per view region. Everything else steps down the emphasis
  ladder: primary → secondary → outline → ghost/link.
- `destructive`/`error` styling is only for irreversible actions and error
  states, always paired with a confirmation (see `foundations-interaction.md`).
  Never use it for emphasis.
- Status colors (`info`, `success`, `warning`, `error`) are the only non-neutral
  accents, and they always mean status - never decoration. Don't reach for raw
  green/yellow/red utilities.
- Surfaces step subtly: `base-100` page and cards, `base-200` subtle insets
  (wells, code blocks, hover), `base-300` for borders. Separation comes from
  1px borders, not from color blocks.
- Secondary text is `text-muted-foreground`; body text inherits the foreground.
  No other text colors except status and destructive.
- **Brand splash rule**: a brand recolors by overriding theme tokens in its own
  `[data-theme="<brand>"]` block (see `theming.md`) - never by inline brand
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

---

# shadcn_daisyui - typography & icons

The type ramp and iconography rules. Six roles cover every screen - if text
doesn't fit a role, it's probably the wrong text.

## Rules

- Use the ramp roles below; don't invent sizes between steps or stack multiple
  "title-ish" sizes on one screen.
- Weights: 500 (medium) for buttons/labels, 600 (semibold) for titles, 700 (bold)
  for the page title only. One bold weight per level - never bold body copy for
  emphasis (restructure instead).
- Controls and dense UI default to `text-sm` (14px) - this is the system-wide
  control size (buttons, inputs, tables, menus already use it). Prose uses
  `text-base` (16px).
- `text-xs` (12px) is the floor: labels, captions, badges only - never body text,
  never below it.
- Page titles use `tracking-tight`; nothing else gets letter-spacing tweaks.
- Line length for prose ~65ch (see `foundations-layout.md`).
- Icons: [web] heroicons - outline by default, solid for active/selected states.
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
| UI / controls | `text-sm` | 14px | 400-500 | Subheadline (15pt) |
| Label / caption | `text-xs font-medium` | 12px | 500 | Footnote (13pt) / Caption |

Sizes are at default scale; [ios] roles map to SF text styles so Dynamic Type
scales them - never pin fixed sizes for body content.

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

---

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

---

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
