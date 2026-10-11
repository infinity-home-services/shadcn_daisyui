# Empty

A placeholder for when there is no content to show.

## Specs

| Part | Description |
| --- | --- |
| Container | A centered, dashed-border box for the empty state. |
| Icon | A muted hero icon signaling the empty/missing content. |
| Copy | A title plus muted description, optionally followed by an action button. |

| Property | Value |
| --- | --- |
| Border | 1px dashed var(--border-color), var(--radius-lg) |
| Padding | p-8, centered, gap-2 between elements |
| Icon size | size-7 in var(--muted-foreground) |
| Text | text-sm title, text-sm muted description |

Tokens used: `foreground`, `muted-foreground`, `border-color`, `background`

## Accessibility

Role / ARIA: A structural placeholder block; the icon is aria-hidden and the text carries the meaning.

Focus: Not focusable itself; any recovery action button manages its own focus.

Screen reader: The title and description are read as text; consider aria-live if the empty state appears after a filter.

Touch target: Any action button should reach 2.75rem effective area on touch.

Reduced motion: No motion.

## Native (SwiftUI)

Parity: native parity with the web component.

```swift
ContentUnavailableView {
  Label("No results found", systemImage: "tray")
} description: {
  Text("Try adjusting your search.")
} actions: {
  Button("Clear filters") { clearFilters() }
}
```

Maps directly to ContentUnavailableView, including the optional action button.

## Default

```html
<div class="flex w-full max-w-sm flex-col items-center justify-center gap-2 rounded-lg border border-dashed border-base-300 p-8 text-center">
  <span class="hero-inbox size-7 text-muted-foreground" aria-hidden="true"></span>
  <p class="text-sm font-medium">No results found</p>
  <p class="text-sm text-muted-foreground">Try adjusting your search.</p>
  <button class="btn btn-outline btn-sm mt-1">Clear filters</button>
</div>
```
