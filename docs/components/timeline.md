# Timeline

A vertical or horizontal sequence of events.

## Specs

| Part | Description |
| --- | --- |
| Timeline list | <ul class=timeline> of vertically stacked events. |
| Middle marker | Centered icon node (check/clock) on the spine. |
| Box | timeline-box card holding the event label. |
| Connector | <hr> spine segments tinted with border-color. |

| Property | Value |
| --- | --- |
| Box radius | var(--radius-md) |
| Box border | 1px border-color |
| Box shadow | var(--shadow-xs) |
| Box font | 0.875rem |
| Spine | <hr> tinted border-color |

Tokens used: `card`, `border-color`, `primary`, `muted-foreground`

## Accessibility

Role / ARIA: Presentational <ul>/<li>; marker icons are aria-hidden decoration.

Focus: Not focusable; no interactive elements.

Screen reader: Event labels read in order as a list; icons are hidden from the accessibility tree.

Touch target: Not interactive; no hit-target requirement.

Reduced motion: Static; no animation to suppress.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
List(events) { event in
    Label(event.title, systemImage: event.done ? "checkmark.circle" : "clock")
}
.listStyle(.plain)
```

A plain List with leading status icons approximates the vertical spine.

## Default

```html
<ul class="timeline">
  <li>
    <div class="timeline-middle"><span class="hero-check-circle size-4 text-primary" aria-hidden="true"></span></div>
    <div class="timeline-end timeline-box">Project kickoff</div>
    <hr />
  </li>
  <li>
    <hr />
    <div class="timeline-middle"><span class="hero-check-circle size-4 text-primary" aria-hidden="true"></span></div>
    <div class="timeline-end timeline-box">Design complete</div>
    <hr />
  </li>
  <li>
    <hr />
    <div class="timeline-middle"><span class="hero-clock size-4 text-muted-foreground" aria-hidden="true"></span></div>
    <div class="timeline-end timeline-box">Launch</div>
  </li>
</ul>
```
