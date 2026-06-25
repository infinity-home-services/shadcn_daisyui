# Dropdown Menu

A menu of actions or links triggered by a button.

## Usage guidance

Use when:

- 3-8 secondary actions behind one trigger (row actions, ⋯ menus)
- Account/user menus in the navbar

Don't use for:

- A single action - show the button directly
- Choosing a form value - use select or combobox
- More than ~8 items - use a command palette or a dedicated page

Sizing: Menu items are text-sm with rounded-sm; destructive item last, styled destructive.

Responsive: Menus are fine on touch (items are full-width rows); ensure the trigger itself meets the 44pt floor.

iOS: Menu attached to a button (or context menu on long-press); destructive role last.

## Specs

| Part | Description |
| --- | --- |
| Trigger | Button (with chevron) that opens the menu on click via tabindex/focus. |
| Menu | Popover ul (dropdown-content menu) of items, optional menu-title label. |
| Item | Action or link row that tints with accent on hover/focus. |

| Property | Value |
| --- | --- |
| Default width | w-48 |
| Panel radius | var(--radius-md) |
| Panel padding | 0.25rem |
| Item radius | var(--radius-sm) |
| Item hover | var(--accent) / var(--accent-foreground) |

Tokens used: `popover`, `popover-foreground`, `border-color`, `accent`, `accent-foreground`, `muted-foreground`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab / Enter / Space | Open the menu and move focus into it |
| Arrow keys | Move between menu items |
| Esc | Close the menu and return focus to the trigger |

Role / ARIA: CSS-only daisyUI dropdown: a role=button trigger plus a focusable list. For full menu semantics layer role=menu / menuitem; the label slot is a non-interactive menu-title.

Focus: Trigger and items show focus styling; the open menu closes when focus leaves it (CSS :focus-within mechanism).

Screen reader: Trigger needs an accessible name; add aria-haspopup / aria-expanded for a complete menu-button pattern.

Touch target: Item rows are comfortably tappable; ensure 44pt on touch-primary surfaces.

Reduced motion: Menu shows/hides without a color fade under the theme.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
Menu("Open menu") {
    Section("My Account") {
        Button("Profile") { }
        Button("Log out", role: .destructive) { }
    }
}
```

Menu is a close native equivalent with system-managed dismissal and keyboard support; visual chrome differs from the web menu.

## Default

HEEx:

```heex
<.dropdown_menu>
  <:trigger>Open menu</:trigger>
  <:label>My Account</:label>
  <:item><.link navigate={~p"/profile"}>Profile</.link></:item>
  <:item>Billing</:item>
  <:item>Settings</:item>
  <:item phx-click="logout" class="text-destructive">Log out</:item>
</.dropdown_menu>
```

```html
<div class="dropdown">
  <div tabindex="0" role="button" class="btn btn-outline">
    Open menu <span class="hero-chevron-down size-4" aria-hidden="true"></span>
  </div>
  <ul tabindex="0" class="dropdown-content menu z-10 mt-2 w-48">
    <li class="menu-title">My Account</li>
    <li><a>Profile</a></li>
    <li><a>Billing</a></li>
    <li><a>Settings</a></li>
    <li><a class="text-destructive">Log out</a></li>
  </ul>
</div>
```
