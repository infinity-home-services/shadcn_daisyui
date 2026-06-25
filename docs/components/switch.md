# Switch

A control that toggles between on and off states.

## Specs

| Part | Description |
| --- | --- |
| Track | Pill background that turns primary when on (daisyUI toggle). |
| Knob | Sliding circular thumb drawn in the background color. |
| Label | Tappable label row wrapping the input. |

| Property | Value |
| --- | --- |
| Height | 1.15rem (--size; width derives) |
| Radius | 9999px (pill) |
| Off track | var(--input) |
| On track | var(--primary) |
| Knob | var(--background) |

Tokens used: `input`, `primary`, `primary-foreground`, `background`, `ring`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Move focus to / from the switch |
| Space | Toggle on / off |

Role / ARIA: Native checkbox input styled as a switch (the .toggle class). Bound to a boolean FormField with a hidden false input.

Focus: Ring shadow on focus-visible.

Screen reader: On/off state is announced via the checkbox semantics; the wrapping label supplies the name. For a literal switch role add role=switch.

Touch target: Wrap in the label row for a 44pt-friendly hit area on touch.

Reduced motion: Theme forces an instant switch; the knob does not animate its slide.

## Native (SwiftUI)

Parity: native parity with the web component.

```swift
Toggle("Email notifications", isOn: $notifications)
```

Toggle is the exact native equivalent and renders as a sliding switch on iOS.

## Default

HEEx:

```heex
<.switch field={@form[:airplane_mode]} label="Airplane mode" />
<.switch field={@form[:wifi]} label="Wi-Fi" />
```

```html
<div class="space-y-3">
  <label class="flex items-center gap-3 text-sm">
    <input type="checkbox" class="toggle" checked /> Airplane mode
  </label>
  <label class="flex items-center gap-3 text-sm">
    <input type="checkbox" class="toggle" /> Wi-Fi
  </label>
</div>
```
