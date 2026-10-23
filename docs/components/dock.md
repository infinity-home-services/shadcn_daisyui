# Dock

A bottom navigation bar for mobile.

## Specs

| Part | Description |
| --- | --- |
| Dock bar | Bottom navigation bar pinned to the foot of the view. |
| Dock item | Icon + dock-label button; dock-active marks the current destination. |

| Property | Value |
| --- | --- |
| Variant | dock-sm compact size in the example |
| Position | Anchored to the bottom edge |
| Item | Stacked icon (size-5) over a dock-label |
| Active | dock-active highlights the current item |

Tokens used: `background`, `primary`, `muted-foreground`, `border-color`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Move focus across dock destinations |
| Enter / Space | Activate the focused destination |

Role / ARIA: Navigation landmark of tab-like destinations; mark the active item with aria-current.

Focus: Each destination button shows a native focus ring.

Screen reader: Announced as navigation; each item reads its label and current state.

Touch target: Dock destinations must meet the 44pt minimum tap area.

Reduced motion: No motion beyond color transitions.

## Native (SwiftUI)

Parity: guidance only - no native component yet.

```swift
TabView {
    HomeView().tabItem { Label("Home", systemImage: "house") }
    SearchView().tabItem { Label("Search", systemImage: "magnifyingglass") }
    ProfileView().tabItem { Label("Profile", systemImage: "person") }
}
```

The native tab bar is the platform equivalent of a bottom dock.

## Default

```html
<div class="relative h-24 w-full overflow-hidden rounded-xl border border-base-300">
  <div class="dock dock-sm" style="position:absolute">
    <button class="dock-active">
      <span class="hero-home size-5" aria-hidden="true"></span><span class="dock-label">Home</span>
    </button>
    <button>
      <span class="hero-magnifying-glass size-5" aria-hidden="true"></span><span class="dock-label">Search</span>
    </button>
    <button>
      <span class="hero-user size-5" aria-hidden="true"></span><span class="dock-label">Profile</span>
    </button>
  </div>
</div>
```
