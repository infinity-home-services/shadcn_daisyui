# Marker

Displays an inline status, system note, bordered row, or labeled separator in a conversation.

## Usage guidance

Use when:

- Agent or system activity in a transcript ("Explored 4 files", "Switched branch")
- Live status while work runs ("Thinking…", "Running tests") with status + shimmer
- Date or event separators between groups of messages (variant="separator")

Don't use for:

- Messages from a person or the assistant - use <.message> + <.bubble>
- Page-level notices - use <.alert>; transient confirmations - use toast()

Sizing: 14px muted text, 16px icon, 8px icon gap. Border variant adds 8px bottom padding and a 1px rule; separator draws 1px rules either side.

Responsive: Markers span the full width of the transcript and wrap long text; separator labels stay centered.

iOS: A Label(text, systemImage:) in .secondary foreground; separators as HStack { Divider; Text; Divider }. Use ProgressView() for the status spinner.

## Specs

| Part | Description |
| --- | --- |
| Marker | Full-width row (div, a, or button) with data-variant. |
| Icon (optional) | 16px decorative glyph or spinner. |
| Content | Muted text; optional shimmer while in progress. |

| Property | Value |
| --- | --- |
| Text | 14px muted-foreground |
| Icon | 16px, 8px gap |
| separator | 1px border-color rules either side of centered text |
| border | 1px bottom border, 8px bottom padding |
| Link / button hover | foreground text |
| Shimmer | 2s linear sweep, highlight 20% alpha (lighter in dark) |

Tokens used: `muted-foreground`, `foreground`, `border-color`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Focus link and button markers |
| Enter / Space | Activate the focused marker |

Role / ARIA: status sets role=status, so live progress ("Thinking…") is announced politely. Link markers are <a>; action markers are <button type=button>.

Focus: Only link and button markers are focusable.

Screen reader: The icon is aria-hidden; the text must say what happened. Don't mark every historical note as status - only the one that's live.

Touch target: Action markers are text-height; on touch, give them vertical padding (py-2) to reach 44pt.

Reduced motion: The shimmer stops under prefers-reduced-motion; spinners keep turning slowly.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
Label("Explored 4 files", systemImage: "magnifyingglass")
    .font(.subheadline)
    .foregroundStyle(.secondary)

HStack(spacing: 4) {
    VStack { Divider() }
    Text("Today").font(.subheadline).foregroundStyle(.secondary)
    VStack { Divider() }
}
```

For the status marker use HStack { ProgressView(); Text("Thinking…") }, and announce it with .accessibilityAddTraits(.updatesFrequently).

## Props

| Name | Type | Default |
| --- | --- | --- |
| variant | default \| separator \| border | default |
| status | boolean (role=status) | false |
| shimmer | boolean | false |
| as | div \| button | div |
| href / navigate / patch | string | nil (renders a link) |
| :icon | slot (decorative) | - |

## Default

HEEx:

```heex
<.marker>
  <:icon><.icon name="hero-arrows-right-left" /></:icon>
  Switched to a new branch
</.marker>
<.marker status shimmer>
  <:icon><.spinner size="loading-xs" /></:icon>
  Thinking...
</.marker>
<.marker variant="separator">Conversation compacted</.marker>
```

```html
<div class="flex w-full max-w-sm flex-col gap-8">
  <div data-slot="marker" data-variant="default">
    <span data-slot="marker-icon" aria-hidden="true"><span class="hero-arrows-right-left"></span></span>
    <span data-slot="marker-content">Switched to a new branch</span>
  </div>
  <div data-slot="marker" data-variant="default" role="status">
    <span data-slot="marker-icon" aria-hidden="true"><span class="loading loading-spinner loading-xs"></span></span>
    <span data-slot="marker-content" class="shimmer">Thinking...</span>
  </div>
  <div data-slot="marker" data-variant="separator">
    <span data-slot="marker-content">Conversation compacted</span>
  </div>
  <div data-slot="marker" data-variant="default">
    <span data-slot="marker-icon" aria-hidden="true"><span class="hero-magnifying-glass"></span></span>
    <span data-slot="marker-content">Explored 4 files</span>
  </div>
</div>
```

## Variants

HEEx:

```heex
<.marker>A default marker for inline notes.</.marker>
<.marker variant="separator">A separator marker</.marker>
<.marker variant="border">A border marker for row boundaries.</.marker>
```

```html
<div class="flex w-full max-w-sm flex-col gap-8">
  <div data-slot="marker" data-variant="default"><span data-slot="marker-content">A default marker for inline notes.</span></div>
  <div data-slot="marker" data-variant="separator"><span data-slot="marker-content">A separator marker</span></div>
  <div data-slot="marker" data-variant="border"><span data-slot="marker-content">A border marker for row boundaries.</span></div>
</div>
```

## Status & shimmer

HEEx:

```heex
<.marker status>
  <:icon><.spinner size="loading-xs" /></:icon>
  Compacting conversation
</.marker>
<.marker variant="separator" status shimmer>Reading 4 files</.marker>
```

```html
<div class="flex w-full max-w-sm flex-col gap-8">
  <div data-slot="marker" data-variant="default" role="status">
    <span data-slot="marker-icon" aria-hidden="true"><span class="loading loading-spinner loading-xs"></span></span>
    <span data-slot="marker-content">Compacting conversation</span>
  </div>
  <div data-slot="marker" data-variant="separator" role="status">
    <span data-slot="marker-icon" aria-hidden="true"><span class="loading loading-spinner loading-xs"></span></span>
    <span data-slot="marker-content">Running tests</span>
  </div>
  <div data-slot="marker" data-variant="default" role="status">
    <span data-slot="marker-content" class="shimmer">Thinking...</span>
  </div>
  <div data-slot="marker" data-variant="separator" role="status">
    <span data-slot="marker-content" class="shimmer">Reading 4 files</span>
  </div>
</div>
```

## Border

HEEx:

```heex
<.marker :for={step <- @steps} variant="border">
  <:icon><.icon name={step.icon} /></:icon>
  {step.label}
</.marker>
```

```html
<div class="flex w-full max-w-sm flex-col gap-3">
  <div data-slot="marker" data-variant="border">
    <span data-slot="marker-icon" aria-hidden="true"><span class="hero-arrows-right-left"></span></span>
    <span data-slot="marker-content">Switched to release-candidate</span>
  </div>
  <div data-slot="marker" data-variant="border">
    <span data-slot="marker-icon" aria-hidden="true"><span class="hero-magnifying-glass"></span></span>
    <span data-slot="marker-content">Reviewed 8 related files</span>
  </div>
  <div data-slot="marker" data-variant="border">
    <span data-slot="marker-icon" aria-hidden="true"><span class="hero-document-text"></span></span>
    <span data-slot="marker-content">Opened implementation notes</span>
  </div>
</div>
```

## Links & buttons

HEEx:

```heex
<.marker href={@pr_url}>
  <:icon><.icon name="hero-arrows-right-left" /></:icon>
  View the pull request
</.marker>
<.marker as="button" phx-click="revert">
  <:icon><.icon name="hero-arrow-uturn-left" /></:icon>
  Revert this change
</.marker>
```

```html
<div class="flex w-full max-w-sm flex-col gap-8">
  <a href="#links-and-buttons" data-slot="marker" data-variant="default">
    <span data-slot="marker-icon" aria-hidden="true"><span class="hero-arrows-right-left"></span></span>
    <span data-slot="marker-content">View the pull request</span>
  </a>
  <button type="button" data-slot="marker" data-variant="default" data-toast="You clicked the revert button">
    <span data-slot="marker-icon" aria-hidden="true"><span class="hero-arrow-uturn-left"></span></span>
    <span data-slot="marker-content">Revert this change</span>
  </button>
</div>
```
