# Navbar

A top application bar.

## Usage guidance

Use when:

- Primary navigation at medium width; brand + search + account at any width
- Marketing/docs sites where a dock would be overkill

Don't use for:

- The only navigation on compact app screens - primary destinations belong in the dock
- Stuffing primary destinations into a hamburger menu

Sizing: h-14 bar, sticky, border-b border-base-300 with backdrop blur; contents are text-sm.

Responsive: Links collapse below md - keep brand, search, and account visible; move links to the dock or a drawer of secondary items.

iOS: The navigation bar (large title) - it comes from NavigationStack, never hand-built.

## Specs

| Part | Description |
| --- | --- |
| Navbar bar | Top bar container, min-height 3.5rem. |
| Brand / start | flex-1 region holding the brand link. |
| Menu / end | flex-none region with a horizontal menu and primary action. |

| Property | Value |
| --- | --- |
| Min height | 3.5rem (h-14) |
| Border | 1px border-base-300 (rounded-xl in the demo card) |
| Surface | bg-base-100 |
| Font | text-sm contents |

Tokens used: `background`, `color-base-300`, `primary`, `primary-foreground`, `foreground`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Move through brand, links, and actions |
| Enter | Follow the focused link / activate the button |

Role / ARIA: Navigation landmark - wrap links in <nav>; menu items are real <a> links.

Focus: Each link/button shows a native focus ring; nothing hides focus.

Screen reader: Announced as a navigation region; links read by their text.

Touch target: Bar controls should meet 44pt effective hit areas on touch.

Reduced motion: No motion beyond color transitions.

## Native (SwiftUI)

Parity: guidance only - no native component yet.

```swift
NavigationStack {
    content
        .toolbar {
            ToolbarItem(placement: .principal) { Text("Acme Inc").font(.headline) }
            ToolbarItem(placement: .topBarTrailing) { Button("Sign in") { } }
        }
}
```

Use the system navigation bar / .toolbar; never hand-build the bar on iOS.

## Default

```html
<div class="navbar w-full rounded-xl border border-base-300 bg-base-100">
  <div class="flex-1"><a class="btn btn-ghost text-base">Acme Inc</a></div>
  <div class="flex-none">
    <ul class="menu menu-horizontal gap-1">
      <li><a>Docs</a></li>
      <li><a>Pricing</a></li>
      <li><a class="btn btn-primary btn-sm text-primary-content">Sign in</a></li>
    </ul>
  </div>
</div>
```
