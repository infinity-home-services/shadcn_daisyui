# Input Group

An input with attached addons or actions.

## Specs

| Part | Description |
| --- | --- |
| Group | A `.join` container fusing addons and the input into one field. |
| Addon | A leading/trailing `.join-item .btn` used as a prefix label or action. |
| Input | The `.join-item .input` field, shadow cleared so it sits flush. |

| Property | Value |
| --- | --- |
| Height | 2.25rem across addons and input |
| Corner radius | var(--radius-md) on the outer corners only |
| Input padding | padding-inline 0.75rem |
| Border | shared 1px var(--input); seams collapse to a single line |

Tokens used: `background`, `foreground`, `input`, `border-color`, `primary`, `primary-foreground`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Move between the input and any interactive addons |
| Enter | Submit or trigger a trailing action button |

Role / ARIA: A text input with attached addons; the input keeps its own label or aria-label.

Focus: Focusing the input swaps its border to var(--ring) and shows the ring-shadow.

Screen reader: Static prefixes are read as text; the input is labeled independently of the addons.

Touch target: 2.25rem field height; action buttons should reach 2.75rem effective area on touch.

Reduced motion: Focus styling is an instant color change with no transition.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
HStack(spacing: 0) {
  Text("https://").foregroundStyle(.secondary).padding(.horizontal, 8)
  TextField("example.com", text: $url)
  Button("Copy") { copy() }
}
.overlay(RoundedRectangle(cornerRadius: 8).stroke(.separator))
```

No direct primitive; compose an HStack with a shared rounded border, or use a TextField with a trailing label/button.

## Default

```html
<div class="join">
  <span class="join-item btn btn-outline pointer-events-none">https://</span>
  <input class="join-item input" placeholder="example.com" />
  <button class="join-item btn btn-primary">Copy</button>
</div>
```
