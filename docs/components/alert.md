# Alert

Displays a callout for user attention.

The inner block renders in a div, so it can hold paragraphs and links. Buttons go in <:actions>, never inside the text.

## Specs

| Part | Description |
| --- | --- |
| Container | Bordered card-surface region carrying role=alert. |
| Icon | Optional <:icon>, 16px, left of the title and description. |
| Title | Optional medium-weight heading line. |
| Description | Muted body text in a div (holds paragraphs and links); tinted destructive in the error variant. |
| Actions | Optional <:actions>: right of the text from 640px, below it (aligned with the text) on phones. |

| Property | Value |
| --- | --- |
| Padding | 0.75rem block, 1rem inline (py-3 px-4) |
| Radius | var(--radius-lg) |
| Border | 1px var(--border-color); error blends 30% destructive |
| Font | 0.875rem (text-sm) |
| Shadow | none (flat) |
| Gaps | 0.75rem icon to text and text to actions |

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
| <:title> | slot | - |
| <:icon> | slot, 16px icon left of the text | - |
| <:actions> | slot, right of the text from sm, below it on phones | - |

## Default & destructive

HEEx:

```heex
<.alert>
  <:icon><.icon name="hero-information-circle" /></:icon>
  <:title>Heads up!</:title>
  You can add components to your app using the CLI.
</.alert>

<.alert variant="destructive">
  <:icon><.icon name="hero-exclamation-triangle" /></:icon>
  <:title>Error</:title>
  Your session has expired. Please log in again.
</.alert>
```

```html
<div class="w-full space-y-3">
  <div class="alert" role="alert">
    <span class="alert-icon" aria-hidden="true"><span class="hero-information-circle"></span></span>
    <div class="alert-content">
      <h3 class="text-sm font-medium">Heads up!</h3>
      <div class="text-sm text-muted-foreground">You can add components to your app using the CLI.</div>
    </div>
  </div>
  <div class="alert alert-error" role="alert">
    <span class="alert-icon" aria-hidden="true"><span class="hero-exclamation-triangle"></span></span>
    <div class="alert-content">
      <h3 class="text-sm font-medium">Error</h3>
      <div class="text-sm text-muted-foreground">Your session has expired. Please log in again.</div>
    </div>
  </div>
</div>
```

## With an action

HEEx:

```heex
<.alert>
  <:icon><.icon name="hero-inbox" /></:icon>
  <:title>New leads</:title>
  3 new leads are waiting.
  <:actions>
    <.button size="sm" navigate={~p"/leads/new"}>Go to new leads</.button>
  </:actions>
</.alert>
```

```html
<div class="alert w-full" role="alert">
  <span class="alert-icon" aria-hidden="true"><span class="hero-inbox"></span></span>
  <div class="alert-content">
    <h3 class="text-sm font-medium">New leads</h3>
    <div class="text-sm text-muted-foreground">3 new leads are waiting.</div>
  </div>
  <div class="alert-actions">
    <a href="#" class="btn btn-primary btn-sm">Go to new leads</a>
  </div>
</div>
```
