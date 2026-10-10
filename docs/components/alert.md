# Alert

Displays a callout for user attention.

## Specs

| Part | Description |
| --- | --- |
| Container | Bordered card-surface region carrying role=alert. |
| Title | Optional medium-weight heading line. |
| Description | Muted body text; tinted destructive in the error variant. |

| Property | Value |
| --- | --- |
| Padding | 0.75rem block, 1rem inline (py-3 px-4) |
| Radius | var(--radius-lg) |
| Border | 1px var(--border-color); error blends 30% destructive |
| Font | 0.875rem (text-sm) |
| Shadow | none (flat) |

Tokens used: `card`, `card-foreground`, `border-color`, `destructive`, `muted-foreground`

## Accessibility

Role / ARIA: Renders role=alert, so assistive tech announces the content as an assertive live region the moment it appears.

Focus: Not focusable; it is an announcement, not a control. Any action buttons inside keep their own focus.

Screen reader: Inserted alert text is read immediately. Reserve role=alert for genuinely important, time-sensitive messages.

Touch target: Container has no hit requirement; nested actions follow the 44pt minimum.

Reduced motion: Static surface; no entrance animation.

## Native (SwiftUI)

Parity: guidance only - no native component yet.

```swift
VStack(alignment: .leading, spacing: 4) {
    Text("Error").font(.subheadline.weight(.medium))
    Text("Your session has expired.").foregroundStyle(.secondary)
}
.padding(.horizontal, 16).padding(.vertical, 12)
.background(.background, in: RoundedRectangle(cornerRadius: 8))
.overlay(RoundedRectangle(cornerRadius: 8).stroke(.separator))
```

This is an inline banner, not an interrupting .alert() modal. SwiftUI has no inline alert primitive, so compose a bordered VStack.

## Props

| Name | Type | Default |
| --- | --- | --- |
| variant | default \| destructive | default |

## Default & destructive

HEEx:

```heex
<.alert>
  <:title>Heads up!</:title>
  You can add components to your app using the CLI.
</.alert>

<.alert variant="destructive">
  <:title>Error</:title>
  Your session has expired. Please log in again.
</.alert>
```

```html
<div class="w-full space-y-3">
  <div class="alert" role="alert">
    <span class="hero-information-circle size-4" aria-hidden="true"></span>
    <div>
      <h3 class="text-sm font-medium">Heads up!</h3>
      <p class="text-sm text-muted-foreground">You can add components to your app using the CLI.</p>
    </div>
  </div>
  <div class="alert alert-error" role="alert">
    <span class="hero-exclamation-triangle size-4" aria-hidden="true"></span>
    <div>
      <h3 class="text-sm font-medium">Error</h3>
      <p class="text-sm">Your session has expired. Please log in again.</p>
    </div>
  </div>
</div>
```
