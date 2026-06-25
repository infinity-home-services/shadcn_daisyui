# Card

A container for grouping related content and actions.

## Usage guidance

Use when:

- Grouping related content with a clear boundary (summary + actions)
- Dashboard tiles, settings sections, list items with rich content

Don't use for:

- Wrapping an entire page - pages are flat, cards are islands
- Nesting cards inside cards - flatten or use a separator

Sizing: card-body pads 24px and the card is rounded-xl - don't add extra padding inside or override the radius.

Responsive: Cards stack single-column on compact; grid them (grid gap-4 lg:grid-cols-2/3) from expanded up.

iOS: A grouped List section or a custom rounded container (Radius.xl, 16-24pt padding) - prefer the system grouped list when content is row-like.

## Specs

| Part | Description |
| --- | --- |
| Container | Bordered surface with rounded corners and a subtle shadow. |
| Body | Padded content region (card-body) holding title, description, and actions. |
| Title / Description | Semibold heading plus muted supporting text. |

| Property | Value |
| --- | --- |
| Radius | var(--radius-xl) |
| Border | 1px var(--border-color) |
| Shadow | var(--shadow-sm) |
| Body padding | 1.5rem (p-6) |
| Body gap | 0.375rem |

Tokens used: `card`, `card-foreground`, `border-color`, `muted-foreground`

## Accessibility

Role / ARIA: Generic grouping container (div). It carries no implicit landmark; if the card is a single clickable target, make the whole card a link/button and label it.

Focus: Not focusable by itself. Interactive children (buttons, links) keep their own focus order.

Screen reader: Use a real heading element for the title so the card participates in the heading outline.

Touch target: Container has no hit requirement; nested actions follow the 44pt minimum.

Reduced motion: Static surface; no animation.

## Native (SwiftUI)

Parity: native parity with the web component.

```swift
VStack(alignment: .leading, spacing: 6) {
    Text("Title").font(.headline)
    Text("Description").foregroundStyle(.secondary)
}
.padding(24)
.background(.background, in: RoundedRectangle(cornerRadius: 12))
.overlay(RoundedRectangle(cornerRadius: 12).stroke(.separator))
```

Closest native idiom is GroupBox or a styled container; a bordered RoundedRectangle background matches the shadcn metrics best.

## With form

HEEx:

```heex
<.card class="w-full max-w-sm">
  <.card_body>
    <.card_title>Create project</.card_title>
    <.card_description>Deploy your new project in one click.</.card_description>
    <div class="card-actions mt-6 flex justify-between">
      <.button variant="outline">Cancel</.button>
      <.button>Deploy</.button>
    </div>
  </.card_body>
</.card>
```

```html
<div class="card w-full max-w-sm">
  <div class="card-body">
    <h3 class="card-title">Create project</h3>
    <p class="text-sm text-muted-foreground">Deploy your new project in one click.</p>
    <div class="mt-4 space-y-3">
      <label class="block space-y-1.5">
        <span class="text-sm font-medium">Name</span>
        <input type="text" class="input w-full" placeholder="Name of your project" />
      </label>
      <label class="block space-y-1.5">
        <span class="text-sm font-medium">Framework</span>
        <select class="select w-full">
          <option disabled selected>Select</option>
          <option>Phoenix</option>
          <option>Next.js</option>
        </select>
      </label>
    </div>
    <div class="card-actions mt-6 flex justify-between">
      <button class="btn btn-outline">Cancel</button>
      <button class="btn btn-primary">Deploy</button>
    </div>
  </div>
</div>
```

## With toggle

```html
<div class="card w-full max-w-sm">
  <div class="card-body">
    <h3 class="card-title">Notifications</h3>
    <p class="text-sm text-muted-foreground">You have 3 unread messages.</p>
    <div class="mt-4 flex items-center justify-between rounded-lg border border-base-300 p-4">
      <div class="space-y-0.5">
        <p class="text-sm font-medium">Push Notifications</p>
        <p class="text-xs text-muted-foreground">Send to your device.</p>
      </div>
      <input type="checkbox" class="toggle" checked />
    </div>
    <div class="card-actions mt-6">
      <button class="btn btn-primary w-full">
        <span class="hero-check size-4" aria-hidden="true"></span> Mark all as read
      </button>
    </div>
  </div>
</div>
```
