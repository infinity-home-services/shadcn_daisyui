# Validator

Form-validation visual states with a hint.

## Specs

| Part | Description |
| --- | --- |
| Validated input | An <input class="input validator"> styled by its HTML validity state. |
| Hint | validator-hint message shown when the input is invalid. |

| Property | Value |
| --- | --- |
| Valid state | Neutral/success styling when constraints pass |
| Invalid state | Destructive border/ring when validity fails |
| Hint | validator-hint message tied to the field |
| Constraints | Driven by native attributes (required, type, pattern) |

Tokens used: `input`, `ring`, `destructive`, `destructive-foreground`, `border-color`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Move focus to / from the field |
| Typing | Edit the value; validity updates live |

Role / ARIA: Native form input; validity styling supplements (does not replace) real error messaging.

Focus: Native input focus ring (var(--ring)); invalid state adds a destructive ring.

Screen reader: Wire the hint via aria-describedby and set aria-invalid so the error is announced - color alone is not enough.

Touch target: Input meets the standard field height; comfortable on touch.

Reduced motion: Color/ring transitions only; nothing moves.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
TextField("you@example.com", text: $email)
    .textFieldStyle(.roundedBorder)
    .foregroundStyle(isValid ? .primary : .red)
if !isValid { Text("Enter a valid email address").font(.caption).foregroundStyle(.red) }
```

No native validator; tint the field and show a caption error based on your own validation.

## Default

```html
<div class="w-full max-w-sm space-y-1.5">
  <input type="email" class="input validator w-full" required placeholder="you@example.com" />
  <p class="validator-hint">Enter a valid email address</p>
</div>
```
