# Toast

A brief, auto-dismissing notification.

## Usage guidance

Use when:

- Confirming a completed action the user doesn't need to act on ("Saved")
- Background results (export finished, message sent)

Don't use for:

- Errors that need action - show inline errors or an alert in place
- Anything the user must read - toasts disappear

Sizing: One line, optional action link; status variant matches the event.

Responsive: Bottom-center on compact (thumb zone), bottom-right on expanded.

iOS: No system toast: prefer in-place state change; if needed, a brief overlay with VoiceOver announcement (UIAccessibility.post).

## Specs

| Part | Description |
| --- | --- |
| Host | Fixed bottom-end container (toast-host) with role=status and aria-live=polite. |
| Toast | Alert/card injected by showToast(), animated in and out. |

| Property | Value |
| --- | --- |
| Position | toast-end toast-bottom, z-60 |
| Toast shadow | var(--shadow-sm) |
| Enter | shadcn-toast-in keyframe (~slide + fade) |
| Exit | shadcn-toast-out keyframe |

Tokens used: `popover`, `popover-foreground`, `card`, `border-color`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Reach an action/close control inside a toast (if present) |

Role / ARIA: The host is role=status with aria-live=polite, so appended toasts are announced without stealing focus. Use an assertive live region only for truly urgent messages.

Focus: Toasts do not steal focus; any close/action button inside is reachable in normal tab order.

Screen reader: The polite live region reads new toasts after the current utterance. Keep messages short and self-contained.

Touch target: Any dismiss/action control inside the toast should meet the 44pt minimum.

Reduced motion: The slide/fade keyframes should be reduced to a plain appearance under prefers-reduced-motion.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
someView
    .overlay(alignment: .bottom) {
        if showToast {
            Text("Saved")
                .padding()
                .background(.regularMaterial, in: Capsule())
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
```

No native toast/snackbar; compose a transient overlay with a transition. Announce it with .accessibilityAddTraits or an accessibility notification.

## Default

HEEx:

```heex
<%!-- Put one toast host in your root layout; the bundled showToast() appends to it.
     For server-driven notices use <.flash> instead. --%>
<.toast_host />
```

```html
<div class="flex flex-wrap items-center gap-3">
  <button class="btn btn-outline" onclick="window.showToast()">Show toast</button>
  <button class="btn btn-outline" onclick="window.showToast('success')">Show success</button>
</div>
<div id="toast-host" class="toast toast-end toast-bottom z-[60]" role="status" aria-live="polite"></div>
```
