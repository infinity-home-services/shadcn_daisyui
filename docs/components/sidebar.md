# Sidebar

An app navigation sidebar layout.

## Usage guidance

Use when:

- Primary navigation on expanded screens (≥ 1024px) with grouped sections
- Apps with more destinations than a dock can hold

Don't use for:

- Compact screens - use the bottom dock; the sidebar hides below lg
- A handful of peer views within one page - use tabs

Sizing: 15rem (240px) wide; items are text-sm rows with rounded-md and bg-muted when active.

Responsive: Pair with a mobile picker or dock below lg - the same destinations, same order, same labels.

iOS: NavigationSplitView sidebar on iPad regular width; it collapses to a stack on compact.

## Specs

| Part | Description |
| --- | --- |
| Layout | A flex container with an `<aside>` rail and a `<main>` content region. |
| Group | A titled `.menu` list (`.menu-title` heading) of navigation rows. |
| Item | A link row; the active row gets `.menu-active` (subtle accent fill). |

| Property | Value |
| --- | --- |
| Rail width | ~15rem (240px) in app usage |
| Rail border | border-r 1px var(--border-color), bg-base-100 |
| Item text | 0.875rem (text-sm), var(--radius-sm) rows |
| Active fill | var(--accent) / var(--accent-foreground) |

Tokens used: `background`, `foreground`, `border-color`, `color-base-200`, `accent`, `accent-foreground`, `muted-foreground`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Move focus through the navigation links |
| Enter | Follow the focused link |

Role / ARIA: An <aside> complementary landmark wrapping a nav menu; <main> is the content landmark.

Focus: Each link row shows the ring-shadow outline; the active row also carries the accent fill.

Screen reader: The complementary landmark and menu-title group the destinations; the active link conveys current location.

Touch target: Rows are text-sm; hidden below lg, so pair with a dock that meets 2.75rem touch targets on compact.

Reduced motion: No motion; active/hover are instant color changes.

## Native (SwiftUI)

Parity: native parity with the web component.

```swift
NavigationSplitView {
  List(selection: $selection) {
    Section("Platform") {
      NavigationLink("Dashboard", value: Route.dashboard)
      NavigationLink("Projects", value: Route.projects)
    }
  }
} detail: {
  DetailView()
}
```

Maps cleanly to a NavigationSplitView sidebar that collapses to a stack on compact width.

## Default

HEEx:

```heex
<.sidebar_layout>
  <:sidebar>
    <.sidebar_group title="Platform">
      <:item navigate={~p"/"} active>Dashboard</:item>
      <:item navigate={~p"/projects"}>Projects</:item>
      <:item navigate={~p"/team"}>Team</:item>
      <:item navigate={~p"/settings"}>Settings</:item>
    </.sidebar_group>
  </:sidebar>
  Main content area
</.sidebar_layout>
```

```html
<div class="flex h-64 overflow-hidden rounded-xl border border-base-300">
  <aside class="w-56 border-r border-base-300 bg-base-100 p-2">
    <ul class="menu w-full">
      <li class="menu-title">Platform</li>
      <li><a class="menu-active">Dashboard</a></li>
      <li><a>Projects</a></li>
      <li><a>Team</a></li>
      <li><a>Settings</a></li>
    </ul>
  </aside>
  <div class="flex-1 p-6 text-sm text-muted-foreground">Main content area</div>
</div>
```
