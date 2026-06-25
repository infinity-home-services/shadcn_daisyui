# Input

A form input field for collecting text from the user.

## Usage guidance

Use when:

- Any free-text or typed value in a form - always via <.input field={...}>
- Email, password, number, date, and other native input types

Don't use for:

- Choosing from a known set - use select, radio-group, or combobox
- Raw <input> markup inside a <.form> (the field wiring is lost)

Sizing: Fixed h-9 with text-sm; full width of the form column (forms cap at max-w-md-lg). Labels above, 6-8px gap.

Responsive: Stack fields 16px apart (space-y-4) at every width; never two-column forms on compact.

iOS: TextField in a Form section; rely on system styling, set keyboard type and textContentType per field.

## Do / Don't

Do - Label every field:

```html
<label class="block w-full max-w-xs space-y-1.5">
  <span class="text-sm font-medium">Email</span>
  <input type="email" class="input w-full" placeholder="you@example.com" />
</label>
```

Don't - Placeholder as the only label:

```html
<input type="email" class="input w-full max-w-xs" placeholder="Email" />
```

## Specs

| Part | Description |
| --- | --- |
| Label | Field name above the control, 14px / font-medium, 6-8px gap. |
| Control | The text field - h-9 surface with a 1px border and rounded-md corners. |
| Placeholder | Muted hint text shown when empty (text-muted-foreground). |
| Error message | Rendered below, gated on used_input?, in text-destructive. |

| Property | Value |
| --- | --- |
| Height | 2.25rem / 36px (h-9) |
| Padding | 0.75rem inline (px-3) |
| Radius | var(--radius-md) |
| Border | 1px var(--input) |
| Font | 0.875rem / text-sm |
| Focus ring | 0 0 0 3px var(--ring) @ 50% |

Tokens used: `background`, `foreground`, `muted-foreground`, `input`, `ring`, `destructive`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Move focus between fields in source order |
| Type | Enter the value; native input behaviors apply |

Role / ARIA: Native <input>; always paired with a <label> via the FormField. aria-invalid + aria-describedby wire to the error when present.

Focus: Visible 3px focus ring (var(--ring)); the border shifts to the ring color on :focus-visible.

Screen reader: Label is announced with the field; errors are linked via aria-describedby so they are read on focus.

Touch target: 44pt row height on touch - wrap the label + control so the whole row is tappable.

Reduced motion: Color-only focus transition; nothing animates position.

## Native (SwiftUI)

Parity: native parity with the web component.

```swift
TextField("you@example.com", text: $email)
    .textContentType(.emailAddress)
    .keyboardType(.emailAddress)
    .textFieldStyle(.roundedBorder)
```

Put fields in a Form { Section { … } }; let the system own height, focus ring, and Dynamic Type.

## Default

HEEx:

```heex
<.input field={@form[:email]} type="email" label="Email" placeholder="you@example.com" />
```

```html
<label class="block w-full max-w-sm space-y-1.5">
  <span class="text-sm font-medium">Email</span>
  <input type="email" class="input w-full" placeholder="you@example.com" />
</label>
```
