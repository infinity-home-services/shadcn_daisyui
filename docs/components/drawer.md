# Drawer

A panel that slides up from the bottom of the screen.

## Usage guidance

Use when:

- Touch-first tasks and pickers on compact screens
- The compact-screen replacement for side sheets and many dialogs

Don't use for:

- Expanded screens - use sheet (side panel) or dialog there
- Long forms - navigate to a page

Sizing: Content gets safe-area bottom padding; primary action full-width at the bottom.

Responsive: Drawer on compact ↔ sheet/dialog on expanded - same content, different container.

iOS: This IS the iOS sheet with detents; use the system presentation, not a custom panel.

## Specs

| Part | Description |
| --- | --- |
| Trigger | A button that opens the drawer via showModal(). |
| Panel | A native <dialog> sliding up from the bottom (.drawer-bottom) with a grab handle. |
| Content | Centered, max-w-md body with a full-width primary action. |

| Property | Value |
| --- | --- |
| Grab handle | 1.5px tall x 12 wide, rounded-full bg-base-300 |
| Content width | max-w-md, centered |
| Surface | var(--popover) over the modal backdrop |

Tokens used: `popover`, `popover-foreground`, `color-base-300`, `muted-foreground`, `primary`, `primary-foreground`

## Accessibility

| Keys | Action |
| --- | --- |
| Esc | Close the drawer (native <dialog> dismiss) |
| Tab / Shift+Tab | Cycle focus within the trapped dialog |
| Enter / Space | Activate the focused control (e.g. the primary action) |

Role / ARIA: A native <dialog> opened with showModal(), so it is a modal dialog with built-in focus trapping and backdrop.

Focus: showModal traps focus inside the panel and restores it to the trigger on close; an outside click on the backdrop dismisses it.

Screen reader: Announced as a modal dialog; give the panel a heading and aria-label/labelledby so its purpose is read on open.

Touch target: Touch-first surface: the primary action is a full-width btn meeting the 44pt minimum; the grab handle hints at swipe-to-dismiss.

Reduced motion: The drawer slide is excluded from the instant-theme transition reset so it animates; gate the slide on prefers-reduced-motion for sensitive users.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
.sheet(isPresented: $showing) {
    DrawerContent()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
}
```

This IS the native iOS sheet with detents and a drag indicator - use the system presentation rather than a custom bottom panel.

## Default

HEEx:

```heex
<.drawer id="goal">
  <:trigger><.button variant="outline">Open drawer</.button></:trigger>
  <div class="mx-auto w-full max-w-md text-center">
    <h3 class="text-lg font-semibold">Move goal</h3>
    <p class="mt-1 text-sm text-muted-foreground">Set your daily activity goal.</p>
  </div>
</.drawer>
```

```html
<button class="btn btn-outline" onclick="document.getElementById('drawer_bottom').showModal()">
  Open drawer
</button>
<dialog id="drawer_bottom" class="drawer-bottom" onclick="if(event.target===this)this.close()">
  <div class="mx-auto mb-4 h-1.5 w-12 rounded-full bg-base-300"></div>
  <div class="mx-auto w-full max-w-md text-center">
    <h3 class="text-lg font-semibold">Move goal</h3>
    <p class="mt-1 text-sm text-muted-foreground">Set your daily activity goal.</p>
    <div class="my-6 flex items-center justify-center gap-6">
      <button class="btn btn-outline btn-circle">−</button>
      <span class="text-4xl font-bold tabular-nums">350</span>
      <button class="btn btn-outline btn-circle">+</button>
    </div>
    <button class="btn btn-primary w-full" onclick="this.closest('dialog').close()">Submit</button>
  </div>
</dialog>
```
