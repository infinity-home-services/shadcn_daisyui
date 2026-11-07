# Menubar

A horizontal bar of dropdown menus, like a desktop app.

## Specs

| Part | Description |
| --- | --- |
| Bar | A horizontal row of ghost menu triggers in a bordered container. |
| Menu trigger | A role=button label (File / Edit / View) that opens its dropdown. |
| Dropdown | A .menu list of items, each optionally showing a keyboard shortcut hint. |

| Property | Value |
| --- | --- |
| Bar radius | var(--radius-md) |
| Menu item radius | var(--radius-sm) |
| Trigger | btn-ghost btn-sm |
| Surface | var(--popover) dropdown over var(--background) bar |

Tokens used: `background`, `foreground`, `popover`, `popover-foreground`, `accent`, `muted-foreground`, `border-color`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Move focus across the menu triggers |
| Enter / Space | Open the focused trigger's menu (tabindex=0 dropdown) |
| Esc | Close the open menu (blur the focused dropdown) |

Role / ARIA: Built on daisyUI dropdowns: each trigger is role=button with a tabindex=0 menu (.menu) of links. For full menubar semantics add role=menubar / menuitem and roving focus.

Focus: daisyUI dropdowns open on focus/click of the tabindex=0 trigger and close on blur; there is no built-in roving arrow-key traversal across the bar.

Screen reader: Each trigger reads as a button and its items as links; promote to role=menubar/menuitem if you need true menu semantics announced.

Touch target: btn-sm triggers and menu rows are tappable; size up the bar for touch since this pattern is desktop-oriented.

Reduced motion: Menus appear without movement, so reduced-motion has nothing to suppress.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
.toolbar {
    ToolbarItem(placement: .navigation) {
        Menu("File") {
            Button("New Tab") { newTab() }
            Button("New Window") { newWindow() }
        }
    }
}
// macOS: declare top-level menus with the CommandMenu / .commands modifier
```

On macOS use the .commands / CommandMenu API for a real menu bar; on iOS/iPadOS this becomes toolbar Menus, since there is no global menubar.

## Default

```html
<div class="flex w-fit items-center gap-1 rounded-md border border-base-300 bg-base-100 p-1">
  <div class="dropdown">
    <div tabindex="0" role="button" class="btn btn-ghost btn-sm">File</div>
    <ul tabindex="0" class="dropdown-content menu mt-1 w-52">
      <li><a class="flex justify-between">New Tab <span class="text-xs text-muted-foreground">⌘T</span></a></li>
      <li><a class="flex justify-between">New Window <span class="text-xs text-muted-foreground">⌘N</span></a></li>
      <li><a>Share</a></li>
      <li><a class="flex justify-between">Print <span class="text-xs text-muted-foreground">⌘P</span></a></li>
    </ul>
  </div>
  <div class="dropdown">
    <div tabindex="0" role="button" class="btn btn-ghost btn-sm">Edit</div>
    <ul tabindex="0" class="dropdown-content menu mt-1 w-44">
      <li><a class="flex justify-between">Undo <span class="text-xs text-muted-foreground">⌘Z</span></a></li>
      <li><a class="flex justify-between">Redo <span class="text-xs text-muted-foreground">⇧⌘Z</span></a></li>
      <li><a>Cut</a></li>
      <li><a>Copy</a></li>
    </ul>
  </div>
  <div class="dropdown">
    <div tabindex="0" role="button" class="btn btn-ghost btn-sm">View</div>
    <ul tabindex="0" class="dropdown-content menu mt-1 w-48">
      <li><a>Reload</a></li>
      <li><a>Toggle Fullscreen</a></li>
      <li><a>Hide Sidebar</a></li>
    </ul>
  </div>
</div>
```
