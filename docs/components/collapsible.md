# Collapsible

A single expandable/collapsible section.

## Specs

| Part | Description |
| --- | --- |
| Section | A `.collapse` block (collapse-arrow) holding a checkbox toggle. |
| Trigger | The `.collapse-title` row that expands/collapses the section. |
| Content | The `.collapse-content` region revealed when open. |

| Property | Value |
| --- | --- |
| Trigger padding | 1rem block, padding-inline-end 2.5rem for the arrow |
| Trigger text | text-sm (0.875rem) font-medium |
| Content text | text-sm var(--muted-foreground) |
| Divider | border-bottom 1px var(--border-color) between sections |

Tokens used: `foreground`, `muted-foreground`, `border-color`, `color-base-300`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Move focus to the toggle |
| Space / Enter | Expand or collapse the section |

Role / ARIA: A disclosure: a toggle (checkbox) controls the visibility of an associated content region.

Focus: The toggle shows the ring-shadow focus outline.

Screen reader: Expose expanded/collapsed state (e.g. aria-expanded) so the open/closed status is announced.

Touch target: The full trigger row is tappable; ensure it reaches 2.75rem height on touch.

Reduced motion: Honor prefers-reduced-motion for the open/close height animation.

## Native (SwiftUI)

Parity: native parity with the web component.

```swift
DisclosureGroup("@shadcn starred 3 repositories") {
  Text("@radix-ui/primitives")
  Text("@radix-ui/colors")
}
```

Maps directly to DisclosureGroup, which manages its own expanded state and chevron.

## Default

```html
<div class="card w-full">
  <div class="card-body py-1">
    <div class="collapse collapse-arrow">
      <input type="checkbox" />
      <div class="collapse-title font-medium">@shadcn starred 3 repositories</div>
      <div class="collapse-content space-y-2 text-sm text-muted-foreground">
        <div class="rounded-md border border-base-300 px-3 py-2">@radix-ui/primitives</div>
        <div class="rounded-md border border-base-300 px-3 py-2">@radix-ui/colors</div>
      </div>
    </div>
  </div>
</div>
```
