# Sonner

An opinionated toast component: stacked, swipeable, auto-dismissing notifications.

> Requires a JS hook: initialize with `initShadcnDaisyui()` (dead views) or the corresponding `Shadcn*` LiveView hook from `shadcn-daisyui.js`.

A port of svelte-sonner, set up as shadcn-svelte ships it: same markup, timings and stylesheet, with the popover colours and lucide icons. Render one <.toaster /> in the root layout. From JS: import { toast } from "shadcn_daisyui" and call toast(), toast.success() / info / warning / error / loading, toast.promise(), toast.custom(), toast.dismiss(), toast.getActiveToasts(). From a LiveView: push_toast(socket, "Saved", type: :success, action: %{label: "Undo", event: "undo"}). Toasts live in the browser's top layer and follow into an open sheet, dialog, drawer or command palette, so they show above it and stay clickable without taking focus; Esc still closes the modal. Phoenix flashes (<.flash> / put_flash) render through the same toaster: info shows a success check and clears after 5 seconds, errors stay until closed.

## Usage guidance

Use when:

- Confirming a completed action the user doesn't need to act on ("Saved")
- Background results (export finished, message sent), optionally with an Undo action
- Long-running work: a loading toast that resolves to success or error (toast.promise)

Don't use for:

- Errors that need action - show inline errors or an alert in place
- Anything the user must read - toasts disappear
- Form validation - use field errors

Sizing: 356px wide, 16px padding, 14px between stacked toasts; one-line title, optional description and one action.

Responsive: Full width minus 16px gutters under 600px. Bottom-center keeps toasts in the thumb zone on compact screens; bottom-right on expanded.

iOS: No system toast: prefer an in-place state change; if needed, a brief overlay announced with UIAccessibility.post(notification: .announcement).

## Specs

| Part | Description |
| --- | --- |
| Toaster | A top-layer region (aria-label "Notifications alt+T", aria-live=polite) holding one <ol data-sonner-toaster> stack per screen position; <.toaster> only carries the options. |
| Toast | <li data-sonner-toast>: optional type icon, title + description, optional cancel/action buttons and a close button at the top start corner. |
| Stack | Newest toast in front; up to 3 visible, the ones behind peek out 14px apart, 5% smaller each. Hover or focus expands the stack. |

| Property | Value |
| --- | --- |
| Width | 356px (full width minus 16px gutters up to 600px) |
| Padding / radius | 16px / 8px (var(--radius-md)) |
| Viewport offset | 24px (16px up to 600px); offset / mobile_offset |
| Stack gap | 14px; collapsed toasts scale 5% per step |
| Title / description | 13px, 500 / 400 weight; description #3f3f3f (91% grey in dark), mixed from the toast colours |
| Action / cancel button | 24px tall, 4px radius, 12px / 500; action inverts the toast colours, cancel 8% (30% dark) of the text colour |
| Close button | 20px circle at the top start corner, 12px icon |
| Rich colours | sonner's own light and dark palettes (--success-bg / -border / -text … --error-*, on [data-sonner-toaster]), not the status tokens |
| Duration | 4000ms default; paused while hovered, focused, pressed, or the tab is hidden |
| Motion | 400ms transform/opacity/height, unmounted after 200ms; swipe 45px (or a flick) toward the stack's edges; promise icons scale in over 300ms |

Tokens used: `popover`, `popover-foreground`, `border-color`, `ring`

## Accessibility

| Keys | Action |
| --- | --- |
| Alt + T | Move focus to the toasts and expand the stack |
| Tab / Shift+Tab | Move between toasts and their action, cancel, and close buttons |
| Enter / Space | Activate the focused action or close button |
| Escape | Collapse the stack and return focus to where it was before Alt+T |

Role / ARIA: The toaster is a labeled polite live region; each toast is role=status (aria-live=assertive only when sent with important: true), so toasts are announced without stealing focus.

Focus: Toasts never take focus on their own; a focused or hovered stack pauses its timers so keyboard and screen-reader users have time to act.

Screen reader: Title and description are read as one atomic message. Keep them short and self-contained; never put the only copy of important information in a toast.

Touch target: Swipe a toast toward the edges its stack sits on (down or right for bottom-right; swipe_directions to change); the other way only stretches. The action button is 24px tall; on touch-first screens prefer an in-page control for anything critical.

Reduced motion: Under prefers-reduced-motion, toasts appear and leave without sliding or scaling, and the loading spinner slows down.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
someView
    .overlay(alignment: .bottom) {
        if showToast {
            Text("Saved")
                .padding()
                .background(.regularMaterial, in: Capsule())
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
```

No native toast/snackbar; compose a transient overlay with a transition. Announce it with .accessibilityAddTraits or an accessibility notification.

## Props

| Name | Type | Default |
| --- | --- | --- |
| position | top-left \| top-center \| top-right \| bottom-left \| bottom-center \| bottom-right | bottom-right |
| rich_colors | boolean | false |
| close_button | boolean | false |
| expand | boolean | false |
| invert | boolean | false |
| theme | auto \| light \| dark \| system | auto |
| duration | integer (ms) \| :infinity | 4000 |
| visible_toasts | integer | 3 |
| gap | integer (px) | 14 |
| offset / mobile_offset | integer \| string \| %{top:, right:, bottom:, left:} | 24px / 16px |
| hotkey | list | ["altKey", "KeyT"] |
| dir | auto \| ltr \| rtl | auto |
| swipe_directions | list | the position's edges |
| toast_options | map | %{} |
| toaster_id | string | nil |
| <:success_icon> … <:close_icon> | slots | lucide icons |

## Default

HEEx:

```heex
<%!-- once, in root.html.heex --%>
<.toaster />

<%!-- from a LiveView event handler --%>
{:noreply,
 push_toast(socket, "Event has been created",
   description: "Sunday, December 03, 2023 at 9:00 AM",
   action: %{label: "Undo", event: "undo-create", value: %{id: event.id}}
 )}
```

```html
<!-- docs site only: a delegated listener turns data-toast* into toast() calls.
     In your app call toast() from JS, or push_toast/2 from LiveView (HEEx tab). -->
<button class="btn btn-outline" data-toast="Event has been created" data-toast-description="Sunday, December 03, 2023 at 9:00 AM" data-toast-action="Undo">Show Toast</button>
```

## Types

HEEx:

```heex
push_toast(socket, "Event has been created", type: :success)
push_toast(socket, "Be at the area 10 minutes before the event time", type: :info)
push_toast(socket, "Event start time cannot be earlier than 8am", type: :warning)
push_toast(socket, "Event has not been created", type: :error)
```

```html
<!-- docs site only: a delegated listener turns data-toast* into toast() calls.
     In your app call toast() from JS, or push_toast/2 from LiveView (HEEx tab). -->
<div class="flex flex-wrap justify-center gap-2">
  <button class="btn btn-outline" data-toast="Event has been created">Default</button>
  <button class="btn btn-outline" data-toast="Event has been created" data-toast-type="success">Success</button>
  <button class="btn btn-outline" data-toast="Be at the area 10 minutes before the event time" data-toast-type="info">Info</button>
  <button class="btn btn-outline" data-toast="Event start time cannot be earlier than 8am" data-toast-type="warning">Warning</button>
  <button class="btn btn-outline" data-toast="Event has not been created" data-toast-type="error">Error</button>
  <button class="btn btn-outline" data-toast-promise="Event">Promise</button>
</div>
```

## Description

HEEx:

```heex
push_toast(socket, "Event has been created", description: "Monday, January 3rd at 6:00pm")
```

```html
<!-- docs site only: a delegated listener turns data-toast* into toast() calls.
     In your app call toast() from JS, or push_toast/2 from LiveView (HEEx tab). -->
<button class="btn btn-outline" data-toast="Event has been created" data-toast-description="Monday, January 3rd at 6:00pm">Show Toast</button>
```

## Position

HEEx:

```heex
<%!-- toaster-wide --%>
<.toaster position="top-center" />

<%!-- or per toast --%>
push_toast(socket, "Event has been created", position: "top-left")
```

```html
<!-- docs site only: a delegated listener turns data-toast* into toast() calls.
     In your app call toast() from JS, or push_toast/2 from LiveView (HEEx tab). -->
<div class="flex flex-wrap justify-center gap-2">
  <button class="btn btn-outline" data-toast="Event has been created" data-toast-position="top-left">Top Left</button>
  <button class="btn btn-outline" data-toast="Event has been created" data-toast-position="top-center">Top Center</button>
  <button class="btn btn-outline" data-toast="Event has been created" data-toast-position="top-right">Top Right</button>
  <button class="btn btn-outline" data-toast="Event has been created" data-toast-position="bottom-left">Bottom Left</button>
  <button class="btn btn-outline" data-toast="Event has been created" data-toast-position="bottom-center">Bottom Center</button>
  <button class="btn btn-outline" data-toast="Event has been created" data-toast-position="bottom-right">Bottom Right</button>
</div>
```

## Rich colors

HEEx:

```heex
<%!-- every toast --%>
<.toaster rich_colors />

<%!-- or one --%>
push_toast(socket, "Event has been created", type: :success, rich_colors: true)
```

```html
<!-- docs site only: a delegated listener turns data-toast* into toast() calls.
     In your app call toast() from JS, or push_toast/2 from LiveView (HEEx tab). -->
<div class="flex flex-wrap justify-center gap-2">
  <button class="btn btn-outline" data-toast="Event has been created" data-toast-type="success" data-toast-rich>Success</button>
  <button class="btn btn-outline" data-toast="Be at the area 10 minutes before the event time" data-toast-type="info" data-toast-rich>Info</button>
  <button class="btn btn-outline" data-toast="Event start time cannot be earlier than 8am" data-toast-type="warning" data-toast-rich>Warning</button>
  <button class="btn btn-outline" data-toast="Event has not been created" data-toast-type="error" data-toast-rich>Error</button>
</div>
```

## Action and cancel

HEEx:

```heex
push_toast(socket, "Event has been created",
  description: "Sunday, December 03, 2023 at 9:00 AM",
  action: %{label: "Undo", event: "undo", value: %{id: event.id}},
  cancel: %{label: "Dismiss"}
)
```

```html
<!-- docs site only: a delegated listener turns data-toast* into toast() calls.
     In your app call toast() from JS, or push_toast/2 from LiveView (HEEx tab). -->
<button class="btn btn-outline" data-toast="Event has been created" data-toast-description="Sunday, December 03, 2023 at 9:00 AM" data-toast-action="Undo" data-toast-cancel="Dismiss">Show Toast</button>
```

## Close button

HEEx:

```heex
<%!-- every toast --%>
<.toaster close_button />

<%!-- or one --%>
push_toast(socket, "Event has been created", close_button: true)
```

```html
<!-- docs site only: a delegated listener turns data-toast* into toast() calls.
     In your app call toast() from JS, or push_toast/2 from LiveView (HEEx tab). -->
<button class="btn btn-outline" data-toast="Event has been created" data-toast-description="Monday, January 3rd at 6:00pm" data-toast-close>Show Toast</button>
```

## Loading, then the result

HEEx:

```heex
<%!-- the same id turns the loading toast into its result --%>
push_toast(socket, "Uploading report.pdf…", id: "upload", type: :loading)
push_toast(socket, "report.pdf uploaded", id: "upload", type: :success)
```

```html
<!-- docs site only: a delegated listener turns data-toast* into toast() calls.
     In your app call toast() from JS, or push_toast/2 from LiveView (HEEx tab). -->
<button class="btn btn-outline" data-toast-promise="Report">Upload report</button>
```

## Invert

HEEx:

```heex
<%!-- dark toasts on a light page, light on a dark one --%>
<.toaster invert />

push_toast(socket, "Event has been created", invert: true)
```

```html
<!-- docs site only: a delegated listener turns data-toast* into toast() calls.
     In your app call toast() from JS, or push_toast/2 from LiveView (HEEx tab). -->
<button class="btn btn-outline" data-toast="Event has been created" data-toast-description="Sunday, December 03, 2023 at 9:00 AM" data-toast-action="Undo" data-toast-invert>Show Toast</button>
```

## Custom icon

HEEx:

```heex
<%!-- one toast: a heroicon class, or false for none --%>
push_toast(socket, "Draft saved", icon: "hero-cloud-arrow-up")

<%!-- every toast of a type --%>
<.toaster>
  <:success_icon><.icon name="hero-check-badge" class="size-4" /></:success_icon>
</.toaster>
```

```html
<!-- docs site only: a delegated listener turns data-toast* into toast() calls.
     In your app call toast() from JS, or push_toast/2 from LiveView (HEEx tab). -->
<button class="btn btn-outline" data-toast="Draft saved" data-toast-description="Synced to your workspace" data-toast-icon="hero-cloud-arrow-up">Show Toast</button>
```

## Headless

HEEx:

```heex
<%!-- JS only: your markup, with the stack, timers and swipe but no toast chrome --%>
import { toast } from "shadcn_daisyui"

toast.custom((id) => {
  const card = document.querySelector("#release-toast").content.firstElementChild.cloneNode(true)
  card.querySelector("[data-close]").addEventListener("click", () => toast.dismiss(id))
  return card
})
```

```html
<!-- docs site only: a delegated listener turns data-toast-custom into toast.custom().
     In your app call toast.custom() from JS (HEEx tab). -->
<button class="btn btn-outline" data-toast-custom="release-toast">Show Toast</button>
<template id="release-toast">
  <div class="card w-89 max-w-full flex-row items-center gap-3 p-4 shadow-lg">
    <span class="hero-sparkles size-5 shrink-0 text-muted-foreground" aria-hidden="true"></span>
    <div class="min-w-0 flex-1">
      <p class="text-sm font-medium">Version 2.4 is out</p>
      <p class="text-sm text-muted-foreground">Faster search and offline drafts.</p>
    </div>
    <button class="btn btn-sm btn-outline" data-close>Close</button>
  </div>
</template>
```

## Over an open sheet

HEEx:

```heex
<%!-- nothing to configure: toasts and flashes follow into the open
     sheet / dialog / drawer / command palette, above its backdrop --%>
<.sheet id="edit-profile">
  <:trigger><.button variant="outline">Open sheet</.button></:trigger>
  <:title>Edit profile</:title>
  <.button phx-click="save">Save changes</.button>
</.sheet>

def handle_event("save", _params, socket) do
  {:noreply,
   socket
   |> put_flash(:info, "Profile saved")
   |> push_toast("Event has been created", action: %{label: "Undo", event: "undo"})}
end
```

```html
<!-- docs site only: a delegated listener turns data-toast* into toast() calls.
     In your app call toast() from JS, or push_toast/2 from LiveView (HEEx tab). -->
<button class="btn btn-outline" commandfor="toast_sheet" command="show-modal">Open sheet</button>
<dialog id="toast_sheet" class="sheet">
  <button
    class="btn btn-ghost btn-square btn-sm absolute right-3 top-3"
    aria-label="Close"
    commandfor="toast_sheet"
    command="close"
  >
    <span class="hero-x-mark size-4" aria-hidden="true"></span>
  </button>
  <h3 class="text-lg font-semibold">Edit profile</h3>
  <p class="mt-1 text-sm text-muted-foreground">
    The toast shows above the sheet and its backdrop. Its buttons work and focus stays here; Esc closes the sheet.
  </p>
  <div class="mt-5 flex flex-wrap gap-3">
    <button class="btn btn-primary" data-toast="Profile saved" data-toast-type="success">Save changes</button>
    <button class="btn btn-outline" data-toast="Event has been created" data-toast-description="Sunday, December 03, 2023 at 9:00 AM" data-toast-action="Undo">Show toast</button>
    <button class="btn btn-outline" data-toast="Could not save the profile" data-toast-type="error">Show error</button>
  </div>
</dialog>
```
