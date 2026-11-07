# Avatar

An image element with a text fallback.

## Specs

| Part | Description |
| --- | --- |
| Frame | Sized, shaped wrapper (rounded-full by default) clipping the image. |
| Image / Fallback | Photo when present, otherwise initials on a muted placeholder. |

| Property | Value |
| --- | --- |
| Default size | w-10 (2.5rem); set via class |
| Shape | rounded-full (default) or any radius class |
| Fallback bg | var(--muted) |
| Fallback text | var(--muted-foreground), text-sm / 500 |
| Group overlap | -space-x-3 with a background-colored ring |

Tokens used: `muted`, `muted-foreground`, `background`, `border-color`

## Accessibility

Role / ARIA: An image (with alt text) or a decorative initials span. The image alt should name the person; a bare fallback like JD needs surrounding context to be meaningful.

Focus: Not focusable unless wrapped in a link/button.

Screen reader: Provide a meaningful alt for the image; mark the initials fallback as decorative if the name is already announced nearby.

Touch target: Decorative by default; if interactive, size the wrapper to 44pt.

Reduced motion: Static; no animation.

## Native (SwiftUI)

Parity: native parity with the web component.

```swift
AsyncImage(url: user.photoURL) { image in
    image.resizable().scaledToFill()
} placeholder: {
    Text(user.initials)
}
.frame(width: 40, height: 40)
.clipShape(Circle())
```

Compose AsyncImage with a clip shape; supply the person's name as the accessibility label.

## Placeholders & group

HEEx:

```heex
<.avatar fallback="JD" />
<.avatar fallback="UI" shape="rounded-lg" />
<.avatar_group>
  <.avatar fallback="AB" />
  <.avatar fallback="CD" />
  <.avatar fallback="+3" />
</.avatar_group>
```

```html
<div class="flex items-center gap-4">
  <div class="avatar avatar-placeholder">
    <div class="w-10 rounded-full"><span class="text-sm font-medium">JD</span></div>
  </div>
  <div class="avatar avatar-placeholder">
    <div class="w-10 rounded-lg"><span class="text-sm font-medium">UI</span></div>
  </div>
  <div class="avatar-group -space-x-3">
    <div class="avatar avatar-placeholder">
      <div class="w-10 rounded-full"><span class="text-xs">AB</span></div>
    </div>
    <div class="avatar avatar-placeholder">
      <div class="w-10 rounded-full"><span class="text-xs">CD</span></div>
    </div>
    <div class="avatar avatar-placeholder">
      <div class="w-10 rounded-full"><span class="text-xs">+3</span></div>
    </div>
  </div>
</div>
```
