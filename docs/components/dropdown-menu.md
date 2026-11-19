# Dropdown Menu

A menu of actions or links triggered by a button.

The menu is floating content at z-50, so it opens above sticky table headers, toolbars and bottom bars (z-10). Dialogs and sheets render in the browser's top layer, above both. Item attributes variant, confirm, values, id and disabled, and the menu's close_on_select, are opt in: items without them render exactly as before. confirm renders data-confirm, which phoenix_html (imported in a stock Phoenix app.js) turns into a browser confirm before phx-click is sent; name the object, e.g. "Remove Acme Marketing from Pat?".

## Usage guidance

Use when:

- 3-8 secondary actions behind one trigger (row actions, ⋯ menus)
- Account/user menus in the navbar

Don't use for:

- A single action - show the button directly
- Choosing a form value - use select or combobox
- More than ~8 items - use a command palette or a dedicated page

Sizing: Menu items are text-sm with rounded-sm; destructive item last, `variant="destructive"` with a `confirm` that names the object. Opt-in item attrs leave existing items untouched.

Responsive: Menus are fine on touch (items are full-width rows); ensure the trigger itself meets the 44pt floor.

iOS: Menu attached to a button (or context menu on long-press); destructive role last.

## Specs

| Part | Description |
| --- | --- |
| Trigger | Button (with a chevron unless chevron={false}) that opens the menu on click via tabindex/focus. Icon-only triggers use btn-square and aria-label. |
| Menu | Popover ul (dropdown-content menu) of items, optional menu-title label. |
| Item | Action or link row that tints with accent on hover/focus. |

| Property | Value |
| --- | --- |
| Default width | w-48 |
| Panel radius | var(--radius-md) |
| Panel padding | 0.25rem |
| Item radius | var(--radius-sm) |
| Item hover | var(--accent) / var(--accent-foreground) |
| Layer | z-50 (floating), above sticky headers and bars (z-10) |

Tokens used: `popover`, `popover-foreground`, `border-color`, `accent`, `accent-foreground`, `muted-foreground`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab / Enter / Space | Open the menu and move focus into it |
| Arrow keys | Move between menu items |
| Esc | Close the menu and return focus to the trigger |

Role / ARIA: CSS-only daisyUI dropdown: a role=button trigger plus a focusable list. For full menu semantics layer role=menu / menuitem; the label slot is a non-interactive menu-title.

Focus: Trigger and items show focus styling; the open menu closes when focus leaves it (CSS :focus-within mechanism).

Screen reader: Trigger needs an accessible name: its text, or aria-label for an icon-only trigger ("More actions"). Add aria-haspopup / aria-expanded for a complete menu-button pattern.

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

## Props

| Name | Type | Default |
| --- | --- | --- |
| trigger_class | classes | "btn btn-outline" |
| chevron | boolean | true |
| aria-label | string (icon-only triggers) | nil |
| align | start \| end | start |
| class | menu panel classes | "w-48" |
| close_on_select | boolean (opt in) | false |
| :item class / phx-click / phx-value-id | slot attrs | - |
| :item variant | destructive (opt in) | nil |
| :item confirm | string, data-confirm (opt in) | nil |
| :item values | map, phx-value-<key> (opt in) | nil |
| :item id | string (opt in) | nil |
| :item disabled | boolean (opt in) | false |

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
  <ul tabindex="0" class="dropdown-content menu z-50 mt-2 w-48">
    <li class="menu-title">My Account</li>
    <li><a>Profile</a></li>
    <li><a>Billing</a></li>
    <li><a>Settings</a></li>
    <li><a class="text-destructive">Log out</a></li>
  </ul>
</div>
```

## Icon-only trigger (row actions)

HEEx:

```heex
<.dropdown_menu
  trigger_class="btn btn-ghost btn-square btn-sm"
  chevron={false}
  aria-label="More actions"
  align="end"
  class="w-40"
>
  <:trigger><.icon name="hero-ellipsis-horizontal" class="size-4" /></:trigger>
  <:item phx-click="edit" phx-value-id={@row.id}>Edit</:item>
  <:item phx-click="duplicate" phx-value-id={@row.id}>Duplicate</:item>
  <:item phx-click="delete" phx-value-id={@row.id} class="text-destructive">Delete</:item>
</.dropdown_menu>
```

```html
<div class="dropdown dropdown-end">
  <div tabindex="0" role="button" class="btn btn-ghost btn-square btn-sm" aria-label="More actions">
    <span class="hero-ellipsis-horizontal size-4" aria-hidden="true"></span>
  </div>
  <ul tabindex="0" class="dropdown-content menu z-50 mt-2 w-40">
    <li><a>Edit</a></li>
    <li><a>Duplicate</a></li>
    <li><a class="text-destructive">Delete</a></li>
  </ul>
</div>
```

## Row actions with a confirmed, destructive Remove

HEEx:

```heex
<.dropdown_menu
  trigger_class="btn btn-ghost btn-square btn-sm"
  chevron={false}
  aria-label={"Actions for #{@member.name}"}
  align="end"
  class="w-40"
  close_on_select
>
  <:trigger><.icon name="hero-ellipsis-horizontal" class="size-4" /></:trigger>
  <:item phx-click="edit" phx-value-id={@member.id}>Edit</:item>
  <:item disabled>Transfer</:item>
  <:item
    phx-click="remove"
    values={%{user_id: @member.id, team_id: @team.id}}
    variant="destructive"
    confirm={"Remove #{@team.name} from #{@member.name}?"}
  >
    Remove
  </:item>
</.dropdown_menu>
```

```html
<div class="dropdown dropdown-end" data-close-on-select>
  <div tabindex="0" role="button" class="btn btn-ghost btn-square btn-sm" aria-label="Actions for Pat">
    <span class="hero-ellipsis-horizontal size-4" aria-hidden="true"></span>
  </div>
  <ul tabindex="0" class="dropdown-content menu z-50 mt-2 w-40">
    <li><a>Edit</a></li>
    <li><a aria-disabled="true">Transfer</a></li>
    <li>
      <a class="text-destructive" data-variant="destructive" data-confirm="Remove Acme Marketing from Pat?">Remove</a>
    </li>
  </ul>
</div>
```
