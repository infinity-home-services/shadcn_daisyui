# Alert Dialog

A modal that interrupts to confirm an action: a question, its consequence, Cancel and the action.

Open it like any modal: the :trigger slot, phx-click={show_modal(id)}, or from the server with push_show_modal(socket, id) or show={@assign} + on_close. A backdrop click doesn't close it; Cancel, Esc and the action do (each runs on_close). Focus lands on Cancel and goes back to what opened it. The action runs whatever it carries - a phx-click, a form submit, a link - and closes the dialog; close={false} keeps it open until the server closes it (push_hide_modal/2). For data-confirm (dropdown and command items' confirm, links, buttons) call initConfirmDialog() once in app.js: the browser's confirm() becomes this dialog, and the click runs as before once confirmed.

## Usage guidance

Use when:

- Confirming an action that is hard to undo: delete, remove, discard changes
- A decision the server makes first ("discard your changes?") - open it from the server
- Every data-confirm in the app, once initConfirmDialog() is on

Don't use for:

- A form or a task in a modal - use <.dialog> (it closes on a backdrop click)
- Telling people something happened - use a toast
- Actions that are easy to undo - do it, and offer Undo in a toast

Sizing: shadcn's AlertDialog: up to 32rem (max-w-lg; size="sm" 20rem), 24px padding, 16px between header and footer, the rounded-xl popover surface with a 1px ring and shadow-lg. Title text-lg semibold, description text-sm muted 6px under it. Buttons h-9, 8px apart: Cancel outline, the action primary or destructive.

Responsive: Phones: the full width less 2rem, the header centred, the action above Cancel, both full width. From 640px the text aligns left and the buttons sit in a row on the right. size="sm" stays centred, its two buttons side by side.

iOS: .alert with a .cancel and a .destructive button (or .confirmationDialog when there are several choices).

## Specs

| Part | Description |
| --- | --- |
| Trigger | Optional; opens the dialog (show_modal). |
| Box | The .modal-box popover surface: a grid of the header and the footer, 16px apart. |
| Header | Optional media, the title (the question) and a muted description (the consequence). |
| Footer | Cancel (outline, focused on open) and the action (primary or destructive). |

| Property | Value |
| --- | --- |
| Box | max 32rem (sm 20rem), 100% - 2rem on phones, 1.5rem padding, var(--radius-xl), var(--popover) |
| Title | 1.125rem / 28px, weight 600 |
| Description | 0.875rem, var(--muted-foreground), 6px below |
| Media | 4rem square, var(--muted), var(--radius-md) |
| Buttons | 2.25rem tall, 0.5rem apart |
| Backdrop | oklch(0 0 0 / 0.5), doesn't close it |

Tokens used: `popover`, `popover-foreground`, `muted`, `muted-foreground`, `primary`, `primary-foreground`, `destructive`, `ring`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab / Shift+Tab | Move between Cancel and the action |
| Enter / Space | Activate the focused button |
| Esc | Cancel: close it without the action |

Role / ARIA: A native modal <dialog role="alertdialog">: aria-labelledby the title, aria-describedby the description. Everything behind it is inert.

Focus: Focus lands on Cancel, the safe choice, when it opens, and goes back to what opened it when it closes.

Screen reader: Announced as an alert dialog with its title and description, so the question and the consequence are read before the buttons.

Touch target: The buttons are full width on phones (2.25rem tall); keep the action's label short so it stays one line.

Reduced motion: Fades in and out without the zoom under prefers-reduced-motion.

## Native (SwiftUI)

Parity: native parity with the web component.

```swift
.alert("Delete Q3 report?", isPresented: $confirmDelete) {
    Button("Cancel", role: .cancel) {}
    Button("Delete report", role: .destructive) { delete() }
} message: {
    Text("The report and its comments are deleted for everyone.")
}
```

Maps directly to an .alert: the title, a message, a .cancel button and a .destructive action.

## Props

| Name | Type | Default |
| --- | --- | --- |
| id | string (required) | - |
| size | default \| sm | default |
| cancel | string (Cancel's label) | "Cancel" |
| show | boolean (open while true) | false |
| on_close | event name or JS (Cancel, Esc, the action) | nil |
| class | any | nil |
| :trigger | slot (opens it) | - |
| :media | slot (64px square above the title) | - |
| :title | slot (required; names the dialog) | - |
| :description | slot (describes the dialog) | - |
| inner_block | slot (between the header and the buttons) | - |
| :action | slot (required): variant default \| destructive, close={false}, and any button or <.link> attribute (phx-click, type + form, navigate, href + method) | - |

## Default

HEEx:

```heex
<.alert_dialog id="alert-default">
  <:trigger><.button variant="outline">Show dialog</.button></:trigger>
  <:title>Are you absolutely sure?</:title>
  <:description>
    This permanently deletes your account and removes your data from our servers.
  </:description>
  <:action phx-click="delete_account">Continue</:action>
</.alert_dialog>
```

```html
<span phx-click="[[&quot;dispatch&quot;,{&quot;to&quot;:&quot;#alert-default&quot;,&quot;event&quot;:&quot;shadcn:show-modal&quot;}]]">
  <button class="btn btn-outline">
    Show dialog
  </button>
</span>
<dialog id="alert-default" class="modal alert-dialog" role="alertdialog" aria-labelledby="alert-default-title" aria-describedby="alert-default-description">
  <div class="modal-box">
    <div class="alert-dialog-header">
      <h2 id="alert-default-title" class="alert-dialog-title">Are you absolutely sure?</h2>
      <p id="alert-default-description" class="alert-dialog-description">
        This permanently deletes your account and removes your data from our servers.
      </p>
    </div>
    <div class="alert-dialog-footer">
      <button type="button" class="btn btn-outline" data-alert-dialog-cancel autofocus>
        Cancel
      </button>
      <button class="btn btn-primary" data-alert-dialog-action type="button" phx-click="delete_account">
        Continue
      </button>
    </div>
  </div>
  <div id="alert-default-toasts" data-toast-host phx-update="ignore"></div>
</dialog>
```

## Destructive

HEEx:

```heex
<.alert_dialog id="alert-delete">
  <:trigger><.button variant="destructive">Delete report</.button></:trigger>
  <:title>Delete Q3 report?</:title>
  <:description>The report and its comments are deleted for everyone.</:description>
  <:action variant="destructive" phx-click="delete" phx-value-id={@report.id}>
    Delete report
  </:action>
</.alert_dialog>
```

```html
<span phx-click="[[&quot;dispatch&quot;,{&quot;to&quot;:&quot;#alert-delete&quot;,&quot;event&quot;:&quot;shadcn:show-modal&quot;}]]">
  <button class="btn btn-error">
    Delete report
  </button>
</span>
<dialog id="alert-delete" class="modal alert-dialog" role="alertdialog" aria-labelledby="alert-delete-title" aria-describedby="alert-delete-description">
  <div class="modal-box">
    <div class="alert-dialog-header">
      <h2 id="alert-delete-title" class="alert-dialog-title">Delete Q3 report?</h2>
      <p id="alert-delete-description" class="alert-dialog-description">
        The report and its comments are deleted for everyone.
      </p>
    </div>
    <div class="alert-dialog-footer">
      <button type="button" class="btn btn-outline" data-alert-dialog-cancel autofocus>
        Cancel
      </button>
      <button class="btn btn-error" data-alert-dialog-action type="button" phx-click="delete" phx-value-id="q3">
        Delete report
      </button>
    </div>
  </div>
  <div id="alert-delete-toasts" data-toast-host phx-update="ignore"></div>
</dialog>
```

## Small, with media

HEEx:

```heex
<.alert_dialog id="alert-share" size="sm">
  <:trigger><.button variant="outline">Share report</.button></:trigger>
  <:media><.icon name="hero-share" class="size-8" /></:media>
  <:title>Share with Acme Marketing?</:title>
  <:description>They can view and comment until you stop sharing.</:description>
  <:action phx-click="share">Share</:action>
</.alert_dialog>
```

```html
<span phx-click="[[&quot;dispatch&quot;,{&quot;to&quot;:&quot;#alert-share&quot;,&quot;event&quot;:&quot;shadcn:show-modal&quot;}]]">
  <button class="btn btn-outline">
    Share report
  </button>
</span>
<dialog id="alert-share" class="modal alert-dialog alert-dialog-sm" role="alertdialog" aria-labelledby="alert-share-title" aria-describedby="alert-share-description">
  <div class="modal-box">
    <div class="alert-dialog-header">
      <div class="alert-dialog-media"><span class="hero-share size-8" aria-hidden="true"></span></div>
      <h2 id="alert-share-title" class="alert-dialog-title">Share with Acme Marketing?</h2>
      <p id="alert-share-description" class="alert-dialog-description">
        They can view and comment until you stop sharing.
      </p>
    </div>
    <div class="alert-dialog-footer">
      <button type="button" class="btn btn-outline" data-alert-dialog-cancel autofocus>
        Cancel
      </button>
      <button class="btn btn-primary" data-alert-dialog-action type="button" phx-click="share">
        Share
      </button>
    </div>
  </div>
  <div id="alert-share-toasts" data-toast-host phx-update="ignore"></div>
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

<.alert_dialog id="discard" cancel="Keep editing">
  <:title>Discard your changes?</:title>
  <:description>Your edits to #1042 haven't been saved.</:description>
  <:action variant="destructive" navigate={~p"/orders"}>Discard changes</:action>
</.alert_dialog>

<%!-- or open while an assign is true; on_close turns it back off --%>
<.alert_dialog id="delete-order" show={@confirm?} on_close="keep_order">…</.alert_dialog>

def handle_event("keep_order", _params, socket), do: {:noreply, assign(socket, confirm?: false)}
```

```html
<button class="btn btn-outline" phx-click="[[&quot;dispatch&quot;,{&quot;to&quot;:&quot;#alert-discard&quot;,&quot;event&quot;:&quot;shadcn:show-modal&quot;}]]">
  Cancel
</button>
<dialog id="alert-discard" class="modal alert-dialog" role="alertdialog" aria-labelledby="alert-discard-title" aria-describedby="alert-discard-description">
  <button type="button" hidden tabindex="-1" aria-hidden="true" data-on-close phx-click="keep_editing"></button>
  <div class="modal-box">
    <div class="alert-dialog-header">
      <h2 id="alert-discard-title" class="alert-dialog-title">Discard your changes?</h2>
      <p id="alert-discard-description" class="alert-dialog-description">
        Your edits to #1042 haven't been saved.
      </p>
    </div>
    <div class="alert-dialog-footer">
      <button type="button" class="btn btn-outline" data-alert-dialog-cancel autofocus>
        Keep editing
      </button>
      <button class="btn btn-error" data-alert-dialog-action type="button" phx-click="discard">
        Discard changes
      </button>
    </div>
  </div>
  <div id="alert-discard-toasts" data-toast-host phx-update="ignore"></div>
</dialog>
```

## Styled data-confirm

HEEx:

```heex
// assets/js/app.js, once: data-confirm asks in this dialog, not the browser's confirm()
import { Hooks, initConfirmDialog } from "shadcn_daisyui"
initConfirmDialog()

<.button
  variant="destructive"
  phx-click="delete"
  data-confirm="Delete Q3 report?"
  data-confirm-description="The report and its comments are deleted for everyone."
  data-confirm-action="Delete report"
>
  Delete report
</.button>

<%!-- a destructive item gets a destructive action --%>
<.dropdown_menu align="end" close_on_select>
  <:trigger>Member actions</:trigger>
  <:item phx-click="edit" phx-value-id={@member.id}>Edit</:item>
  <:item
    phx-click="remove"
    phx-value-id={@member.id}
    variant="destructive"
    confirm={"Remove #{@team.name} from #{@member.name}?"}
  >
    Remove
  </:item>
</.dropdown_menu>
```

```html
<button class="btn btn-error" data-confirm="Delete Q3 report?" data-toast="Q3 report deleted" data-confirm-action="Delete report" data-confirm-description="The report and its comments are deleted for everyone.">
  Delete report
</button>
<div class="dropdown dropdown-end" data-close-on-select>
  <div tabindex="0" role="button" class="btn btn-outline">
    Member actions
    <span class="hero-chevron-down size-4" aria-hidden="true"></span>
  </div>
  <ul tabindex="0" class="dropdown-content menu z-50 mt-2 w-48">
    <li>
      <a phx-click="edit">
        Edit
      </a>
    </li>
    <li>
      <a class="text-destructive" phx-click="remove" data-variant="destructive" data-confirm="Remove Acme Marketing from Pat Lee?">
        Remove
      </a>
    </li>
  </ul>
</div>
```
