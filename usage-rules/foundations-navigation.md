# shadcn_daisyui — navigation

Where navigation lives at each window size class, and how deep structures travel.

## Rules

- Navigation pattern follows the window size class (`foundations-layout.md`):
  - **compact** → bottom navigation. [web] `dock` recipe. [ios] `TabView`.
  - **medium** → top navbar ([web] `navbar`) or the bottom nav carried over —
    pick one per app and keep it.
  - **expanded** → sidebar. [web] `<.sidebar_layout>` (15rem / 240px sidebar).
    [ios] `NavigationSplitView`.
- Bottom navigation holds **3–5 destinations**, each with icon + label, always
  visible. More than 5 → rethink the IA or move items behind a "More"
  destination; never scroll a tab bar.
- Primary destinations are never hidden behind a hamburger on compact. A drawer
  may hold secondary items (settings, account) — not the main sections.
- One primary navigation surface per screen. Tabs within a page are for peer
  content views, not navigation — and never nest tab bars.
- Breadcrumbs appear at medium and expanded only, never on compact.
- Keep destination order, icons, and labels identical across platforms — the web
  bottom dock and the iOS tab bar should read the same.
- Deep navigation: drill-down pushes (detail screens) vs. self-contained tasks
  as modal sheets/dialogs. Pushing = "going somewhere"; sheet = "doing something
  and coming back". See `foundations-interaction.md` for dismissal rules.
- [ios] The system back gesture and back button are sacred — never custom back
  buttons, never block swipe-back.

## Reference

| Class | Primary nav | Secondary nav | Detail |
|---|---|---|---|
| compact | bottom dock / `TabView`, 3–5 items | drawer for overflow (settings etc.) | push / full-screen |
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
  its exact glyph) — keep labels identical.
