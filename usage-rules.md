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
- A confirmation (delete, remove, discard, sign out) is `<.alert_dialog>`: the
  question as the title, naming the object, and an action that says what it
  does (`variant="destructive"` when it destroys). `data-confirm` (dropdown and
  command items' `confirm`) asks in the same dialog because `app.js` calls
  `initConfirmDialog()`. Never confirm with a plain `<.dialog>` (a backdrop
  click closes it), a hand-rolled modal or the browser's bare `confirm()`.
- A file upload is `<.dropzone upload={@uploads.x}>` (`size="compact"` in tight
  forms); the picked files show under it as `<.attachment>` tiles. Never show a
  bare `<.live_file_input>` or hand-roll a drop area (see `usage-rules/forms.md`).
- Code, logs, payloads (webhook / API bodies, import error reports) and
  before/after diffs are `<.code_block>` (`lines` with `:added` / `:removed`
  for a diff, `size="sm"` in a card or chat reply). Never hand-roll a `<pre>`, a
  copy button, line numbers or diff colours.
- A chart is `<.chart>` (any Chart.js type: the server sends an ordinary
  config) and a headline figure is `<.number_card>`, from the optional chart
  kit (`import { ChartHooks } from "shadcn_daisyui/charts"`). Pick the form by
  the job (see Charts). Never write a chart hook of your own, load Chart.js
  from a CDN, hand-draw a chart (SVG, divs, `.chart-bar`), or put colours in a
  chart's config - series take `chart-1…5` in order, or a dataset's `color`
  token.
- An AI chat page is a `<.message_scroller>` of `<.message>` / `<.bubble>` /
  `<.marker>` rows, `<.trace>` for the assistant's steps, tool calls and sources,
  and the `<.prompt_input>` composer (see AI chat page). Never hand-roll a chat
  scroller (scrollTop code, a "scroll to bottom" button), a step list (a spinner
  with "Thinking…" lines) or a composer (a textarea with an Enter handler, a
  Send/Stop swap).
- Interactive components (combobox, select, date picker, time picker, time field,
  calendar, range calendar, OTP, carousel, resizable, command, context-menu,
  toaster, tab nav, chip row, page header, data table, section nav, dropzone,
  code block, message scroller, prompt input) REQUIRE a
  unique `id` attribute and the JS hooks
  registered on the LiveSocket (`import { Hooks } from "shadcn_daisyui"` …
  `hooks: { ...Hooks }`). Charts (`<.chart>`, a `<.number_card>`'s trend) need
  `id` and the chart kit's hooks too: `hooks: { ...Hooks, ...ChartHooks }`.
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
| `<.alert_dialog>` | a confirmation: `id` req., `<:title>` (req., the question) `<:description>` (the consequence), `<:action variant="default\|destructive">` (req.; a button running `phx-click`, `type="submit" form="…"`, or a link with `navigate`/`href` + `method`; choosing it closes the dialog, `close={false}` leaves that to the server) and Cancel (`cancel="Keep editing"`, focused on open); `<:trigger>`, `<:media>` (icon `class="size-8"`), `size="sm"`, `show` + `on_close`; a backdrop click doesn't close it, Esc cancels |
| styled `data-confirm` | `initConfirmDialog()` once in `app.js` (`import { Hooks, initConfirmDialog } from "shadcn_daisyui"`; dead views: `initShadcnDaisyui({ confirm: true })`): every `data-confirm` (dropdown / command items' `confirm`, links, buttons) asks in an alert dialog, then the click runs as before; per element `data-confirm-description`, `data-confirm-action="Delete report"`, `data-confirm-cancel`, `data-confirm-variant` (a destructive item or `btn-error` button gets a destructive action); `confirmDialog(message, opts)` returns a promise of the answer |
| opening from the server | `push_show_modal(socket, id)` / `push_hide_modal(socket, id)` (opens each time it's pushed, even after the person closed it), or `show={@open?}` + `on_close="event"` (or a JS) on `<.dialog>` / `<.alert_dialog>` / `<.sheet>` / `<.drawer>` / `<.command>`: open on mount and whenever `show` turns true; `on_close` runs when the person closes it (Esc, backdrop, a close or Cancel button) - set the assign false there; closing from the server doesn't run it |
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
| `<.toaster>` | Sonner, as shadcn ships it; once in root layout (`position`, `rich_colors`, `close_button`, `expand`, `invert`, `duration`, `offset`, `toast_options`, `<:success_icon>`…`<:close_icon>` slots); toasts via JS `toast()` / `toast.success()` / `toast.loading()` / `toast.promise()` / `toast.custom()` / `toast.dismiss()` or LiveView `push_toast(socket, msg, type: :success)` (`id` to update one in place, `action`/`cancel`, `icon: "hero-…"`, `rich_colors`, `invert`, `duration: :infinity`); toasts render in the top layer and follow into an open sheet/dialog/drawer/command, so they show above it and stay clickable - never raise them with z-index or restyle them with your own classes |
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
| `<.chart>` | the chart kit (needs `ChartHooks` from `shadcn_daisyui/charts`): `id`, `label` (accessible name + caption of the hidden table of numbers), `config` (a Chart.js config as maps: `type`, `data`, `options`; labels formatted on the server); `on_click="event"` pushes `%{"id", "key", "series", "index"}` (`key` from `data.keys` or the label, `series` the clicked dataset's `key` or label), `target`; `format={fn n -> text end}` for the table; `canvas_class="h-80"` (16rem default; horizontal bars size to their rows). Kit keys: a dataset's `color` (`"chart-3"`, `"muted-foreground"`, `"chart-1/35"` = 35% opacity, or a list per bar), `key`; `data.keys`; `options.plugins.endLabels.labels` (text at each bar's end, moved above the bars on narrow screens; `position: "above"` keeps it above at every width); `options.plugins.segmentLabels: true` (stacked bars: each part's value inside it where it fits, none where it doesn't; a one-row stack's legend gives every part's number, "Completed 61"), `segmentLabels: "legend"` (the legend's numbers only, nothing on the bar). Values in tooltips follow the value axis's `ticks.format` |
| `<.number_card>` | `id`, `label`, `value` (formatted), inner block = the line under it ("Margin $14,700 (35%)"), `trend` (numbers or `{label, n}`, oldest first, `nil` bridged; drawn faint behind the number and badges - needs `ChartHooks`), `color` (trend token, default `chart-1`); opt-in: `help` (a ? beside the label: what it counts, in plain words; hover, focus or tap), `<:change vs="vs PP" by="+$8,000" percent="+24%" direction="up\|down\|flat" good="up\|down\|none">` (badges against another period: green good news, red bad, neutral flat), `navigate`/`patch`/`href` (the whole card is a link; the label is its text, the help stays its own button) |
| `<.code_block>` | `id` (hook), `code` (a string: split into lines, escaped; no syntax highlighting) or `lines` (strings, `{:added \| :removed \| :highlighted, text}`, or `Phoenix.HTML.raw/1` pre-highlighted lines - build the list in Elixir, a literal `{` in a HEEx attribute opens an expression); `title` + `icon` (header; without one Copy floats top-end), `line_numbers` `start_line`, `highlight={[42, 50..52]}`, `wrap`, `content_class="max-h-72"` (scrolls inside, edges fade), `variant="default\|destructive"`, `size="default\|sm"`, `label` (names the focusable scroll region), `copy={false}`, `copy_text`; `<:actions>` (`class="code-block-action"` 24px icon buttons, `aria-pressed` for a toggle), `<:footer>`; Copy copies the plain text (no numbers or markers) |
| `<.data_table>` | `id` (hook), `rows`, `row_id`, `row_href` (Cmd/Ctrl/middle click), `state` (a `DataTable.State`: sort arrows, ticks), `selectable`, `more`, `matching`, `all_matching`, `edge`, `noun={{"order", "orders"}}`, `active_id`, `scroll_key`, `target`; `<:col label sort class="w-32" align hide_below="md">`, `<:bulk>`, `<:empty title icon>`, `<:empty_action>`; sends `dt:sort` `dt:open` `dt:select` `dt:select_all` `dt:select_matching` `dt:clear` `dt:more` (see List and record pages) |
| `<.table_toolbar>` | `id`, `search`, `placeholder`, `shown`, `total`, `noun`, `views=[%{key, label, count, path, active, edited}]`, `menu=[%{key, label, group, icon, active, path \| click}]`, `chips=[{key, label} \| {key, label, :fixed}]` (`State.chips/3`), `sort` (`State.sort_value/1`), `sorts=[{label, "key:dir"}]` (first = default); `<:filter key label>` (one `<.select>`/`<.combobox>` named `key`), `<:more>`, `<:save>`; a form sending `dt:filter` (+ `dt:unfilter`, `dt:reset`) |
| `<.record_tabs>` | `id`, `tabs={[{key, label} \| {key, label, count}]}`, `active`; each tab sends `"tab"` with `%{"tab" => key}` (`event`, `target` to change); underlined, one tab stop, arrow keys |
| `<.table_card>` | a card of rows: `id`, `title`, `description`, `rows`, `row_id`, `row_class`, `grid` (e.g. `grid-cols-[minmax(0,1fr)_auto]`: side by side on phones too); `<:col :let label class align>`, `<:empty>`, `<:actions>`; labels as a header row from `sm`, rows stack on phones, the rightmost column right-aligned; row actions are a ⋯ `<.dropdown_menu align="end">` (icon trigger, `aria-label="Actions for …"`) in the last column - the card doesn't clip, so it opens in full over the card's edge, on the last row too; rows are one height (a row of text's) whether or not they hold a ⋯ menu, a small button or a badge, and the `<:empty>` row matches them, so cards side by side line up (taller content - two lines - still grows its row) |
| `<.section_nav>` | `id` (hook), `sections=[{id, label} \| {id, label, group}]` (each an element with that id); `variant="side"` (default; give it the cards as its inner block: a list beside them from `lg`, pinned under the page header, "Filter sections" over 10) and `variant="select"` in `<.page_header>`'s `<:below>` (below `lg`, 44px options); marks the section in view, choosing one scrolls there |
| `<.time_field>` | `id` (hook), `field`, `label`, `minute_step` (15): a labelled full-width `<.time_picker>` ("Not set"), errors under it once used |
| `<.message_scroller>` | `id` (hook), `items` (a list keyed by `item.id`, or a stream), `item_id`, `anchor={fn item -> bool end}` (turn anchors: the reader's own messages), `busy` (`aria-busy` on the log while a reply streams), `default_position="end\|start\|last-anchor"`, `follow` (true), `peek` (64), `label` ("Messages"), `button="end\|start\|both\|none"`; the inner block renders one row (`:let={item}`, `{dom_id, item}` for a stream), `<:above>` / `<:below>` rows inside the log (load earlier, a typing marker); fills its parent; follows a streaming reply only at the live edge, a new anchor moves near the top, prepended rows keep the reader's place; `shadcn:scroll-to` (`detail: %{to: "end" \| "start" \| dom_id}`) jumps (see AI chat page) |
| `<.trace>` / `<.trace_line>` | the assistant's work, one row each: `<:line status="running\|pending\|error" icon="hero-…" description href\|navigate\|patch target>` (done without a status; the title is the inner block, one truncated line; description never truncates); a row with detail is `<.trace_line id status open>` in the inner block with `<:icon>`, `<:description>`, `<:detail>` (a disclosure button, `id` required; rows nest); status is colour and motion only - word the title ("Running mix test", "Failed to send") |
| `<.prompt_input>` | `id` (hook), `field` (or `name`/`value`), `placeholder`, `label` ("Message"), `busy` (the button is Stop, Enter waits), `on_stop` ("stop", or a JS), `target`, `upload` + `on_cancel` + `error_text` (attach button, `<.attachment>` tiles above the text, files pasted or dropped in), `disabled`, `<:suggestion value send={false} variant>` (`<.bubble as="button">` chips that fill and send, or your own `phx-click`), `<:tools>`; Enter sends, Shift+Enter adds a line (never while an IME composes); grows to 12rem; clears once sent - reset your form too |
| `<.combobox>` / `<.select>` | `id` required (hook), `<:option value="..." count={n}>` slots; form-bind with `field={@form[:x]}` (or `name`/`value`); `multiple` = checkbox rows + Clear, value is a list, posts `x[]` (cleared posts `x=""`); `full_width` in sheets/compact forms; a single picker's `value=""` option is the choice for a blank value ("Default order", "Any") |
| `<.combobox create>` | lets people add a value the list lacks (an insurer, a tag): text no option label matches exactly (case/spaces ignored) shows a last `Add "…"` row (`create_label="Add \"%{value}\""`, `create_max={80}`); choosing it selects + posts the trimmed text (`multiple`: ticks it, stays open); `on_create="event"` also pushes `%{"id" => id, "value" => text}` - save the option there and re-render the slots. Never hand-roll an "Other…" text input next to a picker |
| `<.input_otp>` | `id` (hook), `length`, `group` |
| `<.carousel>` | `id` (hook), `<:slide>` slots |
| `<.resizable>` | `id` (hook), `<:start>` / `<:end_pane>` slots |

From your app's `CoreComponents` (delegating to `ShadcnDaisyui.CoreComponents`):
`<.button>` (variants + `navigate`), `<.input field={...}>`, `<.error>`, `<.header>`,
`<.table id rows>` with `<:col>` slots (`scroll`: fills a growing card, only the
body scrolls under a sticky header; it scrolls sideways, so a menu in a cell is
cut off - row actions are `<:action>` links, a ⋯ menu per row is a `<.table_card>`), `<.list>`, `<.icon name="hero-...">`, `<.flash>`,
`<.page_header crumbs back esc_back>` with `<:badge>` `<:actions>` `<:below>` (every page
in the shell starts with it), `<.sticky_top id>` (a pinned block of your own).

Not imported (Phoenix's `Layouts` defines its own): `<ShadcnDaisyui.Components.theme_toggle
light="shadcn" dark="shadcn-dark">` - system / light / dark; `<.app_shell>`'s account
menu already has one.

### App shell

- A signed-in app renders `<.app_shell>` in its `Layouts.app/1` (the signed-out
  pages keep a plain centered column). Wide screens (from 48rem): a 16rem sidebar
  that collapses to a 3rem icon rail (`data-sidebar` on `<html>`, Cmd/Ctrl+B, the
  grab strip and the "Collapse sidebar" row; remembered). Its navigation keeps
  its scroll position from page to page and shows the active item - never save
  or restore the sidebar's scroll yourself. Phones: a pinned top
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
- A dialog, alert dialog, sheet, drawer or command can sit anywhere in a
  page, a direct child included: the reading width never reaches it, so it
  opens over the whole window as it does outside the shell. Never wrap one in
  a `contents` div to get that.
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

### AI chat page

An assistant's page: `<.page_header>`, a `<.message_scroller>` over the
conversation, then the `<.prompt_input>` composer, in `<.app_shell fill>` (the
scroller takes the height between the header and the composer; from a record
page, put the same scroller and composer in a `<.sheet>`).

```heex
<.app_shell nav={@nav} active="assistant" fill>
  <.page_header>Assistant</.page_header>
  <.message_scroller
    id="chat"
    items={@streams.messages}
    anchor={fn {_id, m} -> m.role == :user end}
    busy={@reply != nil}
    default_position="last-anchor"
    :let={{_id, m}}
  >
    <:above :if={@older != []}>
      <.button variant="ghost" size="sm" phx-click="load-earlier">Load earlier messages</.button>
    </:above>
    <.message :if={m.role == :user} align="end">
      <.attachment :for={f <- m.files} size="sm">…</.attachment>
      <.bubble>{m.text}</.bubble>
    </.message>
    <.message :if={m.role == :assistant}>
      <:header>Assistant</:header>
      <.trace :if={m.steps != []}>
        <:line :for={s <- m.steps} status={s.status} icon={if s.status == "running", do: "hero-sparkles", else: "hero-check"}>
          {s.text}
        </:line>
      </.trace>
      <.bubble :if={m.text != ""} variant="ghost">{m.text}</.bubble>
      <:footer :if={m.sources != []}>From the customer file and the conversation.</:footer>
    </.message>
  </.message_scroller>
  <.form for={@form} id="chat-form" phx-change="validate" phx-submit="send">
    <.prompt_input id="composer" field={@form[:text]} busy={@reply != nil} on_stop="stop"
      upload={@uploads.files} on_cancel="cancel-upload">
      <:suggestion :if={@new_chat?} value="What's overdue?">Overdue orders</:suggestion>
    </.prompt_input>
  </.form>
</.app_shell>
```

Streaming a reply from LiveView:

```elixir
def handle_event("send", %{"prompt" => %{"text" => text}}, socket) do
  if socket.assigns.reply, do: {:noreply, socket}, else: {:noreply, ask(socket, String.trim(text))}
end

defp ask(socket, text) do
  question = %{id: Ecto.UUID.generate(), role: :user, text: text, files: consume_files(socket)}
  reply = %{id: Ecto.UUID.generate(), role: :assistant, text: "", steps: [], sources: []}
  lv = self()

  socket
  |> stream_insert(:messages, question)   # an anchor: the scroller moves it to the top
  |> stream_insert(:messages, reply)
  |> assign(reply: reply, form: to_form(%{"text" => ""}, as: :prompt))
  |> start_async(:reply, fn ->
    Assistant.ask(text, fn event -> send(lv, {:reply, reply.id, event}) end)
  end)
end

# a step started or done, a chunk of text: update the reply in place
def handle_info({:reply, id, event}, %{assigns: %{reply: %{id: id} = reply}} = socket) do
  reply = apply_event(reply, event)
  {:noreply, socket |> assign(reply: reply) |> stream_insert(:messages, reply)}
end

def handle_info({:reply, _id, _event}, socket), do: {:noreply, socket}  # arrived after Stop

def handle_async(:reply, {:ok, sources}, socket),
  do: {:noreply, finish(socket, %{socket.assigns.reply | sources: sources})}

def handle_event("stop", _params, socket),
  do: {:noreply, socket |> cancel_async(:reply) |> finish(socket.assigns.reply)}

defp finish(socket, reply), do: socket |> assign(reply: nil) |> stream_insert(:messages, reply)
```

- Rows: the reader's messages are `align="end"` default bubbles and the turn
  anchors; the assistant's are `variant="ghost"` (unframed text) under a
  `<:header>` naming it. Status inside the conversation ("Thinking…" before the
  first step, "Stopped") is a `<.marker status>` or the message's footer.
- Steps: while it works, a `<.trace>` of the real work (a sparkle on the
  running step, a check on the done ones) - never a bare spinner or filler
  steps. When it's done, fold them into one `<.trace_line>` ("Worked through 3
  steps", the seconds as its description) with the steps as its `<:detail>`,
  and the sources into another (link rows). Tool calls are `<.trace_line>`s
  with their input and output as detail. Say where an answer came from under
  it, in the message footer ("From the customer file and the conversation.").
- Streaming: `stream_insert` the question and an empty reply, then the reply
  again as each step or chunk arrives (batch tokens: one update every 50-100ms,
  not one per token). `busy` - `aria-busy` on the log, Stop in the composer -
  holds from the question until the reply is done or stopped. Stop is
  `cancel_async/2`; drop the chunks already in the mailbox after it.
- History: a saved conversation opens at its last question
  (`default_position="last-anchor"`); older messages load above with
  `stream(socket, :messages, Enum.reverse(page), at: 0)` (the reader keeps
  their place); a new conversation is `stream(socket, :messages, [], reset: true)`.
- Composer: reset the form in the submit handler and ignore a send while busy;
  files consumed on send show on the question as `<.attachment>`s. Offer
  suggestions while they help (a new conversation), not under every reply.

### Charts

The chart kit is optional: `import { ChartHooks } from "shadcn_daisyui/charts"`
and `hooks: { ...Hooks, ...ChartHooks }` (Chart.js ships inside the package, no
CDN). Pick the form by the data's job, then build an ordinary Chart.js config in
Elixir (labels formatted, numbers raw):

| Job | Form |
|---|---|
| One number, maybe its trend | `<.number_card trend={…}>` - never a one-bar chart |
| Change over time | `type: "line"`; vertical bars (`"bar"`) for days or weeks |
| A ranking / leaderboard | horizontal bars, longest first, labelled at the end |
| Progress through states | one stacked bar, axes hidden, the rest a grey track; counts on the parts with `segmentLabels`, or only in the legend with `segmentLabels: "legend"` |
| Part to whole (≤ 5 parts) | `type: "doughnut"` |
| A few series compared | grouped bars or lines, one dataset each (≤ 5) |

```elixir
# a leaderboard: sorted on the server; the margin is the darker part of each sale
%{
  type: "bar",
  data: %{
    labels: Enum.map(people, & &1.name),
    keys: Enum.map(people, & &1.id),              # sent as "key" with a click
    datasets: [
      %{label: "Margin", key: "margin", data: Enum.map(people, & &1.margin), color: "chart-1"},
      %{label: "Rest of the sale", key: "rest", data: Enum.map(people, &(&1.sale - &1.margin)), color: "chart-1/35"}
    ]
  },
  options: %{
    indexAxis: "y",
    scales: %{x: %{stacked: true, display: false, ticks: %{format: %{style: "currency", currency: "USD", maximumFractionDigits: 0}}},
              y: %{stacked: true}},
    plugins: %{endLabels: %{labels: Enum.map(people, & &1.summary)}}   # "$24,500 · 38% margin · 2 for 3"
    # endLabels position: "above" puts each name and label above its bar at every width
  }
}

# a progress row: one label, a dataset per state, the axes hidden, x max = the total
%{
  type: "bar",
  data: %{labels: ["Today"], datasets: [
    %{label: "Resulted", key: "resulted", data: [14], color: "chart-1"},
    %{label: "Needs a result", key: "needs_result", data: [3], color: "chart-1/65"},
    %{label: "In progress", key: "in_progress", data: [4], color: "chart-1/35"},
    %{label: "Still to come", key: "to_come", data: [9], color: "muted-foreground/25"}
  ]},
  options: %{
    indexAxis: "y",
    scales: %{x: %{stacked: true, display: false, max: 30}, y: %{stacked: true, display: false}},
    plugins: %{segmentLabels: true}   # each part's count on it where it fits, and in the legend ("Resulted 14")
  }
}
```

```heex
<.chart id="leaderboard" label="Sales by person, this week" config={@leaderboard} on_click="open_person" />
```

- Clicks: `handle_event("open_person", %{"key" => id}, socket)` (a progress
  part's state is `"series"`); open the detail in a `<.sheet>`. In a
  LiveComponent pass `target={@myself}`.
- Updates: assign a new config; the hook moves the same chart to the new data.
- Counts on a progress row's parts: `plugins: %{segmentLabels: true}`. Each
  part shows its value where the text fits inside it (a part too narrow shows
  none, never a number spilling over), and the legend gives every part's
  number ("Resulted 14"). `plugins: %{segmentLabels: "legend"}` gives the
  legend the numbers and leaves the bar bare (a slim row, a bar that should
  stay quiet). Never hand-draw numbers on bars or write counts into the
  dataset labels yourself.
- Never colours, fonts or grid styling in `options`: the theme sets them and
  redraws on a theme change. Five series at most (fold the rest into "Other");
  `color: "muted-foreground"` on the others when one series is the point.
- Put each chart in a card (`card_title` says what, `card_description` the
  period). `label` is required: it names the chart and captions the hidden
  table of its numbers; `format` writes them (`&money/1`).
- See `usage-rules/styles-charts.md` for the full rules.

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
| Static table | `<div class="card w-full overflow-hidden"><table class="table">…` (the card clips, for its corners: no menus in cells - a row with a ⋯ menu is a `<.table_card>`) |
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

Browse the full gallery (100 components) in the docs site (`demo/`) or
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
- See `usage-rules/styles-charts.md` - the form for each job, series colours, marks, labels

## Setup invariants (do not undo)

- `app.css` keeps: `@plugin "…daisyui" { themes: false; }`, the shadcn-daisyui CSS
  import, `@source` covering `deps/shadcn_daisyui/lib`, and the
  `@custom-variant dark (…)` line.
- `app.js` keeps the `Hooks` import and spreads them into the LiveSocket. The
  shell's behaviour (`shadcn:toggle-sidebar`, `shadcn:show-dialog`, Cmd/Ctrl+B,
  closing dialogs on navigation, keeping the sidebar's scroll position) comes
  with that import - don't re-add an app
  copy of it or app-specific events for it. It also calls `initConfirmDialog()`
  (styled `data-confirm`); add the call if it's missing, never remove it. An
  app with charts also imports `ChartHooks` from `"shadcn_daisyui/charts"` and
  spreads them beside `Hooks` (dead views: `initCharts()`).
- The root layout keeps its pre-paint `<script nonce={assigns[:csp_nonce]}>` in
  `<head>`: it sets `data-theme` through the `theme-transition` guard and
  `document.documentElement.dataset.sidebar` from localStorage `shadcn:sidebar`
  (`"collapsed"` or `"open"`), so the first paint already has the right theme and
  sidebar. `mix shadcn_daisyui.install` / `mix shadcn_daisyui.upgrade` add the
  sidebar line.
- The app's `CoreComponents` module delegates to `ShadcnDaisyui.CoreComponents`;
  override individual functions there if the app needs to, don't fork wholesale.
