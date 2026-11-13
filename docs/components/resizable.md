# Resizable

Panels the user can resize by dragging a handle.

> Requires a JS hook: initialize with `initShadcnDaisyui()` (dead views) or the corresponding `Shadcn*` LiveView hook from `shadcn-daisyui.js`.

## Specs

| Part | Description |
| --- | --- |
| Panels | Two or more .resizable-panel regions; the first stores its width. |
| Handle | A draggable divider (role=separator, aria-orientation=vertical, tabindex=0) with a grip. |

| Property | Value |
| --- | --- |
| Handle width | thin visible line with a wider invisible hit area (::after) |
| Handle focus | var(--ring) focus ring |
| Container radius | var(--radius-lg) |
| Border | 1px var(--border-color) |

Tokens used: `background`, `foreground`, `border-color`, `muted`, `ring`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Focus the resize handle (shows a focus ring) |

Role / ARIA: The handle is role=separator with aria-orientation=vertical and tabindex=0 so it is focusable as a resize control.

Focus: The handle is focusable and shows a ring on :focus-visible; dragging uses pointer capture and disables text selection during the drag.

Screen reader: Announced as a separator; add an aria-label and aria-valuenow if you wire up keyboard resizing for full WAI-ARIA window-splitter support.

Touch target: The visible handle is thin but a wider invisible ::after hit area makes it draggable by pointer and touch.

Reduced motion: Resizing tracks the pointer directly with no animation.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
NavigationSplitView {
    SidebarView()
} detail: {
    DetailView()
}
// macOS: HSplitView { PaneA(); PaneB() } gives a user-draggable divider
```

NavigationSplitView manages the split on iPadOS but the divider is not freely user-draggable; macOS HSplitView is the closer match for a drag-to-resize handle.

## Default

HEEx:

```heex
<.resizable id="panes" class="h-44 w-80 max-w-full">
  <:start><span class="font-semibold">One</span></:start>
  <:end_pane><span class="font-semibold">Two</span></:end_pane>
</.resizable>
```

```html
<div
  id="resizable-demo"
  data-resizable
  class="flex h-44 w-80 max-w-full overflow-hidden rounded-lg border border-base-300 text-sm"
>
  <div class="resizable-panel flex items-center justify-center" style="width: 50%">
    <span class="font-semibold">One</span>
  </div>
  <div class="resizable-handle" role="separator" aria-orientation="vertical" tabindex="0">
    <div class="resizable-grip"><span class="hero-ellipsis-vertical size-2.5" aria-hidden="true"></span></div>
  </div>
  <div class="resizable-panel flex flex-1 flex-col">
    <div class="flex flex-1 items-center justify-center border-b border-base-300">
      <span class="font-semibold">Two</span>
    </div>
    <div class="flex flex-1 items-center justify-center">
      <span class="font-semibold">Three</span>
    </div>
  </div>
</div>
```
