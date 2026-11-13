# Scroll Area

A scrollable region with a fixed height.

## Specs

| Part | Description |
| --- | --- |
| Viewport | A fixed-height box with overflow-y-auto that clips and scrolls its content. |
| Content | The scrolling rows/items inside the viewport. |

| Property | Value |
| --- | --- |
| Height | fixed (h-32 in the demo) to force scrolling |
| Border | 1px var(--border-color), var(--radius-lg) |
| Padding | p-4 inside the viewport |
| Row dividers | border-b var(--color-base-200) between rows |

Tokens used: `background`, `foreground`, `border-color`, `color-base-200`

## Accessibility

| Keys | Action |
| --- | --- |
| Arrow / Page / Home / End | Scroll when the region is focused |
| Tab | Reach focusable items inside the region |

Role / ARIA: A structural scroll container; add role=region with an aria-label when the region needs a name.

Focus: Make the viewport focusable (tabindex) if keyboard scrolling without interactive children is needed.

Screen reader: Content is read in order; a named region helps users understand the scrollable boundary.

Touch target: Scrolls with native touch panning; any rows that are tappable need 2.75rem hit areas.

Reduced motion: Native scrolling; honor reduced-motion for any smooth-scroll behavior.

## Native (SwiftUI)

Parity: native parity with the web component.

```swift
ScrollView {
  LazyVStack(alignment: .leading) {
    ForEach(items) { item in
      Text(item.title)
    }
  }
}
.frame(height: 128)
```

Maps to a height-constrained ScrollView; iOS provides native scroll indicators and rubber-banding.

## Default

```html
<div class="w-full max-w-sm space-y-1.5">
  <p class="text-sm font-medium">Scroll area</p>
  <div class="h-32 overflow-y-auto rounded-lg border border-base-300 p-4 text-sm">
    <p class="border-b border-base-200 py-1">Item 1</p>
    <p class="border-b border-base-200 py-1">Item 2</p>
    <p class="border-b border-base-200 py-1">Item 3</p>
    <p class="border-b border-base-200 py-1">Item 4</p>
    <p class="border-b border-base-200 py-1">Item 5</p>
    <p class="border-b border-base-200 py-1">Item 6</p>
    <p class="border-b border-base-200 py-1">Item 7</p>
    <p class="border-b border-base-200 py-1">Item 8</p>
    <p class="py-1">Item 9</p>
  </div>
</div>
```
