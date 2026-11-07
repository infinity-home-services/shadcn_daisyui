# Hero

A full-width hero section layout.

## Specs

| Part | Description |
| --- | --- |
| Hero section | Full-width banner container. |
| Hero content | Centered block with heading, supporting text, and a CTA button. |

| Property | Value |
| --- | --- |
| Surface | bg-muted, 1px border-base-300, rounded-xl in the demo |
| Padding | py-12 vertical band |
| Heading | text-2xl font-bold tracking-tight |
| Body | text-sm muted-foreground; content max-w-md |

Tokens used: `muted`, `muted-foreground`, `color-base-300`, `primary`, `foreground`

## Accessibility

Role / ARIA: Presentational layout band; the heading and CTA carry their own semantics.

Focus: Only the CTA button (and any links) inside are focusable.

Screen reader: Heading reads as a heading; the CTA reads as a button.

Touch target: The CTA should meet the 44pt touch target on touch surfaces.

Reduced motion: Static; no animation to suppress.

## Native (SwiftUI)

Parity: guidance only - no native component yet.

```swift
ZStack {
    Color(.secondarySystemBackground)
    VStack(spacing: 12) {
        Text("Build faster").font(.title.bold())
        Text("shadcn looks, daisyUI ergonomics").font(.subheadline).foregroundStyle(.secondary)
        Button("Get started") { }.buttonStyle(.borderedProminent)
    }
}
```

Compose a ZStack header band; there is no stock hero control.

## Default

```html
<div class="hero w-full rounded-xl border border-base-300 bg-muted py-12">
  <div class="hero-content text-center">
    <div class="max-w-md space-y-3">
      <h1 class="text-2xl font-bold tracking-tight">Build faster</h1>
      <p class="text-sm text-muted-foreground">shadcn looks, daisyUI ergonomics - one theme file.</p>
      <button class="btn btn-primary">Get started</button>
    </div>
  </div>
</div>
```
