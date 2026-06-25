# Popover

Rich floating content triggered by a button.

## Specs

| Part | Description |
| --- | --- |
| Trigger | role=button element (outline button by default) opened on click. |
| Panel | dropdown-content floating surface holding rich content. |

| Property | Value |
| --- | --- |
| Default width | w-72 |
| Panel radius | var(--radius-md) |
| Panel padding | 1rem (p-4) |
| Border | 1px var(--border-color) |
| Shadow | var(--shadow-sm) |

Tokens used: `popover`, `popover-foreground`, `border-color`, `foreground`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab / Enter / Space | Open the popover and move focus into it |
| Tab | Cycle through focusable content inside the panel |
| Esc | Close the popover and return focus to the trigger |

Role / ARIA: CSS-only daisyUI dropdown: a role=button trigger and a focusable content panel. Add aria-haspopup / aria-expanded and aria-controls for a complete popover pattern.

Focus: Opens via focus and closes when focus leaves the group. Keep an explicit focus target inside for keyboard users.

Screen reader: Give the trigger an accessible name and wire aria-expanded so the open/closed state is announced.

Touch target: Trigger follows button sizing (44pt on touch); panel content controls keep their own hit areas.

Reduced motion: Panel shows/hides without a color fade under the theme.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
Button("Open popover") { showPopover = true }
    .popover(isPresented: $showPopover) {
        VStack { /* rich content */ }.padding()
    }
```

.popover(isPresented:) is the native equivalent on iPad/macOS; on iPhone it falls back to a sheet, so presentation differs by size class.

## Default

HEEx:

```heex
<.popover>
  <:trigger>Open popover</:trigger>
  <div class="space-y-1">
    <h4 class="text-sm font-medium leading-none">Dimensions</h4>
    <p class="text-sm text-muted-foreground">Set the dimensions for the layer.</p>
  </div>
</.popover>
```

```html
<div class="dropdown">
  <div tabindex="0" role="button" class="btn btn-outline">Open popover</div>
  <div tabindex="0" class="dropdown-content z-10 mt-2 w-72 p-4">
    <div class="space-y-3">
      <div class="space-y-1">
        <h4 class="text-sm font-medium leading-none">Dimensions</h4>
        <p class="text-sm text-muted-foreground">Set the dimensions for the layer.</p>
      </div>
      <div class="grid grid-cols-3 items-center gap-3 text-sm">
        <label for="pop-w">Width</label>
        <input id="pop-w" class="input col-span-2 h-8" value="100%" />
        <label for="pop-h">Height</label>
        <input id="pop-h" class="input col-span-2 h-8" value="25px" />
      </div>
    </div>
  </div>
</div>
```
