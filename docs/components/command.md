# Command

A command palette for fast keyboard-driven actions.

> Requires a JS hook: initialize with `initShadcnDaisyui()` (dead views) or the corresponding `Shadcn*` LiveView hook from `shadcn-daisyui.js`.

## Specs

| Part | Description |
| --- | --- |
| Search input | role=combobox at the top of the modal; filters every command by text content. |
| Groups | Labelled sections (data-group) that hide themselves when none of their items match. |
| Item | role=option row (data-command-item) with optional icon and a trailing shortcut hint. |
| Empty state | Shown when the query matches no command. |

| Property | Value |
| --- | --- |
| Dialog radius | var(--radius-lg) |
| Item radius | var(--radius-sm) |
| Group label font | 0.75rem / weight 500 |
| Surface | var(--popover) over a modal backdrop |

Tokens used: `popover`, `popover-foreground`, `accent`, `accent-foreground`, `muted-foreground`, `border-color`

## Accessibility

| Keys | Action |
| --- | --- |
| Cmd/Ctrl + K | Open the command palette from anywhere |
| Arrow Down | Move to the next visible command (wraps) |
| Arrow Up | Move to the previous visible command (wraps) |
| Enter | Run the active command and close the palette |
| Esc | Close the dialog (native <dialog> behavior) |
| Type | Filter commands; empty groups collapse |

Role / ARIA: A native <dialog> modal. The search is role=combobox over a role=listbox; each command is role=option with aria-selected tracking the active row.

Focus: Opening focuses the search field (a MutationObserver resets the query on open); the native <dialog> traps focus and restores it to the opener on close.

Screen reader: aria-activedescendant names the highlighted command; the modal dialog role scopes the listbox to the palette.

Touch target: Command rows are comfortable to tap; the palette is keyboard-first but works as a tap list on touch.

Reduced motion: The dialog open/close is excluded from the instant-theme transition reset, but it only fades/scales briefly and respects prefers-reduced-motion.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
List(filtered) { cmd in
    Button { run(cmd) } label: { Label(cmd.title, systemImage: cmd.icon) }
}
.searchable(text: $query, placement: .toolbar)
```

No system command palette exists; the closest match is a searchable List presented in a sheet. Bind Cmd-K with a .keyboardShortcut on macOS / Catalyst.

## Default

HEEx:

```heex
<.command id="commands">
  <:trigger_label>Search commands…</:trigger_label>
  <:item group="Suggestions" icon="hero-calendar">Calendar</:item>
  <:item group="Suggestions" icon="hero-face-smile">Search Emoji</:item>
  <:item group="Suggestions" icon="hero-calculator">Calculator</:item>
  <:item group="Settings" icon="hero-user" shortcut="⌘P">Profile</:item>
  <:item group="Settings" icon="hero-cog-6-tooth" shortcut="⌘S">Settings</:item>
</.command>
```

```html
<button class="btn btn-outline w-64 justify-between" onclick="document.getElementById('command_dialog').showModal()">
  <span class="text-muted-foreground">Search commands…</span>
  <kbd class="kbd">⌘K</kbd>
</button>
<dialog id="command_dialog" data-command class="command-dialog">
  <div class="flex items-center gap-2 border-b border-base-300 px-3">
    <span class="hero-magnifying-glass size-4 opacity-50" aria-hidden="true"></span>
    <input data-command-search class="h-11 w-full bg-transparent text-sm outline-none" placeholder="Type a command or search…" />
  </div>
  <ul data-command-list class="max-h-80 overflow-auto p-1">
    <li class="command-group-label" data-group>Suggestions</li>
    <li><button type="button" class="command-item" data-command-item><span class="hero-calendar size-4" aria-hidden="true"></span> Calendar</button></li>
    <li><button type="button" class="command-item" data-command-item><span class="hero-face-smile size-4" aria-hidden="true"></span> Search Emoji</button></li>
    <li><button type="button" class="command-item" data-command-item><span class="hero-calculator size-4" aria-hidden="true"></span> Calculator</button></li>
    <li class="command-group-label" data-group>Settings</li>
    <li><button type="button" class="command-item" data-command-item><span class="hero-user size-4" aria-hidden="true"></span> Profile <span class="ml-auto text-xs text-muted-foreground">⌘P</span></button></li>
    <li><button type="button" class="command-item" data-command-item><span class="hero-cog-6-tooth size-4" aria-hidden="true"></span> Settings <span class="ml-auto text-xs text-muted-foreground">⌘S</span></button></li>
  </ul>
  <p data-command-empty class="hidden p-6 text-center text-sm text-muted-foreground">No results found.</p>
</dialog>
```
