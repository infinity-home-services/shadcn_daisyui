# Accordion

Vertically stacked, expandable sections.

Two opt-ins turn it into a full section card: <:header> puts content above the rows in the same card (padded like a card body: a card_title, a card_description, maybe an action), and flush runs the rows edge to edge, each trigger and its content keeping the card's 24px inset, with a 1px line under the header and between rows (none under the last). Without either, it renders exactly as the default example.

## Specs

| Part | Description |
| --- | --- |
| Section | Each collapsible row (collapse collapse-arrow) inside a card. |
| Trigger | collapse-title row with a rotating chevron affordance. |
| Content | collapse-content panel revealed when open, in muted text. |
| Header (opt-in) | <:header> card-body above the rows: title, description, action. |

| Property | Value |
| --- | --- |
| Trigger padding | 1rem block, 2.5rem inline-end (room for the arrow) |
| Trigger font | 0.875rem / 500 |
| Divider | 1px var(--border-color) between sections |
| Content font | 0.875rem, var(--muted-foreground) |
| Flush rows (opt-in) | edge to edge; 1.5rem inline padding inside each row, 1px line under the header and between rows |

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

## Section card (header + flush rows)

HEEx:

```heex
<.accordion id="job-timeline" flush multiple>
  <:header>
    <div class="flex items-start justify-between gap-4">
      <div class="flex flex-col gap-1.5">
        <.card_title>Timeline</.card_title>
        <.card_description>Every step of this job so far.</.card_description>
      </div>
      <.badge variant="secondary">4 steps</.badge>
    </div>
  </:header>
  <:section title="Inquiry received" open>
    <dl class="grid grid-cols-1 gap-4 sm:grid-cols-2">
      <div>
        <dt class="text-xs">Source</dt>
        <dd class="text-foreground">Website form</dd>
      </div>
      <div>
        <dt class="text-xs">Received</dt>
        <dd class="text-foreground">Mon, Oct 5, 9:12 AM</dd>
      </div>
    </dl>
  </:section>
  <:section title="Site visit scheduled">
    <dl class="grid grid-cols-1 gap-4 sm:grid-cols-2">
      <div>
        <dt class="text-xs">Assigned to</dt>
        <dd class="text-foreground">Pat Rivera</dd>
      </div>
      <div>
        <dt class="text-xs">Visit</dt>
        <dd class="text-foreground">Wed, Oct 7, 2:00 PM</dd>
      </div>
    </dl>
  </:section>
  <:section title="Estimate sent">
    <dl class="grid grid-cols-1 gap-4 sm:grid-cols-2">
      <div>
        <dt class="text-xs">Amount</dt>
        <dd class="text-foreground">$12,480</dd>
      </div>
      <div>
        <dt class="text-xs">Sent</dt>
        <dd class="text-foreground">Thu, Oct 8, 4:30 PM</dd>
      </div>
    </dl>
  </:section>
  <:section title="Contract signed">
    <dl class="grid grid-cols-1 gap-4 sm:grid-cols-2">
      <div>
        <dt class="text-xs">Signed by</dt>
        <dd class="text-foreground">Jordan Lee</dd>
      </div>
      <div>
        <dt class="text-xs">Signed</dt>
        <dd class="text-foreground">Fri, Oct 9, 11:05 AM</dd>
      </div>
    </dl>
  </:section>
</.accordion>
```

```html
<div class="card w-full accordion-flush">
  <div class="card-body accordion-header">
    <div class="flex items-start justify-between gap-4">
      <div class="flex flex-col gap-1.5">
        <h3 class="card-title">Timeline</h3>
        <p class="text-sm text-muted-foreground">Every step of this job so far.</p>
      </div>
      <span class="badge badge-secondary">4 steps</span>
    </div>
  </div>
  <div class="accordion-rows">
    <div class="collapse collapse-arrow">
      <input type="checkbox" checked />
      <div class="collapse-title">Inquiry received</div>
      <div class="collapse-content">
        <dl class="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <div><dt class="text-xs">Source</dt><dd class="text-foreground">Website form</dd></div>
          <div><dt class="text-xs">Received</dt><dd class="text-foreground">Mon, Oct 5, 9:12 AM</dd></div>
        </dl>
      </div>
    </div>
    <div class="collapse collapse-arrow">
      <input type="checkbox" />
      <div class="collapse-title">Site visit scheduled</div>
      <div class="collapse-content">
        <dl class="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <div><dt class="text-xs">Assigned to</dt><dd class="text-foreground">Pat Rivera</dd></div>
          <div><dt class="text-xs">Visit</dt><dd class="text-foreground">Wed, Oct 7, 2:00 PM</dd></div>
        </dl>
      </div>
    </div>
    <div class="collapse collapse-arrow">
      <input type="checkbox" />
      <div class="collapse-title">Estimate sent</div>
      <div class="collapse-content">
        <dl class="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <div><dt class="text-xs">Amount</dt><dd class="text-foreground">$12,480</dd></div>
          <div><dt class="text-xs">Sent</dt><dd class="text-foreground">Thu, Oct 8, 4:30 PM</dd></div>
        </dl>
      </div>
    </div>
    <div class="collapse collapse-arrow">
      <input type="checkbox" />
      <div class="collapse-title">Contract signed</div>
      <div class="collapse-content">
        <dl class="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <div><dt class="text-xs">Signed by</dt><dd class="text-foreground">Jordan Lee</dd></div>
          <div><dt class="text-xs">Signed</dt><dd class="text-foreground">Fri, Oct 9, 11:05 AM</dd></div>
        </dl>
      </div>
    </div>
  </div>
</div>
```
