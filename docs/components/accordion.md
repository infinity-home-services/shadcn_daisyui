# Accordion

Vertically stacked, expandable sections.

## Specs

| Part | Description |
| --- | --- |
| Section | Each collapsible row (collapse collapse-arrow) inside a card. |
| Trigger | collapse-title row with a rotating chevron affordance. |
| Content | collapse-content panel revealed when open, in muted text. |

| Property | Value |
| --- | --- |
| Trigger padding | 1rem block, 2.5rem inline-end (room for the arrow) |
| Trigger font | 0.875rem / 500 |
| Divider | 1px var(--border-color) between sections |
| Content font | 0.875rem, var(--muted-foreground) |

Tokens used: `card`, `border-color`, `muted-foreground`, `foreground`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Move focus to a section trigger |
| Space / Enter | Expand or collapse the focused section |
| Arrow keys | Move between sections in single-open (radio) mode |

Role / ARIA: Built on radio (single-open) or checkbox (multiple) inputs that drive native CSS collapse. Requires an id to group the radios. Toggling is keyboard-operable through the underlying input.

Focus: The underlying input takes focus; the open section shows its content immediately.

Screen reader: Conveyed via the radio/checkbox state. For a full disclosure pattern add aria-expanded / aria-controls on a button-based trigger.

Touch target: Trigger rows are tall (1rem padding top and bottom) and easily exceed 44pt.

Reduced motion: The collapse open/close uses daisyUI height animation; honor prefers-reduced-motion to disable it.

## Native (SwiftUI)

Parity: native parity with the web component.

```swift
DisclosureGroup("Is it accessible?") {
    Text("Yes. It adheres to the WAI-ARIA pattern.")
}
```

DisclosureGroup is the native disclosure equivalent; stack several (or use a List with multiple groups) for accordion behavior.

## Default

HEEx:

```heex
<.accordion id="faq">
  <:section title="Is it accessible?" open>
    Yes. It adheres to the WAI-ARIA design pattern.
  </:section>
  <:section title="Is it styled?">
    Yes. It comes with shadcn-matched styles out of the box.
  </:section>
  <:section title="Is it animated?">
    Yes. It uses a smooth height transition.
  </:section>
</.accordion>
```

```html
<div class="card w-full">
  <div class="card-body py-1">
    <div class="collapse collapse-arrow">
      <input type="checkbox" checked />
      <div class="collapse-title">Is it accessible?</div>
      <div class="collapse-content">Yes. It adheres to the WAI-ARIA design pattern.</div>
    </div>
    <div class="collapse collapse-arrow">
      <input type="checkbox" />
      <div class="collapse-title">Is it styled?</div>
      <div class="collapse-content">Yes. It comes with shadcn-matched styles out of the box.</div>
    </div>
    <div class="collapse collapse-arrow">
      <input type="checkbox" />
      <div class="collapse-title">Is it animated?</div>
      <div class="collapse-content">Yes. It uses a smooth height transition.</div>
    </div>
  </div>
</div>
```
