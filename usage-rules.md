<!--
usage-rules.md - synced into consuming apps' AGENTS.md / CLAUDE.md via the
`usage_rules` package:  mix usage_rules.sync AGENTS.md --all
Keep this file dense and imperative: it is read by AI coding agents, not humans.
-->

# shadcn_daisyui usage rules

This app's design system is `shadcn_daisyui` - daisyUI v5 themed to look and behave
like shadcn/ui. **Every UI decision goes through this package.**

## Non-negotiables

- ALL UI uses shadcn_daisyui components or themed daisyUI classes. Never hand-roll
  one-off Tailwind component markup (custom buttons, cards, inputs built from raw
  utilities) when a component or class recipe exists below.
- Never enable stock daisyUI themes (`@plugin "daisyui"` must keep `themes: false`)
  and never use daisyUI theme names (`light`, `dark`, `cupcake`, …) in `data-theme`.
- Never regenerate or restyle Phoenix's default `core_components.ex` styling - this
  package provides `ShadcnDaisyui.CoreComponents` as the drop-in replacement.
- Never use raw color utilities (`bg-white`, `text-gray-500`, `bg-zinc-900`,
  `border-neutral-200`, hex/oklch literals) in templates. Use semantic tokens only
  (see Theme tokens).
- Multi-value pickers and filters (status, labels, the data-table faceted filter) are
  `<.select multiple>` (short lists) or `<.combobox multiple>` (long lists, search).
  Never build a checkbox-dropdown by hand.
- Rows that can outgrow their width are `<.tab_nav>` (link tabs → More menu)
  and `<.chip_row>` (removable chips → "+N" popover). Never let a tab or chip
  row wrap or scroll sideways, and never hand-roll an overflow menu.
- Rows that appear and disappear in place (filter chips, inline alerts) slide
  with `<.reveal open={…}>`. Never hand-animate `height` / `max-height`, and
  never `:if` the chip row inside the reveal - `open` drives it, and the chips
  animate in and out on their own.
- A signed-in app's layout is `<.app_shell>` (see App shell). Never hand-roll a
  sidebar, bottom bar, account menu or page header.
- A list page is `<.table_toolbar>` over `<.data_table>` in an `<.app_shell fill>`
  page, with its sort, search and filters in `ShadcnDaisyui.DataTable.State` (in
  the URL). Never hand-roll a sticky table header, a select-all checkbox, a
  bulk-action bar, infinite scroll, a filters sheet or a filter chip row (see
  List and record pages).
- A record page is built from `<.page_header>`, `<.record_tabs>`, `<.section_nav>`
  (where an edit form's sections are), `<.table_card>` and `<.time_field>`. Empty
  pages, lists and tables are `<.empty>`. Never hand-roll a scrollspy, a section
  dropdown or an "icon in a circle" empty block.
- A dialog the server decides on ("discard your changes?", a step that needs the
  server first) opens from the server: `push_show_modal(socket, id)` /
  `push_hide_modal/2`, or `show={@confirm?}` with `on_close`. A button opens from
  the browser (`show_modal/2`). Never toggle a dialog's `open` attribute yourself.
- A file upload is `<.dropzone upload={@uploads.x}>` (`size="compact"` in tight
  forms); the picked files show under it as `<.attachment>` tiles. Never show a
  bare `<.live_file_input>` or hand-roll a drop area (see `usage-rules/forms.md`).
- Interactive components (combobox, select, date picker, time picker, time field,
  calendar, range calendar, OTP, carousel, resizable, command, context-menu,
  toaster, tab nav, chip row, page header, data table, section nav, dropzone) REQUIRE a
  unique `id` attribute and the JS hooks
  registered on the LiveSocket (`import { Hooks } from "shadcn_daisyui"` …
  `hooks: { ...Hooks }`).
- Never write inline event handlers (`onclick=`, `onsubmit=`, …) or `javascript:`
  URLs - they break under a strict `script-src` CSP. Open/close overlays with
  `phx-click={show_modal("id")}` / `hide_modal("id")` (the components do this
  for you), or in plain HTML with invoker commands
  (`<button commandfor="id" command="show-modal">`, `command="close"`).

## Picking a component

Decision order:

1. **A function component exists → use it.** Import via `use ShadcnDaisyui.Components`
   (and `ShadcnDaisyui.CoreComponents` for form/table/flash, usually already imported
   in the app's `CoreComponents`).
2. **No function component → use the documented daisyUI class recipe** (table below).
   The theme styles every daisyUI class automatically.
3. **Neither exists → compose from tokens + primitives.** Match shadcn/ui metrics:
   `text-sm`, `rounded-md` fields and floating content / `rounded-xl` cards and dialogs,
   1px `border-border` borders, flat surfaces (`shadow-sm` on cards, the overlay
   recipes carry their own elevation), `text-muted-foreground` for secondary text.
   Do not invent new colors, radii, or shadows.

### Function components

`use ShadcnDaisyui.Components` imports all of these (plus `ShadcnDaisyui.FormComponents`):

| Component | Signature sketch |
|---|---|
| `<.badge>` | `variant="default\|secondary\|outline\|destructive"` |
| `<.alert>` | `variant="default\|destructive"`, `<:title>` slot; inner block is a `div` (paragraphs, links); opt-in `<:icon>` (16px, left of the text) and `<:actions>` (buttons right of the text from `sm`, below it on phones) - never put a button in the text or add a colored left border |
| `<.card>` / `<.card_body>` / `<.card_title>` / `<.card_description>` | compose |
| `<.separator>` | `orientation="horizontal\|vertical"` |
| `<.dialog>` | `id` req., `<:trigger>` `<:title>` `<:description>` `<:actions>`; open via `show_modal(id)` |
| opening from the server | `push_show_modal(socket, id)` / `push_hide_modal(socket, id)` (opens each time it's pushed, even after the person closed it), or `show={@open?}` + `on_close="event"` (or a JS) on `<.dialog>` / `<.sheet>` / `<.drawer>` / `<.command>`: open on mount and whenever `show` turns true; `on_close` runs when the person closes it (Esc, backdrop, a close or Cancel button) - set the assign false there; closing from the server doesn't run it |
| `<.sheet>` / `<.drawer>` | `id` req., `<:trigger>` `<:title>` `<:description>` `<:header>` (stays put, e.g. search) + body + `<:footer>` (pinned actions: ghost "Clear all" left, primary `ml-auto grow sm:grow-0`); only the body scrolls, lines show only while content is under the header/footer - never add your own sticky header/footer, borders or shadows; right panel / bottom panel; sheet `size="sm\|default\|lg\|xl"` (20/24/32/40rem from `sm`, 75% on phones, ≤90vw), or a width class (`sm:w-[28rem]`) |
| `<.popover>` | `<:trigger>` + content |
| `<.tooltip>` | `tip="..."` `position="top\|bottom\|left\|right"` wraps trigger |
| `<.dropdown_menu>` | `<:trigger>` `<:label>` `<:item>` slots, `align="start\|end"`; icon-only ⋯ trigger: `trigger_class="btn btn-ghost btn-square btn-sm" chevron={false} aria-label="More actions"`; opt-in item attrs (items without them render as before): `variant="destructive"`, `confirm="Remove Acme Marketing from Pat?"` (`data-confirm`, name the object), `values={%{user_id: …}}` (one `phx-value-<key>` each, wins over `phx-value-id` for its own keys), `id`, `disabled` (`aria-disabled`, no click, 50%); opt-in menu attr `close_on_select` closes it after a choice |
| `<.app_shell>` | a signed-in app's whole shell (see App shell): `nav` groups, `active`, `search` (a `<.command>` id), `person`, `environment`, `bar`/`more`, `wide`/`fill`; slots `<:header>` (`<.app_shell_heading icon title subtitle tip chevron>`), `<:phone_header>`, `<:footer_item id icon label navigate\|href\|phx-click>`, `<:account_item id icon navigate\|href method soon divider destructive>` |
| `<.command>` | `id` req. (hook), `label` (accessible name), `placeholder`, `<:trigger_label>`, `<:item id group icon shortcut>` that runs `phx-click`, or goes somewhere: `navigate`/`patch`/`href`, or `form` + `name` + `value` (submits that form); `shortcut="k"` (default, ⌘K toggles it; opening closes other dialogs) or `shortcut={nil}` (none - every palette but the search); `icon="hero-user-plus"` (the search row's heroicon, any `<.icon name>` class written out in full; default `hero-magnifying-glass`, `icon={nil}` none); `<:empty>` (default "No results found."); opt-in item attrs (items without them render as before): `description` (muted second line), `confirm` (`data-confirm`, closes only once accepted), `values={%{id: …}}`, `disabled` |
| `<.command on_search>` | search only the server can run (a directory, a remote API, a big table): `on_search="event"` pushes `%{"id" => id, "query" => text}` (trimmed, `search_debounce={250}`), the hook stops filtering; render the results as `<:item>`s and echo the text they answer as `query={@query}` (required; nil before the first search; assign it with the results, so with `start_async` when the answer lands); `<:hint>` before typing, a spinner while pending, `<:empty>` once answered; opening pushes `""` (drop the last results); `phx-target={@myself}` for a LiveComponent (items' `phx-click` go there too). Never hand-roll a search dialog (a `phx-change` input over a result list) |
| `<.tabs>` | `id` req., `<:tab label="..." checked>` slots with panel content |
| `<.tab_nav>` | `id` (hook), link tabs `<:tab navigate\|patch active count>`; overflow moves into a More menu that also takes `<:menu_item group icon active navigate\|patch>`; active tab always visible (too narrow for it + More: every tab folds into the menu and More names the active tab + count) |
| `<.breadcrumb>` | `<:item navigate={...}>` slots; last item without link = current page |
| `<.pagination>` | `page` `total_pages` + `path={fn p -> ... end}` or `event="..."` |
| `<.sidebar_layout>` / `<.sidebar_group>` | a plain sidebar layout (docs page, admin tool); `<:sidebar>` slot; items with `active`. A signed-in app uses `<.app_shell>` |
| `<.accordion>` | `id` req., `<:section title="..." open>` slots, `multiple`; opt in to a section card: `<:header>` (content above the rows in the same card: `card_title`, `card_description`, an action) and `flush` (rows edge to edge, 24px inset inside each row, 1px line under the header and between rows) |
| `<.avatar>` / `<.avatar_group>` | `src` or `fallback="JD"`, `shape`, size via `class` |
| `<.progress>` / `<.skeleton>` / `<.spinner>` | sized via `class` |
| `<.toaster>` | once in root layout (`position`, `rich_colors`, `close_button`); toasts via JS `toast()` / `toast.success()` / `toast.promise()` or LiveView `push_toast(socket, msg, type: :success)`; toasts render in the top layer and follow into an open sheet/dialog/drawer/command, so they show above it and stay clickable - never raise them with z-index |
| `<.flash>` / `<.flash_group>` | CoreComponents; renders as a Sonner toast (info = success check, clears after 5s, paused on hover/focus; error stays until closed), above open modals; `position` same values as `<.toaster>` (default `bottom-right`); keep Phoenix's `Layouts.flash_group`, don't override `flash/1` |
| `<.calendar>` | `id` required (hook) |
| `<.date_picker>` | `id` required (hook), `placeholder` |
| `<.date_range>` | `id` (hook), popover range; form-bind with `start_name`/`end_name` + `start`/`end` (ISO dates); `<:preset label start end>` or `<:preset label days={7}>` |
| `<.time_picker>` | `id` (hook), hour/minute(/second)/AM-PM columns in a popover; form-bind with `field` (or `name` + `value`: `Time` or ISO); posts 24-hour `HH:MM` (`HH:MM:SS` with `seconds`), casts to `:time`; `hour_cycle={24}`, `minute_step={15}`, `full_width` |
| `<.range_calendar>` | `id` (hook), inline range picker; `months`, `start`/`end`; form-bind with `start_name`/`end_name` (ISO dates) |
| `<.item>` / `<.item_group>` / `<.item_separator>` | row with `<:media variant="icon\|image">` `<:title>` `<:description>` `<:actions>` (`<:header>`/`<:footer>`); `variant="default\|outline\|muted"`, `size="default\|sm\|xs"`, `href`/`navigate` makes it a link |
| `<.attachment>` / `<.attachment_group>` / `<.attachment_action>` | file tile: `state="idle\|uploading\|processing\|error\|done"`, `size`, `orientation`, `<:media>` `<:title>` `<:description>` `<:actions>` `<:trigger label>` |
| `<.dropzone>` | `id` (hook), `upload={@uploads.x}`: a dashed `<label>` around the hidden `live_file_input` (the `phx-drop-target`; click / tap / Enter / Space opens the picker); title + description default from the upload ("One .csv file, up to 1 MB."; "Choose a file" on touch) or `<:title touch="…">` / `<:description>`; entries as `<.attachment>` tiles (uploading %, done, error), `on_cancel` (event or JS, pushes `%{"ref" => ref}`, `target`) adds remove; upload errors under the zone, `error_text={fn err -> text \| nil end}`; `<:entry :let={entry}>`; `size="default\|compact"` (one `h-9` row), `disabled`; plain forms: `name` + `accept` + `multiple` instead of `upload` |
| `<.message>` / `<.message_group>` | chat turn: `align="start\|end"`, `<:avatar>` `<:header>` `<:footer>`; `role="log"` on the group for live transcripts |
| `<.bubble>` / `<.bubble_group>` | `variant="default\|secondary\|muted\|tinted\|outline\|ghost\|destructive"`, `align`, `as="button"` for suggested replies, `<:reactions label>` |
| `<.marker>` | in-transcript status/note: `variant="default\|separator\|border"`, `status`, `shimmer`, `<:icon>` |
| `<.chip_row>` | `id` (hook), one line of `<:chip value on_remove remove_label>` (badge + ×); overflow collapses into "+N" (popover, each removable); `<:action>` stays visible; `variant="secondary\|outline"`; chips scale/fade in and out and neighbours slide - always pass `value` (it keys the chip) |
| `<.reveal>` | `open` (server-owned) or `id` + `client` with `<button data-reveal-toggle="id">`; slides a row 0fr↔1fr + opacity, 180ms; put spacing in `class`; keep the content rendered (a chip row: no `:if`) and let `open` drive it, so it collapses around the last chip |
| `<.empty>` | an empty state: `icon` (in a 40px muted circle) or `<:media>`, `title`, one muted line (inner block), `<:actions>`; `variant="card"` (on its own, bordered) or `"plain"` (inside a card or table) |
| `<.data_table>` | `id` (hook), `rows`, `row_id`, `row_href` (Cmd/Ctrl/middle click), `state` (a `DataTable.State`: sort arrows, ticks), `selectable`, `more`, `matching`, `all_matching`, `edge`, `noun={{"order", "orders"}}`, `active_id`, `scroll_key`, `target`; `<:col label sort class="w-32" align hide_below="md">`, `<:bulk>`, `<:empty title icon>`, `<:empty_action>`; sends `dt:sort` `dt:open` `dt:select` `dt:select_all` `dt:select_matching` `dt:clear` `dt:more` (see List and record pages) |
| `<.table_toolbar>` | `id`, `search`, `placeholder`, `shown`, `total`, `noun`, `views=[%{key, label, count, path, active, edited}]`, `menu=[%{key, label, group, icon, active, path \| click}]`, `chips=[{key, label} \| {key, label, :fixed}]` (`State.chips/3`), `sort` (`State.sort_value/1`), `sorts=[{label, "key:dir"}]` (first = default); `<:filter key label>` (one `<.select>`/`<.combobox>` named `key`), `<:more>`, `<:save>`; a form sending `dt:filter` (+ `dt:unfilter`, `dt:reset`) |
| `<.record_tabs>` | `id`, `tabs={[{key, label} \| {key, label, count}]}`, `active`; each tab sends `"tab"` with `%{"tab" => key}` (`event`, `target` to change); underlined, one tab stop, arrow keys |
| `<.table_card>` | a card of rows: `id`, `title`, `description`, `rows`, `row_id`, `row_class`, `grid` (e.g. `grid-cols-[minmax(0,1fr)_auto]`: side by side on phones too); `<:col :let label class align>`, `<:empty>`, `<:actions>`; labels as a header row from `sm`, rows stack on phones, the rightmost column right-aligned |
| `<.section_nav>` | `id` (hook), `sections=[{id, label} \| {id, label, group}]` (each an element with that id); `variant="side"` (default; give it the cards as its inner block: a list beside them from `lg`, pinned under the page header, "Filter sections" over 10) and `variant="select"` in `<.page_header>`'s `<:below>` (below `lg`, 44px options); marks the section in view, choosing one scrolls there |
| `<.time_field>` | `id` (hook), `field`, `label`, `minute_step` (15): a labelled full-width `<.time_picker>` ("Not set"), errors under it once used |
| `<.combobox>` / `<.select>` | `id` required (hook), `<:option value="..." count={n}>` slots; form-bind with `field={@form[:x]}` (or `name`/`value`); `multiple` = checkbox rows + Clear, value is a list, posts `x[]` (cleared posts `x=""`); `full_width` in sheets/compact forms; a single picker's `value=""` option is the choice for a blank value ("Default order", "Any") |
| `<.combobox create>` | lets people add a value the list lacks (an insurer, a tag): text no option label matches exactly (case/spaces ignored) shows a last `Add "…"` row (`create_label="Add \"%{value}\""`, `create_max={80}`); choosing it selects + posts the trimmed text (`multiple`: ticks it, stays open); `on_create="event"` also pushes `%{"id" => id, "value" => text}` - save the option there and re-render the slots. Never hand-roll an "Other…" text input next to a picker |
| `<.input_otp>` | `id` (hook), `length`, `group` |
| `<.carousel>` | `id` (hook), `<:slide>` slots |
| `<.resizable>` | `id` (hook), `<:start>` / `<:end_pane>` slots |

From your app's `CoreComponents` (delegating to `ShadcnDaisyui.CoreComponents`):
`<.button>` (variants + `navigate`), `<.input field={...}>`, `<.error>`, `<.header>`,
`<.table id rows>` with `<:col>` slots (`scroll`: fills a growing card, only the
body scrolls under a sticky header), `<.list>`, `<.icon name="hero-...">`, `<.flash>`,
`<.page_header crumbs back esc_back>` with `<:badge>` `<:actions>` `<:below>` (every page
in the shell starts with it), `<.sticky_top id>` (a pinned block of your own).

Not imported (Phoenix's `Layouts` defines its own): `<ShadcnDaisyui.Components.theme_toggle
light="shadcn" dark="shadcn-dark">` - system / light / dark; `<.app_shell>`'s account
menu already has one.

### App shell

- A signed-in app renders `<.app_shell>` in its `Layouts.app/1` (the signed-out
  pages keep a plain centered column). Wide screens (from 48rem): a 16rem sidebar
  that collapses to a 3rem icon rail (`data-sidebar` on `<html>`, Cmd/Ctrl+B, the
  grab strip and the "Collapse sidebar" row; remembered). Phones: a pinned top
  row (`<:phone_header>` + search), a bottom dock of four destinations plus More,
  and the More sheet (everything, the footer items, the account). Never a
  hamburger.
- `nav` is the navigation as your `Navigation` module returns it, already filtered
  by what the person may open: `[%{label: "Sales" | nil, items: [%{id: "orders",
  label: "Orders", short: "Orders", path: ~p"/orders", icon: "hero-shopping-cart"}]}]`
  (`short` = the dock label). `active` is this page's item id. `more` = the groups
  the More sheet lists (leave desktop-only pages out; default `nav`), `bar` = the
  dock's items (default: the first four of `more`).
- `#main` is the page's one scroll region: the page itself never scrolls. Pages
  keep a reading width (48rem; a page child's own `max-w-*`, e.g. a `max-w-md`
  form, wins); `wide` uses the full width (tables), and `fill`
  makes the content fill the window so a table body inside it scrolls instead:
  `<.data_table>` (a list page), or `<.table scroll>` in
  `<div class="card flex min-h-0 flex-1 flex-col overflow-hidden">`.
- Every page starts with `<.page_header>`: breadcrumb (from 48rem; group as text,
  then the page; on a record the list is a link and Esc goes there), the title,
  `<:badge>`, `<:actions>` (`size="sm"` buttons) and `<:below>`, pinned while
  `#main` scrolls. Keep a thin `page_header` in your `CoreComponents` that computes
  `crumbs` from your navigation and calls `ShadcnDaisyui.CoreComponents.page_header/1`.
- Search is a `<.command id="search">` next to the shell (`search="search"`):
  pages, then records. Other palettes (a brand switcher) take `shortcut={nil}`.
- App-specific things (brand pickers, permission checks, routes, copy) go in
  through the slots and attributes: `<:header>` (`<.app_shell_heading>`, or your
  own markup with `app-shell-label` on what the rail hides), `<:footer_item>`
  (What's new), `<:account_item>`s (Account, Notifications, then `divider` +
  `soon` Support / Feedback, then `divider destructive` Sign out last; the theme
  row closes the first section).
- Open the shell's dialogs with `JS.dispatch("shadcn:show-dialog", to: "#id")` or
  `show_modal("id")`; in an app shell page plain dialogs close on a backdrop click
  and every open dialog closes when LiveView navigates to another page.

### List and record pages

A list page: `<.page_header>`, `<.table_toolbar>`, then `<.data_table>`, in
`<.app_shell wide fill>`. What the table shows is a `ShadcnDaisyui.DataTable.State`:

```elixir
@opts [filters: %{"status" => "any"}, sorts: ~w(number customer total)]

def handle_params(params, _uri, socket) do
  state = State.from_params(params, @opts)  # sort, search, filters: in the URL
  {:noreply, assign(socket, state: state, rows: Orders.list(state))}
end

def handle_event("dt:sort", %{"key" => key}, socket),
  do: {:noreply, push_patch(socket, to: ~p"/orders?#{State.to_params(State.toggle_sort(socket.assigns.state, key), @opts)}")}

def handle_event("dt:filter", params, socket) do
  state = socket.assigns.state |> State.put_search(params["q"]) |> State.put_filters(params, ["status"], @opts)
  state = State.parse_sort(params["sort"], state, @opts)  # the value comes first
  {:noreply, push_patch(socket, to: ~p"/orders?#{State.to_params(state, @opts)}")}
end

def handle_event("dt:select", %{"id" => id} = p, socket),  # ticks: on the page, never in the URL
  do: {:noreply, update(socket, :state, &State.select(&1, id, p["shift"] == true, Enum.map(socket.assigns.rows, fn r -> r.id end)))}
```

- Events (each payload also has `"table" => id`): `dt:sort` `%{"key"}`, `dt:open`
  `%{"id"}` (push_navigate to the record; keep the list's params so its crumb goes
  back to the same view, and pass `active_id`), `dt:select` `%{"id", "shift"}`,
  `dt:select_all` (`State.select_all/2`), `dt:select_matching` (set your own
  `all_matching`), `dt:clear` (`State.clear/1`), `dt:more` (load the next page;
  `more` while there is one), `dt:filter` (the toolbar form: `q`, each filter,
  `sort`), `dt:unfilter` `%{"key"}`, `dt:reset`.
- `State.run(rows, state, spec)` searches, filters and sorts in memory (small
  tables); a database-backed table does the same in its query. `State.chips/3`
  gives the toolbar's chips; `State.keep_visible/2` drops ticks a filter hid.
- Columns: give each a width class (`w-32`; the table is `table-fixed`, cells
  truncate), `hide_below` the less important ones on phones, and leave alignment
  alone - the rightmost column shown is right-aligned at every width.
- A record page: `<.page_header>` (crumbs back to the list, `esc_back={!@dirty}`,
  `<:below>` with `<.record_tabs>` and the `variant="select"` section nav), then the
  edit form with `<.section_nav>` around its cards. Cancel with unsaved changes:
  `push_show_modal(socket, "discard")`.

### Form components (`ShadcnDaisyui.CoreComponents`)

Always bind form controls to changesets via `Phoenix.HTML.FormField`:

```heex
<.form for={@form} id="user-form" phx-change="validate" phx-submit="save">
  <.input field={@form[:email]} type="email" label="Email" />
  <.input field={@form[:role]} type="select" label="Role" options={["admin", "member"]} />
  <.input field={@form[:active]} type="checkbox" label="Active" />
  <.button phx-disable-with="Saving…">Save</.button>
</.form>
```

- NEVER write raw `<input>` / `<select>` / `<textarea>` inside a `<.form>`.
- Errors render automatically from the field (gated on `used_input?` like Phoenix 1.8).
- `phx.gen.live` / `phx.gen.html` generated templates work unmodified.
- See `usage-rules/forms.md` for the full form rules.

### Class-only recipes (no wrapper - use these exact classes)

| Need | Recipe |
|---|---|
| Tabs | `<div role="tablist" class="tabs tabs-box w-fit">` + `<input type="radio" name="…" class="tab" aria-label="…">` |
| Static table | `<div class="card w-full overflow-hidden"><table class="table">…` |
| Data table (sortable/faceted/paged) | Not a recipe: `<.table_toolbar>` + `<.data_table>` (see List and record pages). |
| Sheet sections (raw HTML) | `<dialog class="sheet">` with direct children `.sheet-header` (close button, `h3.sheet-title`, description, `.sheet-header-content`), `.sheet-body` (one wrapper `div` inside), `.sheet-footer`; drawer: `.drawer-handle` `.drawer-header` `.drawer-body` `.drawer-footer` |
| Modal/dialog | native `<dialog id="d" class="modal"><div class="modal-box">…`, opened by `<button commandfor="d" command="show-modal">` (no inline JS); backdrop: `<form method="dialog" class="modal-backdrop"><button>close</button></form>` |
| Tooltip | `<div class="tooltip" data-tip="…">` wrapping the trigger |
| Dropdown | `<div class="dropdown">` + `tabindex="0"` trigger + `<ul class="dropdown-content menu z-50 …">` |
| Context menu | trigger `<div data-context-menu-trigger>` + `<ul data-context-menu class="context-menu hidden">`; needs `id` + `phx-hook="ShadcnContextMenu"` (one per page) |
| Progress | `<progress class="progress w-full" value="60" max="100">` |
| Skeleton | `<div class="skeleton h-4 w-48">` |
| Spinner | `<span class="loading loading-spinner">` |
| Kbd | `<kbd class="kbd kbd-sm">⌘K</kbd>` |
| Stat blocks | `<div class="stats w-full"><div class="stat"><div class="stat-title">…` |
| Steps | `<ul class="steps"><li class="step step-primary">…` |
| Avatar | `<div class="avatar"><div class="w-10 rounded-full"><img …></div></div>` |
| Breadcrumbs | `<div class="breadcrumbs text-sm"><ul><li>…` |
| Toggle/switch | `<input type="checkbox" class="toggle">` (forms: use `<.input type="checkbox">`) |
| Checkbox | `<input type="checkbox" class="checkbox">` |
| Radio | `<input type="radio" class="radio">` |
| Range slider | `<input type="range" class="range">` |
| Inline code | `<code class="rounded bg-muted px-1.5 py-0.5 font-mono text-sm">` |
| Headings | `text-3xl font-bold tracking-tight` (h1), `text-xl font-semibold tracking-tight` (h2, often with `border-b border-border pb-2`) |
| Secondary text | `text-sm text-muted-foreground` |
| Page hero | `<div class="hero">`, navbar `<div class="navbar">`, footer `<footer class="footer">` |
| Collapsing row | `<div class="reveal" data-open><div class="reveal-track"><div>…</div></div></div>` (toggle `data-open`; `<button data-reveal-toggle="id">` for dead views) |
| Bottom dock (compact nav) | `<div class="dock"><button class="dock-active"><span class="hero-…"></span><span class="dock-label">…` (3-5 items; mark the current route's button `dock-active`) |

Browse the full gallery (95 components) in the docs site (`demo/`) or
`/docs/components/:slug` - every entry has copy-pasteable markup.

## Theme tokens

- Theme activation: `<html data-theme="shadcn">` (light) / `"shadcn-dark"` (dark).
  Brand themes (e.g. `data-theme="acme"`) override the same tokens - never bypass them.
- Surfaces (one role each, as in shadcn): page `bg-base-100` / `bg-background`;
  cards and opaque fills inside a card (sticky table header, sticky footer bar)
  `bg-card`; overlays (sheets, dialogs, popovers, dropdown/command content)
  `bg-popover` + `text-popover-foreground`; subtle insets `bg-muted`; hover and
  selected rows/items `bg-accent` (or `bg-muted`); borders `border-border`.
  `bg-base-200` is an alias of muted and `border-base-300` of the border colour -
  in dark mode base-300 is translucent (white/10%), so never use `bg-base-300` as
  a fill. Never paint a card or overlay `bg-base-100` - in dark mode the page is
  darker than cards and popovers.
- A sticky `<thead>` inside a card needs `bg-card` (the table header has no fill
  of its own).
- Stacking: sticky headers / toolbars / bottom bars `z-10`, floating content
  (menus, popovers, picker panels) `z-50`, modals in the top layer, toasts and
  flashes in the top layer above modals (the package handles it). Never use
  arbitrary z values (see `usage-rules/styles-shape-elevation.md`).
- Text: default foreground inherits; secondary text `text-muted-foreground`;
  destructive `text-destructive` / `text-error`.
- Action colors: `btn-primary`, `btn-secondary`, `badge-error`, etc. - daisyUI semantic
  modifiers, all mapped to the theme.
- Status colors: `info`, `success`, `warning`, `error` exist (`alert-success`,
  `text-warning`, …) - use them rather than green/yellow/red utilities.
- Radius comes from the theme (`rounded-md` fields, `rounded-lg` boxes, `rounded-xl`
  cards). Never hardcode pixel radii.
- Dark mode: the `dark:` variant works (mapped to `[data-theme=…-dark]`), but prefer
  tokens that adapt automatically; only use `dark:` for genuinely asymmetric cases.
- See `usage-rules/theming.md` for creating/overriding brand themes.

## Design guidelines

Platform-portable rules (web + native iOS/iPadOS). Load-bearing values:

- Spacing: 4px grid, blessed steps only - 4/8/12/16/24/32/48 (`gap-1/2/3/4/6/8/12`).
  Icon↔label 8px, form fields 16px apart, card interior 24px, page sections 24-48px.
- Window size classes: compact < 640px (phones), medium 640-1023, expanded ≥ 1024.
  Mobile-first: unprefixed = compact, enhance with `sm:`/`lg:`. One column on compact.
- Content widths: shell `max-w-7xl`, prose ~65ch, forms `max-w-md`-`max-w-lg`.
  Gutters `px-4 sm:px-6 lg:px-8`.
- Navigation: compact = bottom dock (3-5 destinations), wider = sidebar (`<.app_shell>`:
  16rem from 48rem, collapsing to a 3rem rail).
  Primary destinations never hide behind a hamburger. Breadcrumbs ≥ medium only.
- Touch targets: 44pt / 2.75rem minimum effective hit area on touch surfaces.
  `h-9` controls are desktop-fine; compact primary actions use `btn-lg` full-width;
  checkboxes/radios always wrapped in a tappable label row.
- Type ramp: `text-3xl` bold page title, `text-xl` semibold section, `text-base`
  prose, `text-sm` controls/UI (default), `text-xs` labels. Weights: 500 controls,
  600 titles, 700 page title only.
- Motion: 150ms micro states, ~180ms small surfaces, 300ms sheets/drawers;
  opacity/transform only, except the 180ms row reveal (`<.reveal>`); respect
  reduced motion.
- Hover is an enhancement, never a requirement. Disabled = variant colors at 50%
  opacity (never grey-washed).

Full rules (each file: terse `## Rules` + reference tables, `[web]`/`[ios]` tags):

- See `usage-rules/foundations-platforms.md` - dual units, HIG arbitration, token→SwiftUI map
- See `usage-rules/foundations-accessibility.md` - contrast, focus, labels, writing basics
- See `usage-rules/foundations-layout.md` - breakpoints, size classes, scaffold
- See `usage-rules/foundations-spacing.md` - grid, blessed steps, standards table
- See `usage-rules/foundations-navigation.md` - nav per size class, destination limits
- See `usage-rules/foundations-interaction.md` - state ladder, touch targets, dismissal
- See `usage-rules/styles-color.md` - token usage semantics, brand splash rules
- See `usage-rules/styles-typography.md` - type ramp, iconography
- See `usage-rules/styles-shape-elevation.md` - radius roles, elevation ladder
- See `usage-rules/styles-motion.md` - durations, easings, patch guard

## Setup invariants (do not undo)

- `app.css` keeps: `@plugin "…daisyui" { themes: false; }`, the shadcn-daisyui CSS
  import, `@source` covering `deps/shadcn_daisyui/lib`, and the
  `@custom-variant dark (…)` line.
- `app.js` keeps the `Hooks` import and spreads them into the LiveSocket. The
  shell's behaviour (`shadcn:toggle-sidebar`, `shadcn:show-dialog`, Cmd/Ctrl+B,
  closing dialogs on navigation) comes with that import - don't re-add an app
  copy of it or app-specific events for it.
- The root layout keeps its pre-paint `<script nonce={assigns[:csp_nonce]}>` in
  `<head>`: it sets `data-theme` through the `theme-transition` guard and
  `document.documentElement.dataset.sidebar` from localStorage `shadcn:sidebar`
  (`"collapsed"` or `"open"`), so the first paint already has the right theme and
  sidebar. `mix shadcn_daisyui.install` / `mix shadcn_daisyui.upgrade` add the
  sidebar line.
- The app's `CoreComponents` module delegates to `ShadcnDaisyui.CoreComponents`;
  override individual functions there if the app needs to, don't fork wholesale.
