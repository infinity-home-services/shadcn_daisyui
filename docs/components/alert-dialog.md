# Alert Dialog

A modal that interrupts the user to confirm an action.

## Specs

| Part | Description |
| --- | --- |
| Trigger | An element that calls showModal() on the dialog. |
| Box | A `.modal-box` surface with title and muted description. |
| Actions | A `.modal-action` row: a cancel and a confirm (often btn-error) button. |

| Property | Value |
| --- | --- |
| Box surface | var(--popover) on var(--border-color), var(--radius-lg), shadow-sm |
| Title | text-lg font-semibold |
| Description | text-sm var(--muted-foreground) |
| Backdrop | modal-backdrop dims the page behind the dialog |

Tokens used: `popover`, `popover-foreground`, `border-color`, `muted-foreground`, `destructive`, `destructive-foreground`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab / Shift+Tab | Cycle focus between cancel and confirm within the trap |
| Enter / Space | Activate the focused action |
| Esc | Dismiss via the native dialog (treated as cancel) |

Role / ARIA: A native modal <dialog>; treat it as an alertdialog by keeping focus on the confirm/cancel choice.

Focus: Opening traps focus inside the dialog; closing returns focus to the trigger.

Screen reader: Announced as a dialog; the title and description give the consequence of the action.

Touch target: Action buttons are 2.25rem; size up to 2.75rem effective area on touch.

Reduced motion: Honor prefers-reduced-motion for the modal's enter/exit fade.

## Native (SwiftUI)

Parity: native parity with the web component.

```swift
.alert("Are you absolutely sure?", isPresented: $showAlert) {
  Button("Cancel", role: .cancel) {}
  Button("Delete account", role: .destructive) { delete() }
} message: {
  Text("This action cannot be undone.")
}
```

Maps directly to an .alert with a .destructive confirm and a .cancel button.

## Default

```html
<button class="btn btn-outline" onclick="alert_dialog_demo.showModal()">Delete account</button>
<dialog id="alert_dialog_demo" class="modal">
  <div class="modal-box space-y-2">
    <h3 class="text-lg font-semibold">Are you absolutely sure?</h3>
    <p class="text-sm text-muted-foreground">
      This action cannot be undone. This will permanently delete your account and remove your data from our servers.
    </p>
    <div class="modal-action">
      <form method="dialog" class="flex gap-3">
        <button class="btn btn-outline">Cancel</button>
        <button class="btn btn-error">Yes, delete account</button>
      </form>
    </div>
  </div>
  <form method="dialog" class="modal-backdrop"><button>close</button></form>
</dialog>
```
