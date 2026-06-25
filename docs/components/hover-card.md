# Hover Card

A card of preview content shown on hover.

## Specs

| Part | Description |
| --- | --- |
| Trigger | An inline link/element that reveals the card on hover or focus. |
| Card | A `.dropdown-content` popover surface holding preview content. |

| Property | Value |
| --- | --- |
| Surface | var(--popover) on var(--border-color), var(--radius-md), shadow-sm |
| Padding | p-4 inside the card |
| Width | w-72 (preview content width) |
| Offset | mt-2 below the trigger |

Tokens used: `popover`, `popover-foreground`, `border-color`, `foreground`, `muted-foreground`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Focus the trigger, which also reveals the card |
| Esc | Move focus away to dismiss the card |

Role / ARIA: A trigger that reveals supplementary preview content; purely informational, not a menu.

Focus: The trigger shows the ring-shadow outline and the card opens on focus as well as hover.

Screen reader: Preview content is read when focus enters it; treat it as non-essential supplementary detail.

Touch target: Hover has no touch equivalent; provide a tap path to the same information on touch surfaces.

Reduced motion: The card appears without animated transitions.

## Native (SwiftUI)

Parity: guidance only - no native component yet.

```swift
Text("@shadcn")
  .popover(isPresented: $showCard) {
    ProfilePreview().padding()
  }
```

There is no hover on touch; bind a .popover to a tap or long-press instead of pointer hover.

## Default

```html
<div class="dropdown dropdown-hover">
  <div tabindex="0" role="button" class="link link-primary">@shadcn</div>
  <div tabindex="0" class="dropdown-content z-10 mt-2 w-72 p-4">
    <div class="flex items-start gap-3">
      <div class="avatar avatar-placeholder shrink-0">
        <div class="size-12 rounded-full"><span>SC</span></div>
      </div>
      <div class="space-y-1">
        <p class="text-sm font-semibold">@shadcn</p>
        <p class="text-sm text-muted-foreground">The library you copy into your app. Joined December 2021.</p>
      </div>
    </div>
  </div>
</div>
```
