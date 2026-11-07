# Input OTP

A segmented input for one-time passcodes.

> Requires a JS hook: initialize with `initShadcnDaisyui()` (dead views) or the corresponding `Shadcn*` LiveView hook from `shadcn-daisyui.js`.

## Specs

| Part | Description |
| --- | --- |
| Group | A role=group wrapper (aria-label One-time code) holding the digit slots. |
| Slots | Single-character inputs (.otp-slot) each labelled Digit N of M; non-digits are stripped. |
| Separator (optional) | A visual divider between slot groups. |

| Property | Value |
| --- | --- |
| Slot radius | var(--radius-md) |
| Slot focus | var(--ring) focus ring |
| Input filter | one digit per slot, auto-advance |

Tokens used: `background`, `foreground`, `input`, `border-color`, `ring`, `muted-foreground`

## Accessibility

| Keys | Action |
| --- | --- |
| Type a digit | Fills the slot and auto-advances focus to the next |
| Backspace | On an empty slot, moves focus back to the previous slot |
| Paste | Distributes the pasted digits across all slots and focuses the first empty one |
| Tab | Move between slots manually |

Role / ARIA: The wrapper is role=group with aria-label One-time code; each slot is a text input labelled with its position (Digit N of M).

Focus: Focus auto-advances on entry and steps back on backspace; pasting jumps focus to the first unfilled slot.

Screen reader: Each slot announces its index out of the total, so the user knows which digit they are entering.

Touch target: Slots are sized boxes; ensure each is at least 44pt on touch and that the numeric keyboard appears (inputmode=numeric).

Reduced motion: Focus moves between slots without any animation.

## Native (SwiftUI)

Parity: guidance only - no native component yet.

```swift
HStack(spacing: 8) {
    ForEach(0..<6, id: \.self) { i in
        TextField("", text: $digits[i])
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .frame(width: 44, height: 44)
            .multilineTextAlignment(.center)
    }
}
```

No native OTP control exists; build it from per-digit TextFields. .textContentType(.oneTimeCode) enables system autofill from SMS.

## Default

HEEx:

```heex
<.input_otp id="otp" />
<.input_otp id="pin" length={4} group={0} />
```

```html
<div data-otp class="flex items-center gap-2">
  <input class="otp-slot" maxlength="1" inputmode="numeric" autocomplete="one-time-code" />
  <input class="otp-slot" maxlength="1" inputmode="numeric" />
  <input class="otp-slot" maxlength="1" inputmode="numeric" />
  <span class="text-muted-foreground">-</span>
  <input class="otp-slot" maxlength="1" inputmode="numeric" />
  <input class="otp-slot" maxlength="1" inputmode="numeric" />
  <input class="otp-slot" maxlength="1" inputmode="numeric" />
</div>
```
