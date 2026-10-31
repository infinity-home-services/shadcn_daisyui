# Field

A grouped set of related form controls.

## Usage guidance

Use when:

- A control needs a description line under its label
- Composing custom controls with correct label/aria wiring

Don't use for:

- Plain labeled inputs - <.input field={...}> already wires everything
- Visual grouping without form semantics - use a card or fieldset

Sizing: Label, control, description, errors stack with 6-8px gaps; field blocks 16px apart.

Responsive: Same stacked layout at every width.

iOS: Form Section with footer text as the description; errors below the row in sdDestructive.

## Specs

| Part | Description |
| --- | --- |
| Label | The control's label, wired to it via the form field. |
| Control | The wrapped input/select/checkbox group. |
| Description | Optional muted helper text under the control. |
| Error | Field errors rendered below, gated on used_input?. |

| Property | Value |
| --- | --- |
| Internal stacking | label, control, description stack with ~6-8px (space-y-1.5) gaps |
| Field spacing | field blocks 16px apart |
| Description text | text-xs var(--muted-foreground) |
| Fieldset border | 1px var(--border-color), var(--radius-lg) when grouped as a fieldset |

Tokens used: `foreground`, `muted-foreground`, `border-color`, `input`, `destructive`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Move focus to the control(s) |
| Space / Enter | Operate the focused control |

Role / ARIA: A label/control/description grouping; a multi-control variant uses fieldset/legend.

Focus: The control shows its own ring-shadow focus styling; the label is click-associated.

Screen reader: The label, description, and errors are associated with the control so they are read together.

Touch target: Wrap checkbox/radio rows in a tappable label so the whole row reaches 2.75rem.

Reduced motion: Static layout; no motion.

## Native (SwiftUI)

Parity: native parity with the web component.

```swift
Section {
  TextField("Email", text: $email)
} footer: {
  Text("We never share it.")
}
```

Maps to a Form Section with footer description text; validation errors render below the row in a destructive style.

## Default

HEEx:

```heex
<.field field={@form[:email]} label="Email" description="We never share it.">
  <.input field={@form[:email]} type="email" />
</.field>
```

```html
<fieldset class="w-full max-w-sm space-y-1.5 rounded-lg border border-base-300 p-4">
  <legend class="px-1 text-sm font-medium">Notifications</legend>
  <label class="flex items-center gap-2 text-sm">
    <input type="checkbox" class="checkbox" checked /> Email
  </label>
  <label class="flex items-center gap-2 text-sm">
    <input type="checkbox" class="checkbox" /> SMS
  </label>
  <p class="text-xs text-muted-foreground">Choose how you want to be notified.</p>
</fieldset>
```
