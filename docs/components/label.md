# Label

An accessible label associated with a form control.

## Specs

| Part | Description |
| --- | --- |
| Label | Text element associated with a control via the for attribute. |

| Property | Value |
| --- | --- |
| Font | 0.875rem / 500 (text-sm font-medium) |
| Color | inherits foreground |

Tokens used: `foreground`, `muted-foreground`

## Accessibility

Role / ARIA: Native label element. Its for attribute ties it to a control id so the label is announced as that control name; clicking the label focuses/toggles the control.

Focus: Not focusable itself; it forwards activation to its associated control.

Screen reader: Provides the accessible name for the linked input. Keep label text concise and descriptive.

Touch target: When wrapping a control, sizes the combined tappable row toward the 44pt minimum.

Reduced motion: No motion.

## Native (SwiftUI)

Parity: native parity with the web component.

```swift
Text("Email")
    .font(.subheadline.weight(.medium))
```

SwiftUI controls take their label inline (TextField(_:), Toggle(_:)), so a standalone Label maps to a styled Text or an accessibility label.

## Default

HEEx:

```heex
<.label for="terms">Accept terms and conditions</.label>
```

```html
<label class="flex items-center gap-2 text-sm font-medium">
  <input type="checkbox" class="checkbox" /> Accept terms and conditions
</label>
```
