# Dialog

A modal window overlaid on the page.

Open it from the browser when a button opens it (the :trigger slot or phx-click={show_modal(id)}, no round trip), and from the server when the server makes the decision (unsaved changes, a step that needs the server first): push_show_modal(socket, id) / push_hide_modal(socket, id) in an event handler, or show={@assign} with on_close (an event run when the person closes it, so the assign turns false again). Closing from the server doesn't run on_close.

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
<div class="w-64 rounded-lg border border-base-300 bg-popover p-5 text-left text-popover-foreground shadow-sm">
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
<div class="w-64 space-y-2 rounded-lg border border-base-300 bg-popover p-5 text-left text-popover-foreground shadow-sm">
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
<button class="btn btn-primary" commandfor="dialog_demo" command="show-modal">Open dialog</button>
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

## Open from the server

HEEx:

```heex
<%!-- a decision the server makes: unsaved changes ask first --%>
def handle_event("cancel", _params, socket) do
  if socket.assigns.dirty?,
    do: {:noreply, push_show_modal(socket, "discard")},
    else: {:noreply, push_navigate(socket, to: ~p"/orders")}
end

<.dialog id="discard">
  <:title>Discard your changes?</:title>
  <:description>Your edits to #1042 haven't been saved.</:description>
  <:actions>
    <.button variant="outline" phx-click={hide_modal("discard")}>Keep editing</.button>
    <.button variant="destructive" phx-click="discard">Discard</.button>
  </:actions>
</.dialog>

<%!-- or open while an assign is true; on_close turns it back off --%>
<.dialog id="delete-order" show={@confirm?} on_close="keep_editing">…</.dialog>

def handle_event("keep_editing", _params, socket), do: {:noreply, assign(socket, confirm?: false)}
```

```html
<button class="btn btn-outline" phx-click="[[&quot;dispatch&quot;,{&quot;to&quot;:&quot;#discard&quot;,&quot;event&quot;:&quot;shadcn:show-modal&quot;}]]">
  Cancel
</button>
<dialog id="discard" class="modal">
  <button type="button" hidden tabindex="-1" aria-hidden="true" data-on-close phx-click="keep_editing"></button>
  <div class="modal-box space-y-2">
    <h3 class="text-lg font-semibold">Discard your changes?</h3>
    <p class="text-sm text-muted-foreground">
      Your edits to #1042 haven't been saved.
    </p>
    <div class="modal-action">
      <div class="flex gap-3">
        <button class="btn btn-outline" phx-click="[[&quot;dispatch&quot;,{&quot;to&quot;:&quot;#discard&quot;,&quot;event&quot;:&quot;shadcn:hide-modal&quot;}]]">
          Keep editing
        </button>
        <button class="btn btn-error" phx-click="discard">
          Discard
        </button>
      </div>
    </div>
  </div>
  <form method="dialog" class="modal-backdrop"><button>close</button></form>
  <div id="discard-toasts" data-toast-host phx-update="ignore"></div>
</dialog>
```
