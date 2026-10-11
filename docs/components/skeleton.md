# Skeleton

A placeholder preview while content is loading.

## Specs

| Part | Description |
| --- | --- |
| Placeholder | Muted block sized with classes to mimic incoming content. |

| Property | Value |
| --- | --- |
| Background | var(--muted) |
| Radius | var(--radius-md) (round for avatars) |
| Size | set via height/width classes (e.g. h-4 w-48) |

Tokens used: `muted`

## Accessibility

Role / ARIA: Purely visual loading placeholder with no role. Mark it aria-hidden and announce loading state via an aria-live status elsewhere so screen-reader users are not given empty boxes.

Focus: Not focusable.

Screen reader: Skeletons should be hidden from the accessibility tree; convey loading with a live-region message instead.

Touch target: No hit area.

Reduced motion: Skeleton is excluded from the instant-toggle rule so its shimmer can run; disable the shimmer under prefers-reduced-motion.

## Native (SwiftUI)

Parity: guidance only - no native component yet.

```swift
RoundedRectangle(cornerRadius: 6)
    .fill(Color(.systemGray5))
    .frame(height: 16)
    .redacted(reason: .placeholder)
```

iOS uses .redacted(reason: .placeholder) for skeleton-style loading; the shimmer effect is a custom modifier.

## Default

HEEx:

```heex
<.skeleton class="h-10 w-10 rounded-full" />
<.skeleton class="h-3 w-40" />
<.skeleton class="h-3 w-24" />
```

```html
<div class="flex items-center gap-3">
  <div class="skeleton h-10 w-10 rounded-full"></div>
  <div class="space-y-2">
    <div class="skeleton h-3 w-40"></div>
    <div class="skeleton h-3 w-24"></div>
  </div>
</div>
```
