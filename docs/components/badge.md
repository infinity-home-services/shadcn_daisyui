# Badge

Displays a badge or a component that looks like a badge.

## Specs

| Part | Description |
| --- | --- |
| Container | Inline span carrying the variant background and 1px border. |
| Label | Short text (and optional icon) describing the status or count. |

| Property | Value |
| --- | --- |
| Height | auto (content + padding) |
| Padding | 0.125rem block, 0.5rem inline (py-0.5 px-2) |
| Radius | 9999px (rounded-full) |
| Border | 1px transparent (outline variant uses var(--border-color)) |
| Font | 0.75rem / 500 (text-xs font-medium) |

Tokens used: `primary`, `primary-foreground`, `secondary`, `destructive`, `border-color`

## Accessibility

Role / ARIA: Plain inline span with no implicit role. Color is decorative; the text must carry the meaning, since the variant hue alone is not announced.

Focus: Not focusable - a badge is a static label, not an interactive target.

Screen reader: Read inline as part of the surrounding text. If a badge conveys status (e.g. a count), give nearby context so it is not a bare number.

Touch target: Decorative; no hit area requirement. If made tappable, wrap it in a button or link sized to 44pt.

Reduced motion: No motion.

## Native (SwiftUI)

Parity: native parity with the web component.

```swift
Text("Badge")
    .font(.caption.weight(.medium))
    .padding(.horizontal, 8)
    .padding(.vertical, 2)
    .background(Color.accentColor, in: Capsule())
    .foregroundStyle(.white)
```

No first-class Badge view; compose a capsule-clipped Text. .badge(_:) on tab items is a different, count-only construct.

## Props

| Name | Type | Default |
| --- | --- | --- |
| variant | default \| secondary \| outline \| destructive | default |

## Variants

HEEx:

```heex
<.badge>Primary</.badge>
<.badge variant="secondary">Secondary</.badge>
<.badge variant="outline">Outline</.badge>
<.badge variant="destructive">Destructive</.badge>
```

```html
<span class="badge badge-primary">Primary</span>
<span class="badge badge-secondary">Secondary</span>
<span class="badge badge-outline">Outline</span>
<span class="badge badge-error">Destructive</span>
```
