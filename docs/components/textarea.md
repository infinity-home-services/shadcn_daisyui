# Textarea

A multi-line text input field.

## Specs

| Part | Description |
| --- | --- |
| Label | Optional field label tied to the control via for/id. |
| Control | Multi-line textarea with bordered surface. |
| Error | Validation message rendered below when the field is invalid. |

| Property | Value |
| --- | --- |
| Padding | 0.5rem block, 0.75rem inline (py-2 px-3) |
| Radius | var(--radius-md) |
| Border | 1px var(--input) |
| Shadow | var(--shadow-xs) |
| Font | 0.875rem (text-sm) |

Tokens used: `input`, `foreground`, `muted-foreground`, `ring`, `destructive`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Move focus to / from the textarea |
| Enter | Insert a newline within the textarea |
| Arrows / Home / End | Move the caret through the text |

Role / ARIA: Native textarea (implicit role textbox, multiline). Bound to a FormField so id/name/value/errors are wired automatically.

Focus: Border switches to var(--ring) with a ring shadow on focus; the focus ring is always visible (not hover-gated).

Screen reader: Associated label is announced; placeholder is supplementary, never a label substitute. Errors surface via the rendered error text.

Touch target: Resizable text region; comfortably exceeds the 44pt minimum.

Reduced motion: Focus transition is instant under the theme; no animation to suppress.

## Native (SwiftUI)

Parity: native parity with the web component.

```swift
TextEditor(text: $bio)
    .frame(minHeight: 80)
    .padding(8)
    .overlay(RoundedRectangle(cornerRadius: 6).stroke(.separator))
```

TextEditor is the multiline equivalent; TextField(_, axis: .vertical) also grows vertically and is often a cleaner fit.

## Default

HEEx:

```heex
<.textarea field={@form[:message]} label="Message" rows="3" placeholder="Type your message..." />
```

```html
<label class="block w-full max-w-sm space-y-1.5">
  <span class="text-sm font-medium">Message</span>
  <textarea class="textarea w-full" rows="3" placeholder="Type your message..."></textarea>
</label>
```
