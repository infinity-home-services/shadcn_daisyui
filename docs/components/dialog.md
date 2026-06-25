# Dialog

A modal window overlaid on the page.

## Usage guidance

Use when:

- A focused task that blocks the page until done (confirm, short form)
- Destructive confirmations that name the object

Don't use for:

- Long or multi-step flows - navigate to a page instead
- Content the user may want to keep visible alongside the page - use sheet

Sizing: The modal box is rounded-lg with shadow-sm and its own padding; forms inside follow the form rules (fields 16px apart).

Responsive: On compact screens prefer a bottom drawer for touch reach; dialogs that stay dialogs should be near-full-width.

iOS: .sheet for tasks (with detents), .alert only for short confirmations - never recreate web-style modals.

## Do / Don't

Do - Short, focused confirmation:

```html
<div class="w-64 rounded-lg border border-base-300 bg-base-100 p-5 text-left shadow-sm">
  <h3 class="text-base font-semibold">Delete file?</h3>
  <p class="py-2 text-sm text-muted-foreground">This can't be undone.</p>
  <div class="flex justify-end gap-2">
    <button class="btn btn-sm btn-outline">Cancel</button>
    <button class="btn btn-sm btn-error">Delete</button>
  </div>
</div>
```

Don't - A long form that belongs on a page:

```html
<div class="w-64 space-y-2 rounded-lg border border-base-300 bg-base-100 p-5 text-left shadow-sm">
  <h3 class="text-base font-semibold">New customer</h3>
  <input class="input input-sm w-full" placeholder="Name" />
  <input class="input input-sm w-full" placeholder="Address" />
  <input class="input input-sm w-full" placeholder="Phone" />
  <input class="input input-sm w-full" placeholder="Email" />
  <input class="input input-sm w-full" placeholder="Notes" />
</div>
```

## Specs

| Part | Description |
| --- | --- |
| Trigger | The control that opens the dialog (calls id.showModal()). |
| Backdrop | Dimmed overlay behind the box; clicking it closes via the dialog form. |
| Modal box | Centered surface - rounded-lg, shadow-sm, its own padding. |
| Title / Description | Heading and supporting text at the top of the box. |
| Actions | Trailing button row; cancel uses method="dialog". |

| Property | Value |
| --- | --- |
| Box radius | var(--radius-lg) |
| Elevation | shadow-sm (flat by design) |
| Max width | near-full-width on compact; the component caps it otherwise |
| Backdrop | dimmed scrim; enter/exit animation is preserved |

Tokens used: `popover`, `popover-foreground`, `background`, `border-color`, `muted-foreground`

## Accessibility

| Keys | Action |
| --- | --- |
| Esc | Close the dialog (native) |
| Tab / Shift+Tab | Cycle focus within the dialog only (focus is trapped) |
| Enter | Activate the focused action |

Role / ARIA: Native <dialog> opened with showModal() - the browser provides the modal role, focus trap, and inert background.

Focus: Focus moves into the dialog on open and returns to the trigger on close; the 3px ring applies to controls inside.

Screen reader: Announced as a modal dialog; give it an accessible name via the <:title> (aria-labelledby).

Touch target: Action buttons keep the 44pt touch minimum; on compact prefer a bottom drawer for reach.

Reduced motion: The open/close animation is exempt from the instant-theme rule; honor prefers-reduced-motion to skip it.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
.sheet(isPresented: $isPresented) {        // tasks / short forms
    ConfirmView()
        .presentationDetents([.medium, .large])
}
// short confirmations only:
.alert("Are you sure?", isPresented: $confirm) { … }
```

iOS has no web-style modal - use .sheet (with detents) for tasks and .alert for short confirmations.

## Default

HEEx:

```heex
<.dialog id="confirm">
  <:trigger><.button>Open dialog</.button></:trigger>
  <:title>Are you absolutely sure?</:title>
  <:description>
    This action cannot be undone. This will permanently delete your account.
  </:description>
  <:actions>
    <form method="dialog"><.button variant="outline">Cancel</.button></form>
    <.button variant="destructive" phx-click="delete">Delete</.button>
  </:actions>
</.dialog>
```

```html
<button class="btn btn-primary" onclick="dialog_demo.showModal()">Open dialog</button>
<dialog id="dialog_demo" class="modal">
  <div class="modal-box space-y-2">
    <h3 class="text-lg font-semibold">Are you absolutely sure?</h3>
    <p class="text-sm text-muted-foreground">
      This action cannot be undone. This will permanently delete your account.
    </p>
    <div class="modal-action">
      <form method="dialog" class="flex gap-3">
        <button class="btn btn-outline">Cancel</button>
        <button class="btn btn-error">Delete</button>
      </form>
    </div>
  </div>
  <form method="dialog" class="modal-backdrop"><button>close</button></form>
</dialog>
```
