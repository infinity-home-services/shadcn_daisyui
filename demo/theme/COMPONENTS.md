# Component coverage: shadcn/ui ↔ daisyUI v5

Two tables:

1. **Every shadcn/ui component** → its daisyUI equivalent → whether it's in the demo gallery.
2. **daisyUI components that have no shadcn/ui counterpart** (the "extra" ones).

Legend for **Demo**: ✅ shown in the gallery · ⬜️ not shown yet (themed, just no example) ·
🔧 needs JavaScript/state (a CSS theme can style it, but it needs interactivity to demo).

---

## 1. shadcn/ui components

| shadcn/ui | daisyUI equivalent | Demo | Notes |
|---|---|---|---|
| accordion | `collapse collapse-arrow` | ✅ | |
| alert | `alert` | ✅ | incl. destructive |
| alert-dialog | `modal` | ✅ | same as dialog, confirm variant |
| aspect-ratio | — (Tailwind `aspect-*`) | ✅ | utility, no component needed |
| avatar | `avatar` / `avatar-group` / `avatar-placeholder` | ✅ | |
| badge | `badge` | ✅ | |
| breadcrumb | `breadcrumbs` | ✅ | |
| button | `btn` | ✅ | all variants + sizes |
| button-group | `join` | ✅ | `join` + `join-item` |
| calendar | `calendar` (Cally/Pikaday wrapper) | ✅ | needs a date lib |
| card | `card` | ✅ | |
| carousel | `carousel` | ✅ | daisyUI scroll-snap; arrows need JS |
| chart | — | ✅ | no daisyUI; use a charting lib |
| checkbox | `checkbox` | ✅ | |
| collapsible | `collapse` | ✅ | (same as accordion) |
| combobox | `dropdown` + `input` | ✅ | needs JS filtering |
| command | — | ✅ | command palette; needs JS |
| context-menu | `dropdown` | ✅ | right-click trigger needs JS |
| data-table | `table` | ✅ | sorting/paging need JS |
| date-picker | `calendar` + `dropdown` | ✅ | single + range modes |
| dialog | `modal` | ✅ | |
| drawer | `drawer` | ✅ | side panel; needs layout wrapper |
| dropdown-menu | `dropdown` + `menu` | ✅ | |
| empty | — (compose) | ✅ | empty-state pattern, no component |
| field | `fieldset` + `label` | ✅ | form field wrapper |
| hover-card | `dropdown` (hover) | ✅ | `dropdown-hover` |
| input | `input` | ✅ | |
| input-group | `join` + `input` / `label` | ✅ | input with addons |
| input-otp | — | ✅ | needs JS |
| item | — (compose / `list`) | ✅ | list-row pattern |
| kbd | `kbd` | ✅ | |
| label | `label` | ✅ | used on form fields |
| menubar | `menu` / `navbar` | ✅ | needs JS |
| native-select | `select` | ✅ | |
| navigation-menu | `navbar` / `menu` | ✅ | |
| pagination | `join` + `btn` | ✅ | |
| popover | `dropdown` (non-menu content) | ✅ | |
| progress | `progress` | ✅ | |
| radio-group | `radio` | ✅ | |
| resizable | — (custom: flex panels + JS drag) | ✅ | shadcn ResizablePanelGroup look |
| scroll-area | — (Tailwind `overflow`) | ✅ | utility |
| select | `select` (native) | ✅ | custom (searchable) select needs JS |
| separator | `divider` | ✅ | horizontal + vertical |
| sheet | `drawer` | ✅ | slide-over panel |
| sidebar | `drawer` + `menu` | ✅ | app sidebar layout |
| skeleton | `skeleton` | ✅ | |
| slider | `range` | ✅ | |
| sonner (toast) | `toast` + `alert` | ✅ | static example shown |
| spinner | `loading loading-spinner` | ✅ | |
| switch | `toggle` | ✅ | |
| table | `table` | ✅ | |
| tabs | `tabs tabs-box` + `tab` | ✅ | radio inputs = clickable |
| textarea | `textarea` | ✅ | |
| toast | `toast` | ✅ | |
| toggle (pressable) | `btn` (toggle) / `swap` | ✅ | pressable icon button |
| toggle-group | `join` + `btn` | ✅ | segmented toggles |
| tooltip | `tooltip` | ✅ | |
| typography | — (Tailwind `prose`) | ✅ | prose styles |

---

## 2. daisyUI components NOT in shadcn/ui (extras)

These ship with daisyUI and have no direct shadcn/ui counterpart. They'll inherit the theme's
colors/radius automatically, but shadcn has no "official" look for them.

| daisyUI | What it is |
|---|---|
| `chat` | Chat-bubble message rows (left/right, avatars) |
| `countdown` | Animated numeric countdown/odometer |
| `diff` | Side-by-side before/after image (themed; not in demo — replaced by Resizable) |
| `dock` | Bottom navigation bar (mobile "dock") |
| `filter` | Radio-button filter group that reveals a reset |
| `footer` | Page footer layout (columns + headings) |
| `hero` | Full-width hero section layout |
| `indicator` | Corner badge/indicator overlay (notification dot) |
| `link` | Styled inline anchor (`link`, `link-hover`, `link-primary`) |
| `list` | Vertical list rows with `list-row` |
| `mask` | Clip an element to a shape (squircle, hexagon, star…) |
| `mockup` | Browser / phone / code / window mockup frames |
| `navbar` | Top app bar layout (daisyUI's, used in this demo's header) |
| `radial-progress` | Circular percentage progress ring |
| `rating` | Star (or heart) rating input |
| `stack` | Stacked/overlapping element pile |
| `stat` | Stat blocks (value + label + figure) |
| `status` | Tiny status dot (online/offline) |
| `steps` | Horizontal/vertical stepper |
| `swap` | Animated swap between two icons/states |
| `timeline` | Vertical/horizontal event timeline |
| `validator` | Form-validation visual states (`validator-hint`) |

> A few daisyUI extras overlap conceptually with shadcn primitives even though shadcn doesn't ship
> them as named components — e.g. `link` ≈ shadcn's link-button, `stat` ≈ dashboard cards,
> `steps` ≈ a stepper you'd compose by hand.

---

### Quick totals

- **shadcn/ui components:** 58 — **all shown** in the demo. The JS-driven ones (command, combobox,
  calendar, date-picker, carousel, data-table, context-menu, input-otp, resizable) use small vanilla
  handlers in `assets/js/app.js`; chart is plain SVG/CSS; menubar/drawer/sheet use daisyUI + `<dialog>`.
- **daisyUI v5 components:** 57 total — **all 22 with no shadcn counterpart** (table 2) are also
  shown in the demo's "daisyUI extras" group.

> The demo gallery (`/`) is organized top-to-bottom: core shadcn components → "More shadcn
> primitives" → "daisyUI extras — no shadcn counterpart".
