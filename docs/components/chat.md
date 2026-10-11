# Chat

Chat-bubble message rows aligned left or right.

## Specs

| Part | Description |
| --- | --- |
| Chat row | Wrapper aligned with chat-start (left) or chat-end (right). |
| Bubble | chat-bubble surface; chat-bubble-primary for the sender's own messages. |

| Property | Value |
| --- | --- |
| Bubble radius | var(--radius-lg) |
| Incoming bubble | muted background, foreground text |
| Primary bubble | primary background, primary-foreground text |
| Alignment | chat-start left, chat-end right |

Tokens used: `muted`, `foreground`, `primary`, `primary-foreground`

## Accessibility

Role / ARIA: Presentational message rows; add a log/list role if used as a live transcript.

Focus: Bubbles are not focusable on their own.

Screen reader: Bubble text reads in source order; sender is conveyed only by side/color.

Touch target: Not interactive; no hit-target requirement.

Reduced motion: Static; no animation to suppress.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
HStack {
    if message.isMine { Spacer() }
    Text(message.text)
        .padding(10)
        .background(message.isMine ? Color.accentColor : Color(.secondarySystemBackground))
        .foregroundStyle(message.isMine ? .white : .primary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    if !message.isMine { Spacer() }
}
```

Build message bubbles with aligned HStacks; no stock chat control exists.

## Default

```html
<div class="w-full">
  <div class="chat chat-start">
    <div class="chat-bubble">You underestimate my power!</div>
  </div>
  <div class="chat chat-end">
    <div class="chat-bubble chat-bubble-primary">Don't try it 😈</div>
  </div>
</div>
```
