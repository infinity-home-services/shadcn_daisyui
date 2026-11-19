# Context Menu

A menu shown on right-click.

> Requires a JS hook: initialize with `initShadcnDaisyui()` (dead views) or the corresponding `Shadcn*` LiveView hook from `shadcn-daisyui.js`.

## Specs

| Part | Description |
| --- | --- |
| Trigger area | The element that opens the menu on right-click / long-press (data-context-menu-trigger). |
| Menu | A fixed-positioned role=menu panel clamped inside the viewport. |
| Menu items | role=menuitem buttons; the first item is focused on open. |

| Property | Value |
| --- | --- |
| Menu radius | var(--radius-md) |
| Item radius | var(--radius-sm) |
| Min width | 12rem |
| Padding | 0.25rem (menu), 0.375rem 0.5rem (item) |

Tokens used: `popover`, `popover-foreground`, `accent`, `accent-foreground`, `border-color`

## Accessibility

| Keys | Action |
| --- | --- |
| Arrow Down | Focus the next item (wraps to the first) |
| Arrow Up | Focus the previous item (wraps to the last) |
| Esc | Close the menu and return focus to the trigger |
| Enter / Space | Activate the focused item (native button) |

Role / ARIA: The panel is role=menu and its buttons are role=menuitem; it is positioned at the pointer and kept inside the viewport edges.

Focus: Opening focuses the first menuitem; Esc, an outside click, scroll, or window blur closes the menu and focus returns to the trigger.

Screen reader: Announced as a menu with menuitem children; activation runs the item's native button handler.

Touch target: Opened by long-press on touch; menu items are full-width rows that meet tap-size when padded for touch.

Reduced motion: The menu toggles via a hidden class with no transition, so reduced-motion is unaffected.

## Native (SwiftUI)

Parity: native parity with the web component.

```swift
rowView
    .contextMenu {
        Button("Edit") { edit() }
        Button("Duplicate") { duplicate() }
        Divider()
        Button("Delete", role: .destructive) { delete() }
    }
```

.contextMenu is the exact native analog - long-press on touch, right-click on macOS - so behavior maps one-to-one.

## Default

```html
<div id="demo-context-menu" phx-hook="ShadcnContextMenu" data-context-menu-trigger class="flex h-32 w-full max-w-sm items-center justify-center rounded-lg border border-dashed border-base-300 text-sm text-muted-foreground">
  Right-click here
</div>
<ul data-context-menu class="context-menu hidden">
  <li><button type="button">Back <span class="text-xs text-muted-foreground">⌘[</span></button></li>
  <li><button type="button">Forward <span class="text-xs text-muted-foreground">⌘]</span></button></li>
  <li><button type="button">Reload <span class="text-xs text-muted-foreground">⌘R</span></button></li>
  <li><button type="button" class="text-destructive">Delete</button></li>
</ul>
```
