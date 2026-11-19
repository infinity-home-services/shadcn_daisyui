# Sheet

A panel that slides in from the edge of the screen.

## Usage guidance

Use when:

- Detail/edit panels that keep the page visible behind (record preview, filters)
- Secondary settings reachable from a list

Don't use for:

- Blocking confirmations - use dialog
- Primary navigation on compact - that's the dock's job

Sizing: 75% wide on phones; from sm, size sets the width (sm 20rem, default 24rem, lg 32rem, xl 40rem), capped at 90vw. A width class overrides it. Header and :footer stay put; only the body scrolls.

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
| Width | 75% on phones; from sm, --sheet-width (sm 20rem, default 24rem, lg 32rem, xl 40rem); max-width 90vw |
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
  <:footer>
    <.button variant="outline" phx-click={hide_modal("edit-profile")}>Cancel</.button>
    <.button class="ml-auto" phx-click="save">Save changes</.button>
  </:footer>
</.sheet>
```

```html
<button class="btn btn-outline" commandfor="sheet_dialog" command="show-modal">
  Open sheet →
</button>
<dialog id="sheet_dialog" class="sheet">
  <div class="sheet-header">
    <button
      class="btn btn-ghost btn-square btn-sm absolute right-3 top-3"
      aria-label="Close"
      commandfor="sheet_dialog"
      command="close"
    >
      <span class="hero-x-mark size-4" aria-hidden="true"></span>
    </button>
    <h3 class="sheet-title text-lg font-semibold">Edit profile</h3>
    <p class="text-sm text-muted-foreground">
      Make changes to your profile here. Click save when you're done.
    </p>
  </div>
  <div class="sheet-body">
    <div class="space-y-4">
      <label class="block space-y-1.5">
        <span class="text-sm font-medium">Name</span>
        <input class="input w-full" value="Jane Doe" />
      </label>
      <label class="block space-y-1.5">
        <span class="text-sm font-medium">Username</span>
        <input class="input w-full" value="@jane" />
      </label>
    </div>
  </div>
  <div class="sheet-footer">
    <button class="btn btn-outline" commandfor="sheet_dialog" command="close">Cancel</button>
    <button class="btn btn-primary ml-auto" commandfor="sheet_dialog" command="close">Save changes</button>
  </div>
</dialog>
```

## Filters (pinned header and footer)

HEEx:

```heex
<%!-- only the body scrolls; a line shows under the header / above the
     footer while content is scrolled under it --%>
<.sheet id="issue-filters">
  <:trigger><.button variant="outline">Filters</.button></:trigger>
  <:title>Filters</:title>
  <:description>Narrow the issue list.</:description>
  <:header>
    <.input type="search" name="q" value={@q} placeholder="Search filters…" />
  </:header>
  <.form for={@filters} id="issue-filter-form" phx-change="filter" class="space-y-6">
    <fieldset class="space-y-3">
      <legend class="mb-3 text-sm font-medium">Status</legend>
      <.input field={@filters[:backlog]} type="checkbox" label="Backlog" />
      <.input field={@filters[:todo]} type="checkbox" label="Todo" />
      …
    </fieldset>
    …more groups…
  </.form>
  <:footer>
    <.button variant="ghost" phx-click="clear_filters">Clear all</.button>
    <%!-- takes the remaining width on phones --%>
    <.button class="ml-auto grow sm:grow-0" phx-click={hide_modal("issue-filters")}>
      Show {@count} results
    </.button>
  </:footer>
</.sheet>
```

```html
<button class="btn btn-outline" commandfor="sheet_filters" command="show-modal">Filters</button>
<dialog id="sheet_filters" class="sheet">
  <div class="sheet-header">
    <button
      class="btn btn-ghost btn-square btn-sm absolute right-3 top-3"
      aria-label="Close"
      commandfor="sheet_filters"
      command="close"
    >
      <span class="hero-x-mark size-4" aria-hidden="true"></span>
    </button>
    <h3 class="sheet-title text-lg font-semibold">Filters</h3>
    <p class="text-sm text-muted-foreground">Narrow the issue list.</p>
    <div class="sheet-header-content">
      <input type="search" class="input w-full" placeholder="Search filters…" aria-label="Search filters" />
    </div>
  </div>
  <div class="sheet-body">
    <form id="sheet_filters_form" class="space-y-6">
      <fieldset class="space-y-3">
        <legend class="mb-3 text-sm font-medium">Status</legend>
        <label class="flex items-center gap-2 text-sm">
          <input type="checkbox" class="checkbox" name="status[]" value="Backlog" /> Backlog
        </label>
        <label class="flex items-center gap-2 text-sm">
          <input type="checkbox" class="checkbox" name="status[]" value="Todo" /> Todo
        </label>
        <label class="flex items-center gap-2 text-sm">
          <input type="checkbox" class="checkbox" name="status[]" value="In progress" /> In progress
        </label>
        <label class="flex items-center gap-2 text-sm">
          <input type="checkbox" class="checkbox" name="status[]" value="In review" /> In review
        </label>
        <label class="flex items-center gap-2 text-sm">
          <input type="checkbox" class="checkbox" name="status[]" value="Done" /> Done
        </label>
        <label class="flex items-center gap-2 text-sm">
          <input type="checkbox" class="checkbox" name="status[]" value="Canceled" /> Canceled
        </label>
      </fieldset>
      <fieldset class="space-y-3">
        <legend class="mb-3 text-sm font-medium">Priority</legend>
        <label class="flex items-center gap-2 text-sm">
          <input type="checkbox" class="checkbox" name="priority[]" value="Urgent" /> Urgent
        </label>
        <label class="flex items-center gap-2 text-sm">
          <input type="checkbox" class="checkbox" name="priority[]" value="High" /> High
        </label>
        <label class="flex items-center gap-2 text-sm">
          <input type="checkbox" class="checkbox" name="priority[]" value="Medium" /> Medium
        </label>
        <label class="flex items-center gap-2 text-sm">
          <input type="checkbox" class="checkbox" name="priority[]" value="Low" /> Low
        </label>
        <label class="flex items-center gap-2 text-sm">
          <input type="checkbox" class="checkbox" name="priority[]" value="No priority" /> No priority
        </label>
      </fieldset>
      <fieldset class="space-y-3">
        <legend class="mb-3 text-sm font-medium">Assignee</legend>
        <label class="flex items-center gap-2 text-sm">
          <input type="checkbox" class="checkbox" name="assignee[]" value="Olivia Martin" /> Olivia Martin
        </label>
        <label class="flex items-center gap-2 text-sm">
          <input type="checkbox" class="checkbox" name="assignee[]" value="Jackson Lee" /> Jackson Lee
        </label>
        <label class="flex items-center gap-2 text-sm">
          <input type="checkbox" class="checkbox" name="assignee[]" value="Isabella Nguyen" /> Isabella Nguyen
        </label>
        <label class="flex items-center gap-2 text-sm">
          <input type="checkbox" class="checkbox" name="assignee[]" value="William Kim" /> William Kim
        </label>
        <label class="flex items-center gap-2 text-sm">
          <input type="checkbox" class="checkbox" name="assignee[]" value="Sofia Davis" /> Sofia Davis
        </label>
        <label class="flex items-center gap-2 text-sm">
          <input type="checkbox" class="checkbox" name="assignee[]" value="Liam Johnson" /> Liam Johnson
        </label>
      </fieldset>
      <fieldset class="space-y-3">
        <legend class="mb-3 text-sm font-medium">Labels</legend>
        <label class="flex items-center gap-2 text-sm">
          <input type="checkbox" class="checkbox" name="labels[]" value="Bug" /> Bug
        </label>
        <label class="flex items-center gap-2 text-sm">
          <input type="checkbox" class="checkbox" name="labels[]" value="Feature" /> Feature
        </label>
        <label class="flex items-center gap-2 text-sm">
          <input type="checkbox" class="checkbox" name="labels[]" value="Documentation" /> Documentation
        </label>
        <label class="flex items-center gap-2 text-sm">
          <input type="checkbox" class="checkbox" name="labels[]" value="Design" /> Design
        </label>
        <label class="flex items-center gap-2 text-sm">
          <input type="checkbox" class="checkbox" name="labels[]" value="Performance" /> Performance
        </label>
        <label class="flex items-center gap-2 text-sm">
          <input type="checkbox" class="checkbox" name="labels[]" value="Security" /> Security
        </label>
        <label class="flex items-center gap-2 text-sm">
          <input type="checkbox" class="checkbox" name="labels[]" value="Accessibility" /> Accessibility
        </label>
      </fieldset>
      <fieldset class="space-y-3">
        <legend class="mb-3 text-sm font-medium">Project</legend>
        <label class="flex items-center gap-2 text-sm">
          <input type="checkbox" class="checkbox" name="project[]" value="Website" /> Website
        </label>
        <label class="flex items-center gap-2 text-sm">
          <input type="checkbox" class="checkbox" name="project[]" value="Mobile app" /> Mobile app
        </label>
        <label class="flex items-center gap-2 text-sm">
          <input type="checkbox" class="checkbox" name="project[]" value="API" /> API
        </label>
        <label class="flex items-center gap-2 text-sm">
          <input type="checkbox" class="checkbox" name="project[]" value="Billing" /> Billing
        </label>
        <label class="flex items-center gap-2 text-sm">
          <input type="checkbox" class="checkbox" name="project[]" value="Onboarding" /> Onboarding
        </label>
      </fieldset>
    </form>
  </div>
  <div class="sheet-footer">
    <button type="reset" form="sheet_filters_form" class="btn btn-ghost">Clear all</button>
    <button class="btn btn-primary ml-auto grow sm:grow-0" commandfor="sheet_filters" command="close">
      Show 24 results
    </button>
  </div>
</dialog>
```

## Sizes

HEEx:

```heex
<%!-- size="sm|default|lg|xl": 20/24/32/40rem from sm, 75% on phones, max 90vw --%>
<.sheet id="filters" size="lg">
  <:trigger><.button variant="outline">Filters</.button></:trigger>
  <:title>Filters</:title>
  …
</.sheet>

<%!-- or set the width yourself; a width class beats the size --%>
<.sheet id="details" class="sm:w-[28rem]">…</.sheet>
<.sheet id="preview" class="[--sheet-width:28rem]">…</.sheet>
```

```html
<div class="flex flex-wrap gap-3">
  <button class="btn btn-outline" commandfor="sheet_size_sm" command="show-modal">sm</button>
  <dialog id="sheet_size_sm" class="sheet sheet-sm">
    <button
      class="btn btn-ghost btn-square btn-sm absolute right-3 top-3"
      aria-label="Close"
      commandfor="sheet_size_sm"
      command="close"
    >
      <span class="hero-x-mark size-4" aria-hidden="true"></span>
    </button>
    <h3 class="text-lg font-semibold">Small sheet</h3>
    <p class="mt-1 text-sm text-muted-foreground">20rem from sm, 75% on phones.</p>
  </dialog>
  <button class="btn btn-outline" commandfor="sheet_size_default" command="show-modal">default</button>
  <dialog id="sheet_size_default" class="sheet">
    <button
      class="btn btn-ghost btn-square btn-sm absolute right-3 top-3"
      aria-label="Close"
      commandfor="sheet_size_default"
      command="close"
    >
      <span class="hero-x-mark size-4" aria-hidden="true"></span>
    </button>
    <h3 class="text-lg font-semibold">Default sheet</h3>
    <p class="mt-1 text-sm text-muted-foreground">24rem from sm, 75% on phones.</p>
  </dialog>
  <button class="btn btn-outline" commandfor="sheet_size_lg" command="show-modal">lg</button>
  <dialog id="sheet_size_lg" class="sheet sheet-lg">
    <button
      class="btn btn-ghost btn-square btn-sm absolute right-3 top-3"
      aria-label="Close"
      commandfor="sheet_size_lg"
      command="close"
    >
      <span class="hero-x-mark size-4" aria-hidden="true"></span>
    </button>
    <h3 class="text-lg font-semibold">Large sheet</h3>
    <p class="mt-1 text-sm text-muted-foreground">32rem from sm, 75% on phones.</p>
  </dialog>
  <button class="btn btn-outline" commandfor="sheet_size_xl" command="show-modal">xl</button>
  <dialog id="sheet_size_xl" class="sheet sheet-xl">
    <button
      class="btn btn-ghost btn-square btn-sm absolute right-3 top-3"
      aria-label="Close"
      commandfor="sheet_size_xl"
      command="close"
    >
      <span class="hero-x-mark size-4" aria-hidden="true"></span>
    </button>
    <h3 class="text-lg font-semibold">Extra-large sheet</h3>
    <p class="mt-1 text-sm text-muted-foreground">40rem from sm, capped at 90vw.</p>
  </dialog>
  <button class="btn btn-outline" commandfor="sheet_size_custom" command="show-modal">sm:w-[28rem]</button>
  <dialog id="sheet_size_custom" class="sheet sm:w-[28rem]">
    <button
      class="btn btn-ghost btn-square btn-sm absolute right-3 top-3"
      aria-label="Close"
      commandfor="sheet_size_custom"
      command="close"
    >
      <span class="hero-x-mark size-4" aria-hidden="true"></span>
    </button>
    <h3 class="text-lg font-semibold">Custom width</h3>
    <p class="mt-1 text-sm text-muted-foreground">Any width class overrides the size.</p>
  </dialog>
</div>
```
