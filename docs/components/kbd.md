# Kbd

Displays keyboard keys or shortcuts inline.

## Specs

| Part | Description |
| --- | --- |
| Key | Inline kbd element styled as a keycap. |

| Property | Value |
| --- | --- |
| Radius | var(--radius-sm) |
| Border | 1px var(--border-color) |
| Background | var(--muted) |
| Text | var(--muted-foreground), 0.75rem |

Tokens used: `muted`, `muted-foreground`, `border-color`

## Accessibility

Role / ARIA: Native kbd element marking keyboard input. Semantic but non-interactive; it labels a shortcut, it does not trigger one.

Focus: Not focusable.

Screen reader: Read inline as its text content. Spell out non-obvious symbols (write Command K rather than relying on the glyph alone) where clarity matters.

Touch target: Decorative; no hit area.

Reduced motion: No motion.

## Native (SwiftUI)

Parity: guidance only - no native component yet.

```swift
Text("⌘K")
    .font(.caption.monospaced())
    .padding(.horizontal, 4)
    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 4))
```

No native keycap view; SwiftUI's .keyboardShortcut(_:) wires the actual shortcut while a styled Text shows the hint.

## Default

```html
<p class="text-sm text-muted-foreground">
  Press <kbd class="kbd">⌘</kbd> <kbd class="kbd">K</kbd> to open the command menu.
</p>
```
