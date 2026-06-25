# Sheet

A panel that slides in from the edge of the screen.

## Usage guidance

Use when:

- Detail/edit panels that keep the page visible behind (record preview, filters)
- Secondary settings reachable from a list

Don't use for:

- Blocking confirmations - use dialog
- Primary navigation on compact - that's the dock's job

Sizing: Right side panel on expanded; content follows form/card rules inside.

Responsive: On compact, side sheets become bottom drawers (more thumb-reachable).

iOS: .sheet with .medium/.large detents; swipe-down to dismiss, confirm if input would be lost.

## Specs

| Part | Description |
| --- | --- |
| Trigger | An element that calls showModal() on the dialog. |
| Panel | A native `<dialog class="sheet">` pinned to the inline-end edge. |
| Header | Title (text-lg semibold), description (muted), and a top-right close button. |

| Property | Value |
| --- | --- |
| Width | 20rem, capped at max-width 90vw |
| Height | 100dvh, anchored to the inline-end edge |
| Padding | 1.5rem; leading border-inline-start 1px var(--border-color) |
| Surface | var(--popover) on var(--popover-foreground), shadow-sm |
| Enter/exit | translate 0.3s ease slide-in plus a 50% black backdrop |

Tokens used: `popover`, `popover-foreground`, `border-color`, `foreground`, `muted-foreground`

## Accessibility

| Keys | Action |
| --- | --- |
| Esc | Close the sheet (native dialog behavior) |
| Tab / Shift+Tab | Cycle focus within the trapped dialog |
| Enter / Space | Activate the focused control |

Role / ARIA: A native modal <dialog>; the browser provides the dialog role, focus trap, and inert background.

Focus: Opening moves focus into the dialog and traps it; closing returns focus to the trigger.

Screen reader: Announced as a dialog; give it an accessible name via the title for context.

Touch target: The close button is btn-sm square; pad to 2.75rem effective area on touch.

Reduced motion: The 0.3s slide is exempt from the instant-theme rule; honor prefers-reduced-motion to drop it.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
.sheet(isPresented: $isEditing) {
  EditProfileView()
    .presentationDetents([.medium, .large])
}
```

An edge sheet maps to a .sheet with detents; iOS sheets rise from the bottom rather than the side, and swipe-down dismisses.

## Default

HEEx:

```heex
<.sheet id="edit-profile">
  <:trigger><.button variant="outline">Open sheet →</.button></:trigger>
  <:title>Edit profile</:title>
  <:description>Make changes to your profile here. Click save when you're done.</:description>
  <.input field={@form[:name]} label="Name" />
  <.input field={@form[:username]} label="Username" />
</.sheet>
```

```html
<button class="btn btn-outline" onclick="document.getElementById('sheet_dialog').showModal()">
  Open sheet →
</button>
<dialog id="sheet_dialog" class="sheet" onclick="if(event.target===this)this.close()">
  <button
    class="btn btn-ghost btn-square btn-sm absolute right-3 top-3"
    aria-label="Close"
    onclick="this.closest('dialog').close()"
  >
    <span class="hero-x-mark size-4" aria-hidden="true"></span>
  </button>
  <h3 class="text-lg font-semibold">Edit profile</h3>
  <p class="mt-1 text-sm text-muted-foreground">
    Make changes to your profile here. Click save when you're done.
  </p>
  <div class="mt-5 space-y-4">
    <label class="block space-y-1.5">
      <span class="text-sm font-medium">Name</span>
      <input class="input w-full" value="Jane Doe" />
    </label>
    <label class="block space-y-1.5">
      <span class="text-sm font-medium">Username</span>
      <input class="input w-full" value="@jane" />
    </label>
  </div>
  <div class="mt-6 flex justify-end gap-3">
    <button class="btn btn-outline" onclick="this.closest('dialog').close()">Cancel</button>
    <button class="btn btn-primary" onclick="this.closest('dialog').close()">Save changes</button>
  </div>
</dialog>
```
