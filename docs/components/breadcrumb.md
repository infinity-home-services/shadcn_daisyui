# Breadcrumb

Displays the path to the current resource.

## Specs

| Part | Description |
| --- | --- |
| Nav | nav landmark labeled Breadcrumb wrapping the trail. |
| Crumb | Linked ancestor pages, muted with a hover to foreground. |
| Current page | Final non-link item carrying aria-current=page. |

| Property | Value |
| --- | --- |
| Font | 0.875rem (text-sm) |
| Crumb color | var(--muted-foreground) |
| Current color | var(--foreground) |
| Separator | daisyUI breadcrumbs slash between items |

Tokens used: `muted-foreground`, `foreground`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Move between the breadcrumb links |
| Enter | Follow the focused crumb link |

Role / ARIA: nav element with aria-label=Breadcrumb. Ancestor crumbs are links; the current page is a span with aria-current=page (not a link).

Focus: Links show their standard focus indicator; the current page item is non-interactive.

Screen reader: The nav label announces the region; aria-current=page identifies the user's location in the hierarchy.

Touch target: Crumb links are small text; ensure adequate spacing on touch and only show breadcrumbs at medium width and up.

Reduced motion: No motion.

## Native (SwiftUI)

Parity: guidance only - no native component yet.

```swift
HStack(spacing: 4) {
    Button("Home") { }.buttonStyle(.plain)
    Text("/").foregroundStyle(.secondary)
    Text("Breadcrumb").accessibilityAddTraits(.isSelected)
}
.accessibilityElement(children: .contain)
.accessibilityLabel("Breadcrumb")
```

No native breadcrumb control; on iOS the navigation stack back button usually serves this role. Compose an HStack when an explicit trail is needed.

## Default

HEEx:

```heex
<.breadcrumb>
  <:item navigate={~p"/"}>Home</:item>
  <:item navigate={~p"/docs"}>Components</:item>
  <:item>Breadcrumb</:item>
</.breadcrumb>
```

```html
<nav class="breadcrumbs text-sm" aria-label="Breadcrumb">
  <ul>
    <li><a href="#">Home</a></li>
    <li><a href="#">Components</a></li>
    <li><span aria-current="page">Breadcrumb</span></li>
  </ul>
</nav>
```
