# Button

Displays a button or a component that looks like a button.

## Usage guidance

Use when:

- Triggering an action: submit, save, open a dialog, run a command
- The primary action of a view region (one btn-primary per region)

Don't use for:

- Navigation to another page - use a link (btn-link or a styled <a>)
- Toggling state - use toggle, switch, or toggle-group

Sizing: Default h-9 (36px) for desktop-dense UI; btn-sm (32px) in toolbars and table rows; btn-lg (40px) for compact-screen primary actions.

Responsive: On compact screens the primary action is usually full-width (btn-lg w-full) at the bottom of the content; keep ≥ 8px between adjacent buttons.

iOS: Map emphasis: primary → .borderedProminent, secondary/outline → .bordered, ghost → .borderless. Minimum 44pt hit area.

## Do / Don't

Do - One primary action per region:

```html
<button class="btn btn-primary">Save</button><button class="btn btn-outline">Cancel</button>
```

Don't - Competing primary buttons:

```html
<button class="btn btn-primary">Save</button><button class="btn btn-primary">Cancel</button><button class="btn btn-primary">Delete</button>
```

## Specs

| Part | Description |
| --- | --- |
| Container | The clickable surface - sets height, padding, radius, and a 1px border. |
| Label | Text and/or icon, 14px / font-medium, centered. |
| Icon (optional) | 16px leading or trailing glyph, 8px gap from the label. |

| Property | Value |
| --- | --- |
| Height | 2.25rem / 36px (default); btn-sm 2rem; btn-lg 2.5rem |
| Padding | 1rem inline (px-4) |
| Radius | var(--radius-md) |
| Gap | 0.5rem (icon ↔ label) |
| Border | 1px (transparent on solid variants) |
| Font | 0.875rem / weight 500 |
| Focus ring | 0 0 0 3px var(--ring) @ 50% |

Tokens used: `primary`, `primary-foreground`, `secondary`, `secondary-foreground`, `ring`, `destructive`, `destructive-foreground`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Move focus to / from the button |
| Enter / Space | Activate the button |

Role / ARIA: Native <button>. Icon-only buttons (btn-square) need an aria-label; decorative icons are aria-hidden.

Focus: Visible 3px focus ring (var(--ring)); focus is never removed, only restyled via :focus-visible.

Screen reader: Announced as a button with its label; the disabled attribute conveys the disabled state.

Touch target: 44pt minimum effective hit area on touch; h-9 (36px) is acceptable on pointer devices.

Reduced motion: Only color/box-shadow transitions (150ms); nothing that moves, so reduced-motion is unaffected.

## Native (SwiftUI)

Parity: native parity with the web component.

```swift
Button("Primary") { save() }
    .buttonStyle(.borderedProminent)   // secondary/outline → .bordered, ghost → .borderless
    .controlSize(.regular)             // .small ↔ btn-sm, .large ↔ btn-lg
```

Destructive maps to .tint(.red) (or role: .destructive in menus). Keep a 44pt minimum hit area.

## Props

| Name | Type | Default |
| --- | --- | --- |
| variant | default \| secondary \| outline \| ghost \| link \| destructive | default |
| size | default \| sm \| lg \| icon | default |

## Variants

HEEx:

```heex
<.button>Primary</.button>
<.button variant="secondary">Secondary</.button>
<.button variant="outline">Outline</.button>
<.button variant="ghost">Ghost</.button>
<.button variant="link">Link</.button>
<.button variant="destructive">Destructive</.button>
```

```html
<button class="btn btn-primary">Primary</button>
<button class="btn btn-secondary">Secondary</button>
<button class="btn btn-outline">Outline</button>
<button class="btn btn-ghost">Ghost</button>
<button class="btn btn-link">Link</button>
<button class="btn btn-error">Destructive</button>
```

## Sizes

```html
<button class="btn btn-primary btn-sm">Small</button>
<button class="btn btn-primary">Default</button>
<button class="btn btn-primary btn-lg">Large</button>
<button class="btn btn-primary btn-square" aria-label="icon">
  <span class="hero-plus size-4" aria-hidden="true"></span>
</button>
```

## States

```html
<button class="btn btn-primary" disabled>Disabled</button>
<button class="btn btn-outline">
  <span class="hero-arrow-down-tray size-4" aria-hidden="true"></span> With icon
</button>
<button class="btn btn-secondary">
  <span class="loading loading-spinner loading-xs"></span> Loading
</button>
```
