# Command

A command palette for fast keyboard-driven actions.

> Requires a JS hook: initialize with `initShadcnDaisyui()` (dead views) or the corresponding `Shadcn*` LiveView hook from `shadcn-daisyui.js`.

Opens with ⌘K (Ctrl+K), which also closes it; shortcut="j" picks another letter and shortcut={nil} none (every palette on the page but one). Opening it closes any other open dialog. Items run phx-click, or go somewhere: navigate / patch / href, or form + name + value (submits that form). label is the dialog's accessible name. The hook drops its key listener when LiveView removes it. The app shell's search is one (/docs/app-shell). icon sets the search row's heroicon (default "hero-magnifying-glass"; any class <.icon name> takes, -solid/-mini/-micro too; icon={nil} for none) - write it out in full so Tailwind's heroicons plugin generates it. Server search (on_search="event"): the hook stops filtering and pushes the typed text, debounced (search_debounce, 250ms), as %{"id" => id, "query" => text}; the LiveView renders its results as the items and echoes the text they answer as query={@query} - results count only while it matches the input, so a reply to older text never shows as current. <:hint> shows before anything is typed, a spinner and aria-busy while the reply is pending (what was on screen stays, dimmed), <:empty> once the server has answered with nothing; each answer's count is announced politely. Opening clears the input and pushes an empty search. phx-target={@myself} sends the search and the items' phx-click to a LiveComponent. Opt-in item attributes: description (a muted second line), confirm (data-confirm; closes only once accepted), values (phx-value-*), disabled. A LiveView demo is at /lab/command-search when running the docs app.

## Specs

| Part | Description |
| --- | --- |
| Search input | role=combobox at the top of the modal; filters every command by text content. |
| Groups | Labelled sections (data-group) that hide themselves when none of their items match. |
| Item | role=option row (data-command-item) with optional icon and a trailing shortcut hint. |
| Empty state | Shown when the query matches no command (<:empty>, default "No results found."); with on_search, only once the server has answered the current text. |
| Hint (server search) | <:hint>, shown before anything is typed. |
| Busy state (server search) | A spinner at the end of the input row and aria-busy on the list while the reply is pending; what was on screen (the hint, the empty text or the last results, inert) stays, dimmed. With no rows the list itself is hidden, so no empty strip shows under the input. |
| Status region (server search) | A visually hidden role=status region announcing each answer's result count. |

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
| Cmd/Ctrl + K | Open the command palette from anywhere, or close it (its shortcut letter) |
| Arrow Down | Move to the next visible command (wraps) |
| Arrow Up | Move to the previous visible command (wraps) |
| Enter | Run the active command and close the palette |
| Esc | Close the dialog (native <dialog> behavior) |
| Type | Filter commands; empty groups collapse (with on_search: search on the server) |

Role / ARIA: A native <dialog> modal. The search is role=combobox over a role=listbox; each command is role=option with aria-selected tracking the active row.

Focus: Opening focuses the search field (a MutationObserver resets the query on open); the native <dialog> traps focus and restores it to the opener on close.

Screen reader: aria-activedescendant names the highlighted command; the modal dialog role scopes the listbox to the palette. With on_search the list is aria-busy while a reply is pending, and a polite status region announces each answer's count ("3 results", or the empty text). Disabled items are aria-disabled and skipped by the arrow keys.

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
<button class="btn btn-outline w-64 justify-between" commandfor="command_dialog" command="show-modal">
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

## Server search

HEEx:

```heex
<.command
  id="find-person"
  label="Add person"
  placeholder="Name or email"
  icon="hero-user-plus"
  shortcut={nil}
  on_search="search_people"
  query={@query}
>
  <:trigger_label>Add person…</:trigger_label>
  <:hint>Type a name or email.</:hint>
  <:empty>No one matches "{@query}".</:empty>
  <:item
    :for={person <- @results}
    id={"person-#{person.id}"}
    icon="hero-user"
    description={person.email}
    phx-click="add"
    values={%{id: person.id}}
    confirm={person.removed && "Add #{person.name} back? They start with no roles."}
  >
    {person.name}
  </:item>
</.command>

# in the LiveView: answer the latest text, and echo it
def handle_event("search_people", %{"query" => query}, socket) do
  {:noreply, assign(socket, query: query, results: People.search(query))}
end
```

```html
<button class="btn btn-outline w-64 justify-between" commandfor="command_people" command="show-modal">
  <span class="text-muted-foreground">Add person…</span>
</button>
<dialog id="command_people" data-command data-shortcut="" data-on-search data-search-debounce="250" aria-label="Add person" class="command-dialog">
  <div class="flex items-center gap-2 border-b border-base-300 px-3">
    <span class="hero-user-plus size-4 opacity-50" aria-hidden="true"></span>
    <input data-command-search autocomplete="off" aria-label="Name or email" class="h-11 w-full bg-transparent text-sm outline-none" placeholder="Name or email" />
    <span data-command-spinner class="loading loading-spinner loading-xs hidden shrink-0 opacity-50" aria-hidden="true"></span>
  </div>
  <ul data-command-list class="max-h-80 overflow-auto p-1"></ul>
  <p data-command-hint class="p-6 text-center text-sm text-muted-foreground">Type a name or email.</p>
  <p data-command-empty class="hidden p-6 text-center text-sm text-muted-foreground">No results found.</p>
  <div data-command-status role="status" class="sr-only"></div>
</dialog>
```
