# Separator

Visually or semantically separates content.

## Specs

| Part | Description |
| --- | --- |
| Rule | A thin divider line, horizontal or vertical (divider / divider-horizontal). |

| Property | Value |
| --- | --- |
| Thickness | 1px hairline |
| Color | var(--border-color) via the divider |
| Orientation | horizontal (default) or vertical |

Tokens used: `border-color`, `muted-foreground`

## Accessibility

Role / ARIA: Purely decorative divider. If it semantically separates content, expose role=separator; otherwise keep it aria-hidden so it adds no noise.

Focus: Not focusable (a static separator, unlike the interactive resizable handle).

Screen reader: A plain divider is ignored. Use a real heading/landmark when the separation carries meaning.

Touch target: No hit area.

Reduced motion: No motion.

## Native (SwiftUI)

Parity: native parity with the web component.

```swift
Divider()
```

Divider is the direct equivalent; it adapts to orientation based on its container (HStack vs VStack).

## Props

| Name | Type | Default |
| --- | --- | --- |
| orientation | horizontal \| vertical | horizontal |

## Horizontal & vertical

HEEx:

```heex
<.separator />
<.separator orientation="vertical" />
```

```html
<div class="w-full max-w-sm">
  <div class="space-y-1">
    <p class="text-sm font-medium leading-none">Radix Primitives</p>
    <p class="text-sm text-muted-foreground">An open-source UI component library.</p>
  </div>
  <div class="divider my-3"></div>
  <div class="flex h-5 items-center gap-4 text-sm">
    <span>Blog</span>
    <div class="divider divider-horizontal"></div>
    <span>Docs</span>
    <div class="divider divider-horizontal"></div>
    <span>Source</span>
  </div>
</div>
```
