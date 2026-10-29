# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
(0.x: minor versions may contain breaking changes, noted explicitly).

## [Unreleased]

### Added

- **`options.plugins.segmentLabels: "legend"`** gives a one-row stacked bar
  (a progress row) each part's count in its legend ("Completed 61") without
  drawing numbers inside the parts - for a slim row, or a bar that should
  stay bare. The legend's numbers follow the value axis's `ticks.format` and
  new data, as with `true`; with several rows the legend keeps the names.
  `segmentLabels: true` is unchanged: numbers on the parts and in the legend.

## [0.29.0] - 2026-10-29

A stacked bar can carry each part's number on the part itself, shown only
where it fits, while a progress row's legend gives every part's number. That
legend also no longer loses lines on a phone.

### Added

- **`options.plugins.segmentLabels: true`** puts each part of a stacked bar
  chart's value on the part itself: centred, in the chart's 12px text, as its
  tooltip writes it (the value axis's `ticks.format`). A label shows only
  where it fits - the text's width plus 8px inside the part (inside its 2px
  gap), on a bar at least 16px thick - so a part too narrow has none rather
  than spilling into its neighbour or being cut off. Labels re-fit as the
  chart resizes, takes new data or hides a series, redraw on a theme change,
  and don't animate under reduced motion. On a one-row stack (a progress
  row) the legend gives each part's number too ("Completed 61"), so every
  number stays on screen; with several rows the legend keeps the names. The
  text is foreground or the surface colour, whichever reads better on the
  part's fill as drawn (a hovered part is darker), or black or white where
  neither reaches 4.5:1 - on `chart-1` neither white nor the light
  foreground does, so its numbers are dark in both modes. The hidden table
  and the tooltips are unchanged. See "Progress row, counts on the parts" on
  the Chart page; `/lab/charts` has it on its progress row.

### Fixed

- **A progress row's legend keeps every line on a phone.** Chart.js caps a
  legend at half the canvas, and a one-row chart is a 36px row, so once the
  legend wrapped (a narrow card) only its first line showed - two of a
  four-state progress row's states were missing. Horizontal bar charts,
  which size themselves to their rows, now grow for the whole legend
  instead, and settle in one or two passes when it's taller than the
  canvas.

## [0.28.1] - 2026-10-28

A number card's trend always leaves room above its peak - a flat series is a
level line, a small wiggle a gentle one - and labels above a leaderboard's
bars no longer clip at the top of the chart.

### Fixed

- **A number card's trend always has room above its peak.** Its range came
  from Chart.js's nice ticks, so a peak on a round number (or a flat series)
  sat on the canvas's top edge and the line looked like it ran off the card,
  while other peaks had room. The range now comes from the data: the peak
  sits a sixth of the trend's height below its top, every time, and the
  range is at least a fifth of the top value, extended below the data, so a
  flat series is a level line at that height and a 1-point wiggle (36% to
  37%) a gentle line rather than a full-height V. A `scales.y` `min` / `max`
  from the server still wins.
- **Labels above the bars no longer clip at the top.** With
  `endLabels.position: "above"` (and on narrow screens) the first row's name
  and label had no room over the canvas's top edge. The kit now pads the top
  by the font size plus the 4px gap (16px), and the canvas grows by it (rows
  × row height, plus that room). A top padding the server already passes
  counts toward it - the larger wins - so an app that padded the top itself
  (`options.layout.padding.top: 12`) gets 16px, not 28; it can drop its own.

## [0.28.0] - 2026-10-28

Leaderboard labels can sit above the bars at every width, a number card's
trend now runs to the card's edges, and the change badges have borders in
their own tone, with every badge's text at 4.5:1 or more in light and dark.

### Added

- **`options.plugins.endLabels.position: "above"`** puts a horizontal bar
  chart's names and end labels above the bars at every width, so the bars run
  the card's full width (side by side while they fit, on two lines when they
  don't). The default, `"auto"`, is unchanged: at the bar ends, moving above
  only on a narrow screen.

### Fixed

- **A number card's trend runs edge to edge.** Chart.js's auto padding (room
  for a hover point and half the line) left a 1px strip inside the card's
  border at both sides and the foot; a `variant="trend"` chart now draws to
  the edges, keeping half the line above a peak. The number card's trend
  config no longer sets `layout` (a padding there would replace the hook's).
- **Stronger borders on the change badges.** The period's badge ("vs PP") is
  edged in foreground at 18% over the card instead of `--border-color`, which
  nearly vanished on a card; the good, bad and neutral badges are edged in
  their own tone at 30% over the card.
- **The neutral change badge's text reaches 4.5:1** in light (it was 4.35:1,
  muted-foreground on muted): a tenth of foreground is mixed in. Text contrast
  is now 4.74 / 5.47 / 5.69 / 5.19 (vs, good, bad, neutral) in light and
  6.94 / 7.92 / 6.43 / 6.44 in dark.

## [0.27.0] - 2026-10-28

The number card explains itself and compares: a ? beside the label says what
the number counts, badges set it against another period (good news green, bad
news red), and the whole card can open what's behind the number. Its trend now
shows its peaks and has no gaps.

### Added

- **`<.number_card>` help, changes and links.**
  - `help`: a ? after the label that shows what the number counts, in a
    popover on hover, focus or tap (a 44px target on touch). The button is
    described by the text.
  - `<:change vs by percent direction good>`: badges comparing the number with
    another period, under the line and floating over the trend: an outline
    badge naming the period ("vs PP"), then the difference and the change with
    an arrow. Good news (`direction` matching `good`, default `"up"`) is tinted
    green, bad news red, flat or `good="none"` neutral. Several `<:change>`s
    sit side by side (vs PP, vs PY).
  - `navigate` / `patch` / `href`: the whole card is a link, for opening what's
    behind the number. The label is the link, stretched over the card; the help
    stays its own button. Hover tints the card, keyboard focus rings it.

### Changed

- **A number card's trend shows its peaks:** it no longer fades out toward the
  top, so a spike is as clear as the rest of the line.
- **A trend bridges missing points:** a `nil` (a day with nothing to count) no
  longer leaves a gap in the line (`spanGaps`).
- The number card no longer clips (`overflow: hidden`) or isolates its
  content: the trend clips itself, so the help can float over the card's edge
  and the cards beside it.

## [0.26.0] - 2026-10-28

A chart kit, as an optional part: `<.chart>` draws any Chart.js chart from an
ordinary config the server sends, `<.number_card>` is a dashboard's headline
figure, and both take their look from the theme. Apps that don't use charts
load nothing new.

### Added

- **`<.chart>`** (`ShadcnDaisyui.Components.Chart`, imported by
  `use ShadcnDaisyui.Components`): `id`, `label`, `config` - a Chart.js config
  (`type`, `data`, `options`) as Elixir maps, any stock chart type. One hook
  draws every chart (`ShadcnChart`), and when LiveView changes `config` it
  moves the same chart to the new data. The look is set once, from the
  tokens: series take `--chart-1…5` in order, text `--foreground` /
  `--muted-foreground`, grid lines `--border-color`, the gaps between stacked
  parts the surface behind the chart, the font the page's; the tooltip is a
  popover-styled element in the top layer. Charts redraw when the theme
  changes (`setTheme`, any `data-theme` change, the OS scheme), brand themes
  and theme islands included.
  - Bars are at most 24px with a 4px rounded data end, square at the baseline;
    stacked parts are parted by a 2px surface gap; a single stacked bar with
    no value axis (a progress row) rounds at both ends; lines are 2px with
    their points shown on hover; one series has no legend, two or more get
    one under the chart (keys mirror the marks).
  - Kit keys Chart.js ignores: a dataset's `color` (a token: `"chart-3"`,
    `"muted-foreground"`, `"chart-1/35"` for 35% opacity, or a list per bar),
    its `key`, `data.keys`, and `options.plugins.endLabels.labels` - a text at
    each bar's end, drawn by a small Chart.js plugin; on a narrow screen it
    moves above the bars (beside the name, or under it on two lines).
  - Horizontal bar charts size themselves to their rows; tick labels on the
    value axis compact from 1,000 (`$25K`) while tooltips keep the full value
    (both follow the axis's `ticks.format`).
  - `on_click="event"` pushes `%{"id", "key", "series", "index"}` (`target`
    for a LiveComponent); dead views get a bubbling `chart:click` event.
  - Accessibility: `label` names the chart and captions a visually hidden
    table of its numbers (`format` writes them); the canvas takes focus, the
    arrow keys move the tooltip between labels (or a bar's parts) and a polite
    live region reads it, Enter / Space send `on_click`, Esc hides it. Reduced
    motion turns animation off.
- **`<.number_card>`**: a label, a big number, the line under it (the inner
  block) and a faint trend behind the number (`trend`, a filled line with its
  axes, grid, legend and points hidden; `color` picks its token).
- **The `shadcn_daisyui/charts` entry** (`priv/static/shadcn-daisyui-charts.js`):
  `import { ChartHooks } from "shadcn_daisyui/charts"` and
  `hooks: { ...Hooks, ...ChartHooks }`, or `initCharts()` in a dead view.
  `package.json` gains an `exports` map for it (`"."` stays
  `shadcn-daisyui.js`, which loads no outside code; `./priv/static/*` keeps
  working).
- **Chart.js 4.6.1 ships inside the package** (`priv/static/vendor/`, with its
  one dependency, @kurkle/color 0.3.4): apps load it from their own server,
  under a strict `script-src`, with no CDN and no npm.
  `priv/static/vendor/README.md` records the versions, the npm integrity
  hashes and the one change (the bare `@kurkle/color` import points at the
  vendored copy); `scripts/vendor_chartjs.sh VERSION` re-vendors.
- `usage-rules/styles-charts.md`: the form for each job, the series colours,
  marks, labels and the numbers in text (synced to the Swift package's
  guidelines). `usage-rules.md` gains the chart rules, a Charts section and
  the two components.
- Docs: the Chart and Number Card pages (live, light and dark), Styles →
  Charts, an optional Charts step in Installation, and `/lab/charts` (clicks
  reaching the server and a LiveComponent, data moving in place).

### Changed

- **The `--chart-1…5` tokens have new values.** The old ones failed the
  categorical palette checks: in light, chart-3 was too dark and grey
  (L 0.40, C 0.07) and chart-4 / chart-5 (yellow, amber) were too alike to
  tell apart, with or without colour blindness (ΔE 5.6 / 7.4); in dark,
  chart-2 and chart-3 were too light for the band; and slot 1 was orange in
  light but blue in dark, so a series changed colour with the theme. Now
  the same five hues in both modes, in a fixed order (blue, orange, aqua,
  yellow, magenta), stepped for each card surface, passing the lightness
  band, chroma floor, colour-blind separation of neighbours (worst ΔE 9.1
  light, 8.4 dark) and normal-vision separation (19.6 / 19.3). Anything
  painted with `var(--chart-N)` changes colour; brand themes that set their
  own `--chart-*` keep them.
- The Chart docs page's hand-drawn bars and SVG line are gone; the
  `.chart-bar` class stays (deprecated) for markup that used it.

## [0.25.0] - 2026-10-28

The toast is now a port of svelte-sonner, set up the way shadcn-svelte ships
it: same markup, timings and stylesheet, so `toast()`, `push_toast/3` and
flashes look and move like shadcn's Sonner, and every sonner option is there.
Nothing to change in your layout, `push_toast/3` calls or flashes; two small
JS behaviours now follow sonner (see Breaking).

### Breaking

- **Updating a toast keeps what you don't pass** (sonner merges): reusing an
  `id` changes the title, type and the options you give, and keeps the rest.
  Clear one with `description: undefined` in JS, or `description: ""` from
  `push_toast/3`.
- **Action and cancel buttons close the toast without calling `onDismiss`**
  (as in sonner); the close button, a swipe and `toast.dismiss()` still call
  it. Flashes are unaffected.

### Changed

- **Toasts look like shadcn's Sonner.** 8px corners (`--radius-md`) instead
  of 10px; the description in sonner's near-foreground grey (`#3f3f3f`, 91% in
  dark) instead of the muted foreground; the action button inverts the toast's
  colours (popover foreground on popover) with a 4px radius instead of using
  `--primary`; the cancel button is sonner's translucent text colour; the
  close button sits at the top start corner on every position (it moved to
  the right on right-hand stacks); `rich_colors` uses sonner's own light and
  dark palettes instead of tints of the status colours (override
  `--success-bg` … `--error-text` on `[data-sonner-toaster]` for a brand).
- **Toasts move like sonner's.** Unmounted 200ms into the exit; a dismissed
  toast keeps its place in the stack until it's gone; swipes lock to one
  axis, dismiss only toward the stack's edges (down or right for
  bottom-right) and stretch, dampened, the other way, then fly out the way
  they were thrown; promise toasts fade the spinner out as the result icon
  scales in; pressing a toast pauses the timers; the newest toast comes first
  in the tab order; Esc returns focus to where Alt+T took it from.

### Added

- `<.toaster>`: `invert`, `theme` (`auto` follows the page, or
  `light | dark | system`), `gap`, `offset` / `mobile_offset` (px, a length, or
  per side), `hotkey`, `dir`, `swipe_directions`, `toast_options` (classes per
  part and type, `unstyled`, styles, default `duration` / `close_button`),
  `container_aria_label`, `close_button_aria_label`, `toaster_id` for a second
  toaster, `pause_when_page_is_hidden`, `duration={:infinity}`, `class` on
  each toast list, and `<:success_icon>` … `<:close_icon>` slots for your own
  icons (an empty slot hides one).
- JS: `toast.custom((id) => element)` (headless), `toast.getActiveToasts()`,
  per-toast `invert`, `richColors`, `unstyled`, `class`, `classes`,
  `descriptionClass`, `style`, `actionButtonStyle`, `cancelButtonStyle`,
  `dismissible`, `testId`, `toasterId`, `icon: null`; `toast.promise` takes a
  fetch `Response` that isn't ok as an error, an optional `loading`, and
  `success` / `error` functions returning `{ message, ...options }`.
- `push_toast/3`: `:rich_colors`, `:invert`, `:dismissible`, `:icon` (a
  heroicon class, or `false`), `:class`, `:description_class`, `:classes`,
  `:unstyled`, `:toaster_id`, `:test_id`, and `duration: :infinity`.

## [0.24.3] - 2026-10-26

One behaviour fix, no markup changes: the `<.app_shell>` sidebar keeps its
scroll position from page to page, and shows the new page's item if it's out
of view. It comes with `shadcn-daisyui.js`; apps need no changes.

### Fixed

- **The `<.app_shell>` sidebar lost its scroll position on every page
  change.** A LiveView navigation (`<.link navigate>`, `push_navigate`,
  back/forward) replaces the whole shell, so the sidebar's navigation started
  at the top again: someone who scrolled down to a group near the bottom lost
  their place with each click. The navigation now keeps its position from
  page to page, in the expanded sidebar and after the rail expands again
  (Cmd/Ctrl+B, `shadcn:toggle-sidebar`). It's back before the new page
  paints, instantly (no smooth scroll), and if the new page's active item is
  out of view it scrolls just enough to show it. A full page load in the same
  tab (a dead view, a reload, a link to another `live_session`) keeps it too,
  through sessionStorage (`shadcn:sidebar-scroll`). It ships in
  `shadcn-daisyui.js`: no markup or app changes. Phones are unchanged.

## [0.24.2] - 2026-10-26

One layout fix, no markup changes: a `<.table_card>`'s rows are one height
whether or not they hold a ⋯ menu, a small button or a badge, and the
`<:empty>` row matches them, so a card with no rows lines up with a card
beside it that has some.

### Fixed

- **`<.table_card>` rows weren't one height.** A row with a ⋯
  `<.dropdown_menu>` was 60px against a row of text's 45px (the trigger's
  36px box set the line), a row with a badge 48px, and the `<:empty>` row 69px
  (its own 24px padding), so a card with no rows didn't line up with a card
  beside it that had one. The empty row now has a row's padding and line, and
  where a row's cells sit side by side (`grid`, or stacked from 40rem) a small
  control in a cell - a button up to the default size, the ⋯ menu's trigger,
  a badge - sits in the row's padding: centred, at its full size, its focus
  ring clear of the row lines. On touch screens each button's hit area is
  44px and still fits in the row, so rows keep one height there too. Taller
  content (two lines, an avatar) still makes its row taller. No markup
  change.

## [0.24.1] - 2026-10-26

Two layout fixes, no markup changes: a dialog that sits straight inside an
`<.app_shell>` page opens over the whole window at its own size, and
`<.table_card>` no longer cuts off the menus and pickers inside it. Apps
that wrapped their dialogs in a `contents` div can drop the wrapper.

### Fixed

- **A dialog straight inside an `<.app_shell>` page took the page's reading
  width.** The rule that keeps a non-`wide` page's children to 48rem reached a
  `<dialog>` that was a direct child of the page, so an open sheet was 48rem
  wide instead of its own width, and a modal whose own width didn't win was
  48rem wide from the window's left edge, its box off-centre and its backdrop
  over that strip only. The rule now leaves out every `<dialog>` (dialog,
  alert dialog, sheet, drawer, command) and any `[popover]`: they open over
  the whole window wherever they sit in the page, as outside the shell, with
  no `contents` wrapper. Closed, they still add no gap.
- **`<.table_card>` clipped the menus inside it.** The card was
  `overflow: hidden`, so a row's ⋯ `<.dropdown_menu>` (and a popover or a
  select, combobox or date panel, in a row or in `<:actions>`) was cut off at
  its edge - the menu on the last or only row almost entirely. The card no
  longer clips; the rows at its corners round with it instead, so row lines
  and a `row_class` background still stay inside the rounded corners. The
  usage rules now say row actions are a ⋯ `<.dropdown_menu align="end">` in
  the last column, and that `<.table>`, the static table recipe and
  `<.data_table>` do clip (they scroll, or round their corners that way), so
  a ⋯ menu per row belongs in a table card.

## [0.24.0] - 2026-10-24

Confirmations, code and AI chat: `<.alert_dialog>` and styled `data-confirm`,
`<.code_block>`, and the chat kit - `<.message_scroller>`, `<.trace>` and
`<.prompt_input>` (in `ShadcnDaisyui.Components.Conversation`). All new and
opt-in; existing markup renders as before apart from the fix below.

### Added

- **`<.alert_dialog>`** (in `ShadcnDaisyui.Components.Overlay`, imported by
  `use ShadcnDaisyui.Components`): shadcn's AlertDialog on a native modal
  `<dialog role="alertdialog">`, `aria-labelledby` its `<:title>` (required,
  the question) and `aria-describedby` its `<:description>`. Cancel comes
  first and takes focus when it opens (`cancel="Keep editing"` relabels it);
  `<:action variant="default|destructive">` (required) is a button, or a link
  when it has `navigate` / `patch` / `href` (+ `method`), and passes every
  other attribute through - `phx-click` (+ `phx-value-*`), `type="submit"` +
  `form`, `id`, `disabled`. Choosing it closes the dialog; `close={false}`
  leaves that to the server (`push_hide_modal/2`). Esc cancels, a backdrop
  click doesn't close it (on an app shell page too), and the browser returns
  focus to whatever opened it. Opens like the other modals: `<:trigger>`,
  `show_modal/2`, `push_show_modal/2`, or `show` + `on_close` (Cancel, Esc and
  the action each run `on_close`). `size="sm"` (20rem, centred, the buttons
  side by side) and `<:media>` (a 64px muted square above the title, left of
  it from `sm`) as in shadcn. Theme classes: `.alert-dialog`,
  `.alert-dialog-sm`, `.alert-dialog-header`, `.alert-dialog-media`,
  `.alert-dialog-title`, `.alert-dialog-description`, `.alert-dialog-footer`
  (phones: centred header, the action above Cancel, both full width; from
  640px left-aligned with the buttons in a row on the right). With reduced
  motion it fades without the zoom. No inline handlers: Cancel and the action
  close it through one delegated listener in `shadcn-daisyui.js`.
- **Styled confirmations (opt-in)**: `initConfirmDialog()` (exported from
  `shadcn-daisyui.js`; call it once in `app.js`, or pass
  `initShadcnDaisyui({ confirm: true })` in a dead view) replaces the
  browser's `confirm()` for every `data-confirm` - dropdown and command
  items' `confirm`, `<.link data-confirm>`, any button - with the package's
  alert dialog. The click is stopped in the capture phase before
  `phoenix_html` or LiveView see it; Cancel or Esc does nothing, and the
  action replays the click on the same element (its `data-confirm` lifted for
  that one click), so `phx-click`, `data-method` links, plain links and form
  submits run exactly as before. A command palette item still closes its
  palette only once accepted. Per element: `data-confirm-description`,
  `data-confirm-action` (the action's label, default "Continue"),
  `data-confirm-cancel`, `data-confirm-variant` (a destructive dropdown item
  or `btn-error` button gets a destructive action by default);
  `initConfirmDialog({ action, cancel })` sets the default labels.
  `confirmDialog(message, options)` asks the same way from your own code and
  returns a promise of the answer. Works under a strict `script-src` policy.
- **`<.code_block>`** (`ShadcnDaisyui.Components.CodeBlock`, imported by `use
  ShadcnDaisyui.Components`): shadcn/ui's Code Block, for webhook and API
  payloads, integration logs, import error reports, before/after diffs in a
  record's history and code in chat replies. Rendered on the server with no
  syntax highlighting (shadcn's Shiki is a heavy client dependency): `code`
  is split into lines and HTML-escaped; `lines` gives each line a variant -
  strings, `{:added | :removed | :highlighted, text}`, or `Phoenix.HTML.raw/1`
  lines an app highlighted itself (e.g. Makeup, one fragment per line). Added
  and removed lines get a `+` / `−` marker and a tint (muted, destructive/10),
  never colour alone; `highlight={[42, 50..52]}` tints lines by number.
  `line_numbers` (from `start_line`, the gutter widening to the widest
  number), `wrap`, and `content_class="max-h-72"` to cap the height: the
  scroll region's edges fade while there is more to scroll to (scroll-driven,
  so no overflow means no fade). An optional header holds `title` (a filename
  or label, truncating) with an `icon` and the actions - `<:actions>` buttons
  (the `code-block-action` class: shadcn's 24px ghost icon button, 44px hit
  area on touch) and Copy; without a title the actions float at the top end,
  showing on hover or focus (always on touch screens). `<:footer>` for a Show
  more or Download row. `variant="destructive"` for error output, `size="sm"`
  (text-xs, 12px padding) inside a card, sheet or chat reply. The scroll
  region is a `<pre role="region" tabindex="0" dir="ltr">` named by the title
  (or `label`, default "Code"); its keyboard focus rings the whole block.
  Line numbers and diff markers are CSS generated content, so a selection
  never picks them up; the numbers are silent to screen readers and the
  markers read "Added" / "Removed" (`--code-block-added-label` /
  `--code-block-removed-label` translate them). Copy copies every line's
  plain text (no numbers or markers, highlighting stripped, blank lines kept)
  or `copy_text`, through `navigator.clipboard` with an `execCommand` fallback
  (insecure contexts, iframes that refuse clipboard access), then swaps to a
  check for 2s while a polite live region says "Copied" (`copy_label` /
  `copied_label`) and dispatches `code-block:copied`; `copy={false}` drops it.
  Hook: `ShadcnCodeBlock` (or `initShadcnDaisyui()` in a dead view). A gallery
  page (`/docs/components/code-block`, under Data display) shows a payload,
  line numbers, a diff, a wrapped log, error output and a small block in a
  card, with SwiftUI guidance (monospaced `Text` in a `ScrollView`,
  `.textSelection(.enabled)`, a copy button).
- **Docs**: the Alert Dialog page is now the component (default, destructive,
  small with media, opened from the server, styled `data-confirm`), rendered
  from `<.alert_dialog>` in place of the class recipe. The docs site and the
  `/lab/csp` LiveView turn on `initConfirmDialog()`, so every `data-confirm`
  there (the command palette's "Add back", dropdown items) asks in the alert
  dialog; `/docs/dark-mode` and `/lab/csp` carry an alert dialog. Usage rules:
  a confirmation is `<.alert_dialog>` (or `data-confirm` with
  `initConfirmDialog()` on), never a plain dialog or the browser's
  `confirm()`.
- **`<.message_scroller>`**: shadcn/ui's Message Scroller. A viewport that
  fills its parent (a labelled `role="region"`, a tab stop for keyboard
  scrolling), the rows in a `role="log"` live region (`aria-relevant=
  "additions"`, `aria-busy` while `busy`), and a scroll-to-latest button
  (`button="end|start|both|none"`) that is inert and out of the tab order
  while there is nothing that way. `items` is a list (keyed by `item.id`, or
  `item_id`) or a LiveView stream (`phx-update="stream"`, keyed by its DOM
  ids); the inner block renders a row (`:let`); `anchor` marks turn anchors;
  `<:above>` / `<:below>` rows sit inside the log (load earlier, a typing
  marker). Hook `ShadcnMessageScroller` (or `initShadcnDaisyui()`): opens at
  `default_position` - `"end"`, `"start"` or `"last-anchor"` (the last
  anchored turn at the top; the end when it fits) - hidden until positioned
  (shown after 2s regardless, if no script runs), and waits for a size (a
  scroller in a sheet that opens later); follows growing content (a streaming
  reply) only while the reader is at the live edge (`follow`), released by a
  wheel, touch, scroll keys or the scrollbar and picked up again at the end or
  by the button; a new anchored turn moves near the top with `peek` px (64) of
  the row above still showing, with room made under it for the reply; rows
  added above (a stream insert `at: 0`) keep the row being read in place, on
  every browser (native scroll anchoring is off); a reset stream reopens it.
  `data-scrollable` and `data-autoscrolling` for styling; the bottom edge
  fades while there is more below; `shadcn:scroll-to` (`detail: %{to: "end" |
  "start" | dom_id}`) jumps. Smooth jumps are instant with reduced motion.
- **`<.trace>` / `<.trace_line>`**: shadcn/ui's Trace, for an assistant's
  steps, tool calls, sources and plans. `<:line status icon description href
  navigate patch target>` rows: done (no status), `running` (the title
  shimmers and the glyph pulses, as a working sparkle; neither with reduced
  motion), `pending` (60%) or `error` (destructive); text-sm muted, 16px
  icons, rows 8px apart; the title is one truncated line, the description
  (70% muted, tabular figures) never truncates; a source line is a link (a
  new tab says so to screen readers). `<.trace_line id>` with `<:icon>`,
  `<:description>` and `<:detail>` is a disclosure: a button with
  `aria-expanded` / `aria-controls` and a chevron that opens the detail under
  it (the 180ms row reveal; closed detail is out of the tab order), indented
  with a line on its left; rows nest. One delegated listener toggles it (no
  hook), and the reader's choice survives LiveView patches.
- **`<.prompt_input>`**: the chat composer (Vercel AI Elements' PromptInput,
  on shadcn's field metrics). A form-bound field (`field`, or `name` /
  `value`) that grows with its text from 4rem to 12rem, then scrolls (CSS
  `field-sizing: content`, or the hook where it's missing); Enter sends and
  Shift+Enter adds a line, never while an input method is composing; Send is
  `aria-disabled` (50%) while there is nothing to send; the field clears once
  the message is on its way and keeps focus. `busy` makes the same button
  Stop (it pushes `on_stop`, default `"stop"`, or a JS; `target` for a
  LiveComponent) and Enter waits. `upload` adds an attach button (a label
  around the hidden `live_file_input`), makes the field the upload's drop
  target (primary border on accent while files are over it) and takes pasted
  files (LiveView's `track-uploads`); picked files are `<.attachment>` tiles
  above the text, like `<.dropzone>`'s (`on_cancel`, `error_text`).
  `<:suggestion value>` chips are `<.bubble as="button">`s that fill the field
  and send it (`send={false}` only fills it), or take your own `phx-click`;
  `<:tools>` sits beside the attach button. Toolbar buttons get a 44px hit
  area on touch screens; `enterkeyhint="send"`. Hook `ShadcnPromptInput`.
- **Usage rules: an AI chat page** section (the layout in `<.app_shell
  fill>`, the rows, trace for steps and sources, streaming a reply from
  LiveView with a stream insert per message and `start_async`, `aria-busy`
  until it's done, Stop as `cancel_async`, history and the composer), a "never
  hand-roll a chat scroller, step list or composer" rule, table rows for the
  three, and the two hooks in the list of components that need an `id`.
- **Docs**: Message Scroller (with a streaming preview), Trace (steps, tool
  calls, tool output in a `size="sm"` `<.code_block>`, sources, plan, a whole
  turn) and Prompt Input (suggestions, busy,
  attachments, disabled) pages in the Conversation group, each with specs,
  accessibility and SwiftUI guidance, and `/lab/chat` (dev server): a made-up
  assistant that answers from the lab's orders, streaming its steps and text,
  with Stop, earlier messages and attachments.

### Changed

- README: the "What's included" claim now matches shadcn-svelte's current
  catalog (66 components, all but Trace, Message Scroller and Questionnaire
  reproducible).

### Fixed

- **Lifted tabs showed a brighter line under the tabs in dark mode**: with
  `.tab-content` panels, daisyUI's `tabs-lift` draws a bottom border under each
  inactive tab on the same row as the panel's top border, and the translucent
  dark border colour doubled up there. The panel's border is now the only line.

## [0.23.0] - 2026-10-24

File uploads: the file input now looks like shadcn's, and `<.dropzone>` is a
file picker people can drop files on, with the picked files as attachment
tiles. New and opt-in; existing markup renders as before apart from the fixes
below.

### Added

- **`<.dropzone>`** (in `ShadcnDaisyui.FormComponents`, imported by `use
  ShadcnDaisyui.Components`): the drop area of Kibo UI's Dropzone and Dice UI's
  File Upload (shadcn/ui and shadcn-svelte have none), on a LiveView upload.
  `upload={@uploads.x}`: the zone is a `<label>` around the visually hidden
  `live_file_input` and the upload's `phx-drop-target`, so a click, a tap,
  Enter or Space opens the picker (no inline JS). Without slots the title
  ("Drop a file here, or choose one"; "files" when `max_entries > 1`; "Choose a
  file" on touch screens, which can't drag) and the description ("One .csv
  file, up to 1 MB." - accepted types, size limit, how many) come from the
  upload; `<:title touch="…">` and `<:description>` word your own. Each entry
  is an `<.attachment>` tile: uploading with its progress, done (an image
  previews with `live_img_preview`), or an error with the reason; `on_cancel`
  (an event or a `Phoenix.LiveView.JS`, `target` for a LiveComponent) adds a
  remove button that pushes `%{"ref" => ref}`. `<:entry :let={entry}>` renders
  your own (each file's errors then show under the zone). Upload errors (too
  many files) show under the zone as `text-sm text-error` lines in a polite live
  region; every error is tied to the input by `aria-describedby`, and
  `aria-invalid` marks a rejected file. Built-in English for `:too_large`,
  `:not_accepted`, `:too_many_files` and `:external_client_failure`;
  `error_text={fn error -> text end}` replaces it (`nil` keeps the default).
  `size="compact"` is one `h-9` row shaped like an input (44px on touch), the
  description under it; `disabled` dims it to 50% and takes no picks or drops.
  Dashed `border-border` at rest, `border-primary` on an `accent` fill while
  files are over it (150ms, none with reduced motion), the 3px ring while its
  input has keyboard focus. Hook: `ShadcnDropzone` (or `initShadcnDaisyui()`):
  `data-dragging` while files are over the zone on every LiveView version
  (LiveView's own `phx-drop-target-active`, from 1.1.1x, styles it too), a
  disabled zone refuses the drop, and a drop never makes the browser open the
  file. Theme classes: `.dropzone`, `.dropzone-area`, `.dropzone-icon`,
  `.dropzone-title`, `.dropzone-description`, `.dropzone-errors`,
  `.dropzone-entries`, ….
- **A plain form's dropzone**: `name` (with `accept` and `multiple`) instead of
  `upload`, for a non-LiveView multipart form. A drop puts the files the input
  accepts on the input (added to the chosen ones when it's `multiple`; posts
  `name[]`), fires `input` + `change`, and the zone names the chosen files; a
  form reset clears them. The server checks the size.
- **File input gallery examples** on the Input page (`<.input type="file">`,
  and `.file-input` default, ghost, sizes, disabled and error), and a Dropzone
  page (default, compact, uploading, errors, disabled, plain form, with iOS
  guidance: `.fileImporter` plus `.dropDestination`). Attachment's "don't use
  for" links to it. `/lab/dropzone` (dev server) runs it on real uploads.

### Fixed

- **`.file-input` started "Choose File" 12px in**, as a full-height grey block
  after an empty strip of field: the theme's field padding pushed daisyUI's
  flush button inward. It is now shadcn's `<Input type="file">`: the field
  keeps its 12px padding and "Choose file" is plain `text-sm font-medium`
  foreground text (`h-7`, no border, fill, noise or shadow) with 8px before the
  file name, in light and dark. The same applies to `<.input type="file">`
  (`.input[type=file]`), which showed the browser's own button. Colour variants
  keep the foreground text. The ring shows for keyboard focus only
  (`:focus-visible`), so it no longer stays lit after the picker closes.
- **`file-input-ghost` and `file-input-xs|sm|lg|xl` did nothing** (the theme's
  border and fixed `h-9` won): ghost drops the border, fill and shadow; the
  sizes are `h-6` / `h-8` / `h-10` / `h-12` with the button scaled to match.
- **Fields showed no error state**: `input-error` (which `<.input>` adds),
  `textarea-error`, `select-error`, `file-input-error` and `aria-invalid="true"`
  left the border grey. They now get shadcn's destructive border, and a
  destructive ring while focused.
- **Disabled fields were greyed out** (daisyUI's muted fill and faded text):
  `.input`, `.textarea`, `.select` and `.file-input` now keep their own colours
  at 50% opacity with a not-allowed cursor, as shadcn's do.

## [0.22.0] - 2026-10-23

The parts apps kept writing for themselves: a list page's data table and
toolbar, a state module for what the table shows, an empty state, a record
page's tabs, table cards, section nav and time field, and modals the server
opens. All new and opt-in; existing markup renders as before.

### Added

- **Opening modals from the server.** `push_show_modal(socket, id)` and
  `push_hide_modal(socket, id)` push `shadcn:show-modal` / `shadcn:hide-modal`,
  which the package JS listens for (as `push_toast/3` works); a modal opens
  each time it's pushed, even after the person closed it. `show` on
  `<.dialog>`, `<.sheet>`, `<.drawer>` and `<.command>` keeps it open while
  true: it opens on mount (a modal rendered with `:if` opens as it appears)
  and whenever `show` turns true, and closes when it turns false. `on_close`
  (an event or a `Phoenix.LiveView.JS`) runs when the person closes it - Esc,
  the backdrop, a close or Cancel button - so the assign can follow; closing
  from the server doesn't run it. Docs: a button opens from the browser, a
  decision the server makes opens from the server.
- **`<.empty>`**, shadcn's Empty: an icon (or `<:media>`) in a 40px muted
  circle, a title, one muted line and `<:actions>`. `variant="card"` (default)
  is a bordered card with 48px vertical padding; `variant="plain"` sits inside
  a table or card. Theme classes: `.empty-state`, `.empty-state-media`,
  `.empty-state-title`, `.empty-state-description`, `.empty-state-actions`.
- **`<.data_table>`**: a card that fills the space left (in `<.app_shell
  fill>`) whose body scrolls under a sticky, opaque header; `table-fixed`,
  cells truncate. `<:col label sort class align hide_below>`; the rightmost
  column shown at each width is right-aligned (header and cells) unless
  `align="left"`, never the first. Sortable headers send `dt:sort` and show
  an up or down arrow beside the label, outside its layout (before it on
  right-aligned columns; an up-down arrow on hover), with `aria-sort`. Rows
  are focusable: a click or Enter sends `dt:open` (not on links, buttons,
  inputs, labels, `[data-row-ignore]`, or a click that ends with text
  selected); Cmd/Ctrl-click and middle click open `row_href` in a new tab;
  `active_id` highlights the row last opened and scrolls it into view.
  `selectable` adds a checkbox column (from `md`): `dt:select` with `shift`
  (Shift-click ticks the range without selecting text), a header checkbox
  (`dt:select_all`) that is ticked or half-ticked from the rows after every
  update, and a bulk bar that replaces the column labels while rows are ticked
  so the rows never move: "N selected" (or "All M selected"), "Select all M
  orders" (`dt:select_matching`) when every loaded row is ticked and
  `matching` says more match, `:bulk`, Clear (`dt:clear`). `more` sends
  `dt:more` once the end comes within about 200px, once until the reply.
  `scroll_key` keeps the body's scroll position (per view) in
  `sessionStorage`; a new sort, search or filter starts it at the top. `edge`
  runs it edge to edge on phones; while rows are ticked the body leaves room
  for a floating bar on phones. `:empty` (with `title` and `icon`) and
  `:empty_action` use `<.empty>`'s in-table layout. Every event carries
  `"table" => id`; `target` sends them to a LiveComponent. Hook:
  `ShadcnDataTable` (old `[data-datatable]` docs-showcase markup still gets the
  showcase); in a dead view the table dispatches `shadcn:data-table`
  (`{event, payload}`) instead, and `dt:more` waits for the page to change
  the rows before asking again. Theme classes: `.data-table`,
  `.data-table-scroll`, `.data-table-sort`, `.data-table-bulk`, ….
- **`<.table_toolbar>`**: the one row above a data table, as a form that
  sends `dt:filter` on change and submit. `views` as a `<.tab_nav>` (patch
  links with counts, an edited view's dot, a "Views" menu of `menu` entries)
  or, without views, "N orders" ("N of M" while filtered); the search (`q`,
  debounced 200ms; it takes the row on phones without views); a Filters button
  with the number of filters on; `:more` (hidden on phones). The filters that
  are on show as a `<.chip_row>` in a `<.reveal>` (always rendered, so it
  collapses around the last chip); removing one sends `dt:unfilter`, `:fixed`
  chips can't be removed; then `:save` and "Clear all" (`dt:reset`). The
  filters sheet holds each `:filter` under its label (they apply as they
  change; the sheet stays open), on phones a "Sort by" select named `sort`
  (from `sorts`, the first the default order; "As the table is sorted" when
  the current sort isn't one of them), and "Clear all" / "Show N orders".
- **`ShadcnDaisyui.DataTable.State`**: plain Elixir for what a table shows.
  `from_params/2` / `to_params/2` (sort, search and filters in the URL, `q`,
  `sort`, `dir=desc` and one param per filter, defaults left out), `filtered?/2`,
  `values/1` (a comma list; `"any"`, `""` and nil are none), `any_of?/2`,
  `put_search/2`, `put_filters/4`, `chips/3`, `sort_value/1`, `parse_sort/3`
  (the value first), `toggle_sort/2` (ascending, descending, default), `run/3`
  (search every word, filter, sort with empty values last and dates and times
  by value), and the selection: `select/4` (Shift ticks the range from the
  anchor in the order shown), `select_all/2`, `keep_visible/2`, `clear/1`,
  `selected?/2`. Ids are kept as strings.
- **`<.record_tabs>`**: a tab row inside a record (`tabs`, `active`); a tab
  sends `"tab"` with `%{"tab" => key}` (`event` and `target` change that),
  `role="tab"` + `aria-selected`, the active tab underlined, one tab stop with
  arrow keys. Theme classes: `.record-tabs`, `.record-tab`.
- **`<.table_card>`**: a card with a title, description, `:actions` and rows
  (`:col` with `label`, `class`, `align`; `:empty`). Row lines run edge to
  edge, the last row's padding is the space under it, labels show as a header
  row from `sm`, rows stack on phones unless `grid` keeps them side by side,
  and the rightmost column is right-aligned unless `align="left"`.
- **`<.section_nav>`**: where an edit form's sections are. `variant="side"`
  (from `lg`, beside the cards it's given as its inner block, pinned just
  under the page's pinned header and level with the first card, scrolling on
  its own when taller than the window, a "Filter sections" input over 10
  sections) and `variant="select"` (below `lg`, a full-width dropdown for the
  page header's `<:below>` naming the section in view, "Group, Section" when
  grouped, 44px options with a tick). Both mark the section in view
  (`aria-current`) against the bottom of the pinned header (the last one at
  the bottom of the page); choosing one scrolls there (smoothly, or at once
  under reduced motion), keeps it marked until the scroll settles - and,
  when the page can't bring it up to the header, until the person scrolls on
  - moves focus to it and closes the select. Hook: `ShadcnSectionNav`.
- **`<.time_field>`**: a labelled `<.time_picker>` bound to a form field
  (`id`, `field`, `label`, `minute_step` 15): the label above, the picker full
  width with "Not set", and the field's errors under it once used or submitted.
- **`<.table scroll>`**: the table fills the rest of a card that grows and
  only its body scrolls, under a sticky, opaque header. Theme class:
  `.table-scroll`. Without `scroll` the markup is unchanged.
- A single `<.select>` / `<.combobox>` with a `value=""` option ("Default
  order", "Any") shows it as chosen while the value is blank, and posts `""`.
- Docs: pages for the data table (replacing the docs-only showcase), table
  toolbar, empty (replacing the hand-written recipe), record tabs, table card,
  section nav and time field, "Open from the server" on the Dialog page, a
  scrolling-body example on the Table page, usage rules for list and record
  pages, and `/lab/data-table` (a list page and its record page in a connected
  LiveView, on the dev server).

### Fixed

- Half-ticked checkboxes (`.checkbox:indeterminate`) were invisible: the dash
  drew in the primary-foreground colour on an empty box. They fill like a
  ticked box now.

### Checked

- `<.select>` keeps its chosen value across LiveView re-renders, as it has
  since 0.19.0: a pick survives re-renders that don't know about it, the
  server's echo and a stale render, and the server's own value or a reset
  wins. A browser test now covers it; apps need no wrapper.

## [0.21.2] - 2026-10-23

The command palette's search icon is configurable, and renders at its full
size.

### Added

- **`icon` on `<.command>`**: the search row's icon, `"hero-magnifying-glass"`
  by default. Any heroicon class `<.icon name>` takes (`-solid`, `-mini` and
  `-micro` too), e.g. `icon="hero-user-plus"`, or `icon={nil}` for none. Write
  it out in full so the app's Tailwind heroicons plugin generates it. Without
  `icon` the markup is unchanged.

### Fixed

- The command palette's search icon renders at its full 16px: the input took
  100% of the row and squeezed it to about 15.4px wide. The input now takes
  the row's free space instead (theme CSS only).

## [0.21.1] - 2026-10-23

A steadier server search: no empty strip while a search is pending, and
typed text survives a slow reply.

### Changed

- **`<.command on_search>` no longer shows an empty strip under the input
  while a search is pending.** What was on screen stays in view, dimmed,
  until the answer replaces it: the hint (typing the first letter), the empty
  text, or the last results. The list itself is hidden whenever it has no
  rows on screen (`aria-expanded` on the input follows it), so the hint and
  the empty text sit directly under the input.

### Fixed

- **`<.command on_search>` no longer clears what's being typed when a reply
  is slow.** LiveView sets the dialog's `open` attribute again, unchanged,
  when it unlocks the dialog after a pushed search; the hook took that for
  the palette opening, cleared the input and pushed an empty search. Only the
  attribute being added (a real open) resets the palette now.

## [0.21.0] - 2026-10-23

Server search in the command palette, for what only the server can search: a
directory, a remote API, a table too big to send to the browser. It is
opt-in; a `<.command>` without `on_search` renders and behaves as in 0.20.0.

### Added

- **`on_search="event"` on `<.command>`**: the hook stops filtering in the
  browser and pushes the trimmed text, `search_debounce` ms after the last
  keystroke (default 250), as that event with
  `%{"id" => id, "query" => text}`. The LiveView renders its results as the
  `<:item>`s and echoes the text they answer as `query` (required with
  `on_search`; nil before the first search). Items count only while `query`
  matches the input, so a reply to older text never shows as current.
  `phx-target` (e.g. `@myself`) sends the search, and the items' `phx-click`,
  to a LiveComponent. In a dead view the palette dispatches
  `shadcn:command-search` (`detail` is `{id, query}`); answer it by rendering
  the items and setting `data-query` on the dialog.
- **States, so the palette always says something**: `<:hint>` before anything
  is typed (never "No results found." there); while the reply is pending a
  spinner at the end of the input row, `aria-busy` on the list, and whatever
  was on screen stays, dimmed and inert (no active row, Enter does nothing);
  `<:empty>` (default "No results found.", also available without
  `on_search`) once the server has answered the current text with no items;
  else the items, the first one active, keyboard navigable as before. A
  re-render of the same answer keeps the active row.
- **Opening resets it**: the input clears and an empty search is pushed at
  once, so the server can drop the last results. Closing drops a search still
  waiting for its debounce.
- **Each answer is announced** in a polite `role="status"` region ("3
  results", or the empty text). LiveView leaves its text alone
  (`phx-update="ignore"`).
- **Opt-in `<.command>` item attributes**, as `<.dropdown_menu>` items have
  them; items without them render exactly as before:
  - `description` - a muted second line under the label (an email under a
    name).
  - `confirm` - renders `data-confirm`, asked by `phoenix_html`; the palette
    closes only once the person accepts, and cancelling keeps it open with the
    same results.
  - `values` - one `phx-value-<key>` per entry.
  - `disabled` - `aria-disabled="true"`, no click (a link or form item renders
    as an inert button), skipped by the arrow keys, 50% opacity.
- Theme classes: `.command-item-text` (the label, `.command-item-title`, over
  `.command-item-description`); `.command-item[aria-disabled="true"]` and
  `[data-command-list][aria-busy="true"] .command-item` are styled.
- Docs site: a "Server search" example on the Command page (answered by a
  stand-in in the static export), and `/lab/command-search`, a LiveView whose
  LiveComponent searches a made-up directory on the server.

## [0.20.0] - 2026-10-19

The app shell: the sidebar, phone dock, search, account menu and page header
a signed-in app needs, as one set of neutral components.
Everything is new or opt-in except the `<.command>` palette's shortcut
handling (see Changed).

### Added

- **`<.app_shell>`** (`ShadcnDaisyui.Components.Shell`, imported by
  `use ShadcnDaisyui.Components`): a signed-in app's whole shell.
  - Wide screens (from 48rem): a 16rem sidebar that collapses to a 3rem icon
    rail through `data-sidebar="collapsed"` on `<html>`, with a grab strip on
    its edge, a "Collapse sidebar ⌘B" row and tooltips on rail items. From the
    top: the `:header` slot, the search row (with its ⌘K hint) when `search`
    names a command dialog, the `nav` groups (small muted labels; the `active`
    item `aria-current="page"`, `bg-accent font-medium`), then the footer:
    `:footer_item`s, the collapse row, the `environment` badge and the account
    menu (initials, name, email; opens right of the sidebar, bottom-aligned).
  - Phones: a top row pinned while the page scrolls (`:phone_header`, then a
    search button), a bottom dock of up to four destinations (`bar`, default
    the first four of `more`) plus More, and the More sheet: the `more` groups
    (default `nav`), the footer items, then the account section.
  - The account menu's `:account_item`s (links with `navigate`/`patch`/`href`
    and `method`, or `phx-click` buttons; `soon`, `divider`, `destructive`)
    show in the dropdown (32px rows) and the More sheet (44px rows), with the
    theme row closing their first section.
  - `#main` is the one scroll region, with a 48rem reading width (a page
    child's own `max-w-*` wins), `wide` for full-width tables and `fill` for
    a table body that scrolls instead.
  - `nav` takes the shape a `Navigation` module returns:
    `[%{label, items: [%{id, label, short, path, icon}]}]`.
- **`<.app_shell_heading>`**: the top of the sidebar (a tile, title and
  subtitle; only the tile in the rail, with `tip` as its tooltip; `chevron`
  and the trigger attributes for a switcher). **`toggle_sidebar/1`**: the JS
  command that collapses or expands it.
- **`page_header/1` and `sticky_top/1` in `ShadcnDaisyui.CoreComponents`**,
  wrapped into your app's `CoreComponents` like `header/1` and overridable.
  `page_header` takes `crumbs` (`[%{label, path?}]`) rather than computing
  them: the last crumb with a `path` is the back link (Esc follows it outside
  fields, pickers, menus and open dialogs; `esc_back={false}` turns that off),
  and `back` makes it send an event instead. `badge`, `actions` and `below`
  slots; `id` (default `page-header`). `sticky_top` pins its content to the
  top of `#main` on the page colour and gets `data-stuck` (a line and
  `shadow-sm`) once `#main` has scrolled, falling back to the document's
  scroll outside the shell. The last crumb is always the current page. Hooks: `ShadcnStickyTop`, `ShadcnPageBack` (in
  `Hooks`; `initShadcnDaisyui()` wires them in dead views).
- **`ShadcnDaisyui.Components.theme_toggle/1`**: the system / light / dark
  toggle (`light` / `dark` theme names, default `shadcn` / `shadcn-dark`). It
  dispatches `phx:set-theme`, like Phoenix's own. Not imported by
  `use ShadcnDaisyui.Components`, because Phoenix 1.8 generates a
  `theme_toggle/1` in every app's `Layouts` and the import would clash with
  it. Call it by its full name, or `defdelegate` yours to it.
- **`<.command>` covers a search and a switcher**: `label` (the dialog's
  accessible name), `shortcut` (the Cmd/Ctrl letter that toggles it: `"k"` by
  default, `nil` for none), and items with an `id` that `navigate`, `patch`,
  `href`, or submit a form (`form`, `name`, `value`), besides `phx-click`. We
  extended `<.command>` rather than adding a `<.command_dialog>`: one palette
  component, and no clash with an app's own `command_dialog/1`.
- **Shell behaviour in `shadcn-daisyui.js`** (window listeners, so it works
  under a strict `script-src` CSP):
  - `shadcn:toggle-sidebar`, and Cmd/Ctrl+B outside fields on a page with a
    shell, toggle the sidebar and remember it in localStorage `shadcn:sidebar`.
  - `shadcn:show-dialog` opens its target dialog (the same as `show_modal/2`'s
    `shadcn:show-modal`).
  - On a page with a shell, plain dialogs close on a backdrop click (sheets,
    drawers and command dialogs already did), and every open dialog closes
    when LiveView navigates to another page (`phx:page-loading-start` with
    `kind: "redirect"`). A reconnect, a rejoin, a patch or `phx-page-loading`
    leaves them open.
- **`bg-page`**: base-100 with a 40% base-200 tint, as one solid colour so a
  pinned header can cover what scrolls under it (token `--page-background`,
  restated on every theme scope).
- **The pre-paint script is a setup rule**: the root layout sets `data-theme`
  and `data-sidebar` before first paint. `mix shadcn_daisyui.install` and
  `mix shadcn_daisyui.upgrade` add the sidebar line to Phoenix's theme
  script, or as a small script of its own when there is none, and leave a
  layout that already reads `shadcn:sidebar` alone.
- Docs: an "App shell" section and rows in `usage-rules.md` (the navigation
  guideline now points at `<.app_shell>`), and an App shell page in the docs
  site: a working shell on desktop and on a phone, `page_header` and the
  command dialog.

### Changed

- **The `<.command>` palette's shortcut**: the key listener is removed when the hook is destroyed, so
  a LiveView navigation no longer leaves one behind for a dialog that's gone.
  One listener serves every palette: a second ⌘K closes the palette (as in
  shadcn), and otherwise the last palette on the page with that letter opens,
  closing any other open dialog. Before, every `<.command>` on the page
  opened on ⌘K, stacked. The hook also reads its items live, so
  a patch that changes them is picked up (an open palette re-filters), and it
  keeps explicit item ids. Backwards compatible: `shortcut` defaults to `"k"`,
  and raw `data-command` markup without `data-shortcut` keeps ⌘K.
- `mix shadcn_daisyui.upgrade` patches the root layout in both install modes
  (it used to re-copy the assets of `--copy` installs only).
- `<.sidebar_layout>` and `<.sidebar_group>` are unchanged; their docs point
  signed-in apps at `<.app_shell>`.
- Dead views: a dock button that opens a popup (`aria-haspopup`, like the
  shell's More) no longer becomes the active dock item when tapped.
- `use ShadcnDaisyui.Components` also imports `app_shell/1`,
  `app_shell_heading/1` and `toggle_sidebar/1`, and your `CoreComponents` now
  exports `page_header/1` and `sticky_top/1`. A `CoreComponents` that already
  defines those two overrides them; a function with one of these names in
  another module that imports them must be renamed or removed.

### Moving an app onto `app_shell`

- **Delete**:
  - the shell markup in `Layouts.app/1`: the sidebar, phone row, dock, More
    sheet, user menu and their helpers. Render `<.app_shell>` with your
    navigation, header, footer items and account items instead.
  - the app's command dialog module: use `<.command id="search" label="Search">`,
    with `shortcut={nil}` on any other palette.
  - `page_header/1` and `sticky_top/1`: keep a thin `page_header` in your
    `CoreComponents` that computes `crumbs` from your navigation and calls
    `ShadcnDaisyui.CoreComponents.page_header/1`.
  - `theme_toggle/1`, or `defdelegate` it to `ShadcnDaisyui.Components`.
  - the shell part of `app.js`: the sidebar toggle and its Cmd/Ctrl+B
    listener, the show-dialog listener, the backdrop-click and
    `phx:page-loading-start` dialog closing. App-only listeners stay.
  - the `bg-page` `@utility` in `app.css`.
- **Rename**: an app's own shell events become `shadcn:toggle-sidebar` and
  `shadcn:show-dialog`, and the root layout's sidebar localStorage key becomes
  `shadcn:sidebar` (replace the line, or delete it and run
  `mix shadcn_daisyui.upgrade`).
- Shell ids: `shell`, `sidebar`, `main`, `nav-<id>`, `bar-<id>`, `bar-more`,
  `more-nav`, `user-menu`, `account-phone`, `search-open`, `sidebar-toggle`,
  `phone-header` and `environment-badge`. Account items are
  `user-menu-<id>` / `account-phone-<id>`, footer items `<id>` / `<id>-phone`.

## [0.19.0] - 2026-10-11

A creatable combobox, a fix for form controls that ignored LiveView
re-renders, and an alert that can hold actions and an icon. `create`,
`<:actions>` and `<:icon>` are opt-in; nothing existing needs a change.

### Added

- **`create` on `<.combobox>`** (shadcn's creatable pattern): when the search
  text matches no option label exactly (case and surrounding spaces ignored),
  a last `Add "<text>"` row with a plus icon appears, and when nothing matches
  it is the only row, replacing `empty`. Choosing it (click, Enter, or arrow
  keys to it) closes the list, shows the trimmed text as the selection and
  posts it like any value (`input` + `change` on the hidden input, so
  `phx-change` fires). `on_create="event"` also pushes
  `%{"id" => id, "value" => text}` so the app can save the new option and
  re-render the slots; the server's re-render wins, as for every pick. With
  `multiple`, Add ticks the new value, clears the search and keeps the list
  open. Blank text, an exact match and text over `create_max` (default 80,
  also the search box's `maxlength`) never offer Add. `create_label` sets the
  row text (default `Add "%{value}"`). The row is a `role="option"`, announced
  by its label and reachable through `aria-activedescendant` like the others.
  A value no option carries (just added, or saved but no longer in the list)
  still shows as the selection and as a checked row, and a
  `combobox-create` event with `{ value }` bubbles from the root.
- **`<:icon>` and `<:actions>` on `<.alert>`**, laid out like shadcn's alert:
  a 16px icon left of the title and description, and actions to the right of
  the text from `sm` (640px), below it and aligned with it on phones. Theme
  classes: `.alert-icon`, `.alert-content`, `.alert-actions`; hand-written
  daisyUI `.alert` markup without them keeps daisyUI's row layout.
- `<.radio_group>` label rows are 44px tall on touch (`pointer: coarse`), with
  desktop density unchanged. Theme class: `.radio-group`. Apps can drop their
  own `[&_label]:min-h-11 [&_label]:py-2`.
- Docs: a "Creatable (add a value)" Insurer example on the Combobox page, a
  "With an action" example and slot props on the Alert page, usage rules rows
  for `<.combobox create>` and the alert slots, and a creatable insurer
  combobox in the `/lab/csp` LiveView patch harness.

### Fixed

- **`<.switch>`, `<.checkbox>` and `<.radio_group>` kept their first-render
  state on LiveView re-renders.** `checked` and the field-derived `id`, `name`
  and `value` were set with `Map.update!/3`, which LiveView's change tracking
  doesn't see, so a `phx-change` that flipped a boolean (or changed the picked
  radio) never patched the control, even while a `<.reveal>` driven by the same
  value opened. They now go through `assign/3`, which also fixes
  `<.native_select>` and `<.textarea>` (same `apply_field/1`). An explicit
  `checked` attr still wins over the field, as does `value` on the radio group.
  LiveView tests in the demo app cover all five controls.
- `<.alert>` rendered its inner block in a `<p>`, so a description with a
  `<div>` or a button nested invalid HTML. It is now a `<div>` with the same
  text styles.
- The select/combobox hook now works on pages that also run
  `initShadcnDaisyui()` before LiveView mounts it: the hook attaches to the
  existing picker (needed for `on_create` to push).

## [0.18.0] - 2026-10-10

A time picker. `<.time_picker>` is new; nothing existing changes.

### Added

- **`<.time_picker>`**: a field-style trigger (clock icon, formatted time or
  placeholder) that opens scrollable Hours, Minutes, optional Seconds and
  AM/PM columns in a popover. Bind it with `field` (or `name` + `value`, a
  `Time` or ISO string); the hidden input posts a 24-hour `HH:MM`
  (`HH:MM:SS` with `seconds`) that an Ecto `:time` field casts, and every
  pick dispatches `input` + `change`. `hour_cycle={24}` drops AM/PM,
  `minute_step` sets the minute grid, `full_width` gives a 44px touch
  trigger. Each column is a `role="listbox"`: Up/Down pick, Left/Right move
  between columns, Enter or Esc closes. Opening scrolls every column to its
  value. The open popover and label survive LiveView patches and a changed
  server value wins; a `time-change` event with `{ value }` bubbles. Hook:
  `ShadcnTimePicker`. Theme classes: `.time-columns`, `.time-col`,
  `.time-option`.
- Docs: a Time Picker page under Forms & inputs.

## [0.17.0] - 2026-10-10

`<.accordion>` gets two opt-ins that turn it into a full section card: a
`<:header>` slot and `flush` rows. Both default to off, and an accordion that
uses neither renders the same markup as 0.16.1 (a test pins that output).

### Added

- **`<:header>`** on `<.accordion>`: content above the rows inside the same
  card, padded like a card body (a `card_title`, a `card_description`, maybe
  an action).
- **`flush`** on `<.accordion>`: rows run edge to edge. The card keeps no
  horizontal padding around them; each trigger and its open content carry the
  card body's 24px inset inside the row, and the chevron moves in with it. A
  1px `border-border` line separates the header from the first row and each
  row from the next, reaching both edges like table rows in a card, with none
  under the last row. The keyboard focus ring is inset so the card doesn't
  clip it, and the first and last rows round with the card's corners. Theme
  classes: `.accordion-flush`, `.accordion-header`, `.accordion-rows`.
- Docs: a "Section card (header + flush rows)" accordion example.

## [0.16.1] - 2026-10-10

Test-only release: no changes to the components, CSS or JS.

### Fixed

- The toast-layer browser test no longer fails intermittently in a full
  parallel run. It waited a fixed 450ms for a toast to enter, and under load
  the enter transition could start later, leaving the toast below the
  viewport when it was hit-tested. It now waits until the toast has settled
  (5s deadline).

## [0.16.0] - 2026-10-10

`<.dropdown_menu>` items get opt-in attributes for row-actions menus: a
destructive variant, a confirm prompt, extra event values, an id and a
disabled state, plus a menu-level `close_on_select`. All default to off, and an
item that doesn't use them renders the same markup, classes and events as
0.15.0 (a test pins that output).

### Added

- **`<:item variant="destructive">`**: `text-destructive`, with the hover /
  focus fill tinted like shadcn's `DropdownMenuItem variant="destructive"`
  (destructive at 10%, 20% in dark), via a new per-theme token
  `--menu-destructive-hover`, so a light island in a dark page (and the
  reverse) gets its own tint.
- **`<:item confirm="…">`**: renders `data-confirm`, so the browser asks
  before `phx-click` is sent (phoenix_html, imported in a stock Phoenix
  `app.js`). Name the object: "Remove Acme Marketing from Pat?".
- **`<:item values={%{…}}>`**: one `phx-value-<key>` per entry, for events
  that need more than an id. `phx-value-id` keeps working; when both are
  given, `values` wins for its own keys only.
- **`<:item id="…">`**: rendered on the item, for tests and focus.
- **`<:item disabled>`**: `aria-disabled="true"`, no `phx-click` or
  `data-confirm`, the variant's colors at 50% opacity and no pointer events.
- **`close_on_select`** on `<.dropdown_menu>`: the menu closes once an item is
  chosen (default unchanged: focus keeps it open until it blurs). One
  delegated listener in `shadcn-daisyui.js`, CSP-safe, no inline handlers.

### Fixed

- Clicking the placeholder / value text of a `<.select>` or `<.combobox>`
  trigger now opens it. Opening re-renders the label, which detached the
  clicked element, so the outside-click check closed the panel straight away.
  The date picker, date range popover and the docs data table's faceted filter
  use the same click-path check now.

## [0.15.0] - 2026-10-10

`<.sheet>` and `<.drawer>` get a header and a footer that stay put while only
the body scrolls, like shadcn's `SheetHeader` / `SheetFooter`.

### Added

- **`<:footer>` slot** on `<.sheet>` and `<.drawer>`: pinned to the bottom, a
  row (`flex items-center gap-2`) with the header's horizontal padding and
  safe-area padding at the bottom on phones (`env(safe-area-inset-bottom)`).
  With a short body the footer still sits at the bottom of the sheet. Typical
  footer: a ghost "Clear all" on the left and the primary action on the right
  (`ml-auto`; `grow sm:grow-0` lets it take the remaining width on phones).
- **`<:header>` slot** on both for content under the description that also
  stays put (e.g. a search box).
- `<.drawer>` gains `<:title>` and `<:description>` (centred on compact, start
  aligned from `sm`).
- **Scroll-edge lines**: a 1px `border-border` line between the body and the
  header / footer, shown only while content is scrolled under it (none at the
  top, none at the end, none when the body fits). `shadcn-daisyui.js` sets
  `data-scroll-top` / `data-scroll-bottom` on the dialog from the body's
  scroll position and size (a ResizeObserver, so LiveView patches that grow or
  shrink the body update it); the components keep both attributes across
  patches. No shadows, no motion, CSP-safe.
- Class recipe for raw HTML: `.sheet-header` / `.sheet-body` / `.sheet-footer`
  (and `.drawer-handle` / `.drawer-header` / `.drawer-body` / `.drawer-footer`)
  as direct children of the `<dialog>`.
- Docs: a long "Filters" sheet example (search in the header, "Clear all" and
  "Show 24 results" in the footer); the Default sheet and drawer examples use
  the footer. `/lab/csp`'s sheet is long enough to scroll and has a footer, to
  prove scroll position and edge lines survive patches.

### Changed

- **Sheet layout**: the sheet is a full-height column; the header, body and
  footer are sections and only the body scrolls (`min-height: 0; flex: 1;
  overflow-y: auto`), not the whole dialog. The body content renders inside
  `.sheet-body > div`. The drawer body scrolls the same way once the drawer
  reaches 85vh.
- The drawer's grab handle is now `.drawer-handle` (theme CSS) instead of a
  utility class list.
- Raw `<dialog class="sheet">` / `class="drawer-bottom"` markup without the
  section classes keeps the old padded, whole-dialog-scrolls behaviour.

## [0.14.0] - 2026-10-09

Chips animate in and out, and a closing `<.reveal>` collapses around its
last chip instead of snapping shut.

### Added

- **Chip motion** (`<.chip_row>`, `ShadcnChipRow` / `initShadcnDaisyui()`):
  a chip added after mount scales and fades in (`scale` 0.9 → 1 + opacity,
  150ms ease-out) and the chips, "+N" and actions after it slide over (FLIP
  on `translate`). A removed chip leaves the flow, scales and fades out where
  it stood while its neighbours slide into its place; "+N" recounts once it
  is gone, and a chip pulled out of "+N" then fades in. Removing `:action`
  content animates the same way. Works for LiveView patches, the hook's own
  removals in dead views, and chips other scripts add or remove (a
  MutationObserver). Transform and opacity only, through the Web Animations
  API (CSP-safe); instant under reduced motion. The first render is not
  animated.
- Each chip, its popover copy and the actions wrapper render a `phx-remove`
  (`JS.dispatch("chip-exit")` + a 180ms `JS.transition`), so LiveView keeps a
  removed chip for the length of a reveal collapse. When `open` turns false
  in the patch that removes the last chip, the reveal shrinks with the chip
  still visible inside it, as one motion.
- Docs: an "Add and remove (animated)" chip row example (adds chips, removes
  them including the last one, which closes its reveal), and the pattern in
  the reveal docs, `usage-rules.md` and `usage-rules/styles-motion.md` (a new
  "chip in / out" tier). `/lab/csp` gains an "Add a label" button.

### Changed

- **Chip DOM ids follow the chip's `value`** (`<id>-chip-v-<value>`, with a
  hash suffix when the value has characters outside `[A-Za-z0-9_-]`), and
  the chip `<li>` now carries the id. Index ids made a patch that removed one
  chip morph every later chip and drop the last node. Chips without a
  `value` keep index ids - pass `value` to get correct exit animations.
- The actions wrapper has an id (`<id>-actions`). `.chip-row`,
  `.chip-row-chips` and the popover list are `position: relative` (a leaving
  chip is positioned in them).
- `ShadcnChipRow` gains `beforeUpdate()` (records chip positions before a
  patch); `updated()` re-fits on a microtask so `phx-remove` exits are known
  first. Keyboard navigation and focus restoration skip leaving chips; focus
  moves off a removed chip as its exit starts.

## [0.13.0] - 2026-10-09

Tabs, outline buttons and fields follow shadcn's default (Vega) style, so a
toolbar of them reads as one family in light and dark.

### Changed

- **Tabs** (`.tabs-box` / `.tab`, so `<.tabs>`, `<.tab_nav>` and the recipe):
  the list is `h-9 p-[3px] rounded-lg bg-muted` and triggers fill it less 1px
  (29px, was 28px) with a transparent 1px border. Inactive text is
  `foreground/60` in light and `muted-foreground` in dark, hover `foreground`.
  The active tab stays `bg-background` + `shadow-sm` in light; in dark it is
  `bg-input/30` with a `border-input` border (it was `bg-background`, darker
  than the list). The tab nav's More trigger follows the same rules. A
  `<.tabs>` list holding its panels still grows to fit them.
- **`btn-outline`** (and every trigger using it, e.g. `<.dropdown_menu>`): dark
  is `bg-input/30 border-input`, hover `bg-input/50`, matching fields. Light
  stays `bg-background border-border shadow-xs`; hover is now `bg-muted` with
  `text-foreground` (was `accent` / `accent-foreground`, the same colors in
  the default theme).
- **Light field fill is transparent.** `--input-background` defaults to
  `transparent` in light (was `var(--background)`), so `.input`, `.select`,
  `.textarea`, `.file-input`, OTP slots and the `<.select>` / `<.combobox>` /
  date triggers take the card or muted surface under them, like shadcn's.
  Override `--input-background` to tint fields as before. Dark is unchanged
  (`input/30`).
- The light/dark fills for outline buttons and tabs come from new derived
  variables (`--outline-background`, `--outline-border`, `--outline-hover`,
  `--tab-foreground`, `--tab-active-background`, `--tab-active-border`), keyed
  on the theme name (`*-dark`). Brand themes get them without restating, and a
  light panel inside a dark page (or the reverse) resolves its own theme. The
  field-trigger hover uses `--outline-hover` (dark is still `input/50`).

### Fixed

- `<.select>` / `<.combobox>` placeholders and the date picker label truncate
  on one line instead of wrapping in a narrow trigger (which made it taller
  than the fields beside it). Field-style triggers never wrap.
- The docs' "Fields on every surface" panels: the pickers are `full_width`,
  so they no longer overflow their grid cells.

### Added

- Docs: a toolbar (tabs, search, outline button, outline dropdown, primary
  button) side by side in light and dark, on the page and on a card, on the
  Dark mode page.
- A headless-Chrome test that compares the toolbar's computed colors with the
  shadcn recipe values in both themes, including a light panel inside a dark
  page and the reverse.

## [0.12.0] - 2026-10-09

Toasts and flashes show above sheets, dialogs, drawers and the command
palette, and stay clickable there.

### Added

- **Toasts in the top layer, above open modals.** Toasts render in a
  `popover="manual"` layer in the browser's top layer (UA popover styles
  cleared, placement unchanged). A modal `<dialog>` makes everything outside
  it inert, even a popover painted above it, so while a modal is open the
  layer moves into the topmost one and is shown again (re-raised). It follows
  `shadcn:show-modal`, the dialog `toggle` / `close` events, and any
  `showModal()` call (via the `open` attribute). Toasts stay clickable and
  swipeable above the backdrop, never take focus, and Esc still closes the
  modal, not the toast.
- `<.dialog>`, `<.sheet>`, `<.drawer>` and `<.command>` render an empty
  `<div id="…-toasts" data-toast-host phx-update="ignore">` slot, so LiveView
  patches inside an open modal leave the toasts alone.
- **Flash as Sonner.** `<.flash>` (`ShadcnDaisyui.CoreComponents`) renders as
  a Sonner toast, so apps keep Phoenix's generated `Layouts.flash_group` and
  don't override `flash/1`. Info shows a success check and clears after
  5 seconds (`duration`), paused on hover or focus; errors stay until closed.
  Closing or timing out pushes `lv:clear-flash`. The reconnect flashes
  (`hidden` toggled by `phx-disconnected` / `phx-connected`) show and hide as
  toasts. Without the JS, the flash renders in place.
- `position` on `<.flash>` and `<.flash_group>`, same values as `<.toaster>`
  (default `bottom-right`).
- On compact screens (under 640px), bottom toasts and flashes sit above the
  page's bottom `dock`.
- Sonner's `onDismiss` / `onAutoClose` toast options.

### Changed

- Each toast carries its role: `role="alert"` (assertive) for error toasts,
  `role="status"` otherwise. The JS-built layer is the labelled
  "Notifications alt+T" live region; the `<.toaster>` section is now a hidden
  options holder.
- `<.flash>` markup: the role is on the notice inside, not the positioned
  container, and the close button (`data-flash-close`) carries the
  `phx-click`, not the whole flash. Info uses `hero-check-circle-solid`,
  error `hero-x-circle-solid`.
- The `ShadcnToaster` hook is optional: server toasts arrive through a
  `phx:shadcn:toast` window listener.

### Fixed

- `push_toast/3` toasts could silently never appear on LiveView pages. The
  toaster sits in the root layout, outside every LiveView, where LiveView
  often doesn't mount its hook.
- A `push_toast/3` `action` / `cancel` `event` never reached the server
  ("unable to push hook event. LiveView not connected"). It is now pushed to
  the page's main LiveView.

## [0.11.0] - 2026-10-09

Sheet width is settable, and matches shadcn's Sheet.

### Added

- `<.sheet size="sm|default|lg|xl">` (20rem, 24rem, 32rem, 40rem from the `sm`
  breakpoint), via `sheet-sm` / `sheet-lg` / `sheet-xl` classes that set the
  new `--sheet-width` variable. Width classes (`sm:w-[28rem]`, `max-w-*`) and
  `[--sheet-width:…]` on the sheet also work now.

### Changed

- `dialog.sheet` is 75% wide on phones and 24rem from `sm` (shadcn's
  `w-3/4 sm:max-w-sm`), was a fixed 20rem. Pass `size="sm"` for the old
  width. Still capped at 90vw, slide animation unchanged.

### Fixed

- `<.sheet class="sm:w-96">` (any width class) had no effect, because the
  sheet's width was set outside any CSS layer and beat every utility. The
  width now lives in `@layer components`.

## [0.10.1] - 2026-10-09

Fixes a 0.10.0 regression that broke every `<.chip_row>`.

### Fixed

- `<.chip_row>` threw `ReferenceError: collapsed is not defined` on mount,
  resize and every LiveView patch (aborting the rest of the patch), so rows
  never fit and "+N" never appeared. The chip row's fit referenced the tab
  nav's new collapsed state; a chip row never collapses, so it now only sets
  `data-squeezed`. `<.tab_nav>` is unaffected.

### Added

- A browser test (`test/shadcn_daisyui/js/`) that mounts the real chip row and
  tab nav markup with the real JS in headless Chrome, driven by a small
  dependency-free Node script; it is skipped when Node or Chrome is missing.

## [0.10.0] - 2026-10-09

`<.tab_nav>` degrades cleanly on very narrow widths.

### Added

- **Collapsed `<.tab_nav>`.** When the active tab and the More trigger don't
  fit side by side, every tab now folds into the menu and the trigger names
  the active tab with its count (e.g. "Needs a call 17 ▾"), styled as the
  active tab. If even that is too wide the label truncates with an ellipsis;
  the count and chevron never clip. The menu lists every tab in order with
  the active one checked. The hook sets `data-collapsed` on the root (kept
  across LiveView patches); wider rows behave exactly as before. Plain-HTML
  recipes: the trigger's default label spans carry `data-tab-nav-default` and
  the active tab's label and count are added as `data-tab-nav-current` spans.
- Docs: a "Narrow: everything in the menu" Tab Nav example whose preview
  starts at 25% width (examples can now set a starting slider `width`).

### Fixed

- A More trigger wider than the row (no active tab, long active menu item)
  now truncates its label instead of overflowing the row.

## [0.9.0] - 2026-10-09

Dropdown menu fixes: icon-only triggers and a consistent stacking order for
floating content.

### Added

- **`chevron` on `<.dropdown_menu>`** (default `true`): `chevron={false}` drops
  the trailing chevron for icon-only triggers such as a ⋯ row-actions button.
  New **`aria-label`** attr names the trigger itself (it previously fell
  through to the wrapper). Documented with
  `trigger_class="btn btn-ghost btn-square btn-sm"`; the docs page gains an
  "Icon-only trigger" example and a props table.
- **Stacking layers** in `usage-rules/styles-shape-elevation.md` (and
  `usage-rules.md`): in-page sticky layers (table headers, toolbars, bottom
  bars) `z-10`, floating content `z-50`, modals in the browser's top layer.

### Fixed

- **One floating layer, `z-50`, above sticky layers.** Floating surfaces sat
  at mixed levels: `<.dropdown_menu>` and `<.popover>` carried a `z-10` class
  that never applied (daisyUI pins `.dropdown .dropdown-content` to `z-999` at
  a higher specificity), and the select / combobox / date-picker / date-range
  panels, the tab-nav More menu and the chip-row popover used `z-30`. All of
  them, like the context menu, now use `z-50`: the components' markup says
  `z-50`, the theme sets `.dropdown .dropdown-content` to 50 (down from
  daisyUI's 999), and `.popover-panel` gets a zero-specificity `z-index: 50`
  default for plain-HTML recipes. Docs recipes updated to match. The
  elevation rules also explain the usual real cause of a menu hidden under a
  sticky header: an ancestor that creates a stacking context.

## [0.8.0] - 2026-10-09

Width-aware rows and a sanctioned collapsing-row animation. New docs pages:
**Tab Nav** (`/docs/components/tab-nav`), **Chip Row** (`/docs/components/chip-row`)
and **Reveal** (`/docs/components/reveal`), each with specs, accessibility and
SwiftUI notes. Overflow examples get a preview-width slider.

### Added

- **`<.tab_nav>`** (`ShadcnTabNav` hook): a row of link tabs (`navigate` /
  `patch` / `href`, optional `count` pill, `active`) in the boxed tabs look.
  Tabs show while they fit; the ones that would be squeezed move, in order,
  into a trailing More menu (floating-content panel). `:menu_item` slots add
  extra entries (`group` sections such as "Mine" / "Shared", `icon`, `active`),
  e.g. "Manage views…". The active tab always stays visible, swapping out the
  last visible one; an active `:menu_item` names the More trigger ("More: Open
  bugs"). Re-fits on resize (ResizeObserver), after web fonts load and after
  LiveView patches (`updated()`), in one pass before paint, so the row never
  jumps; until the hook has measured, tabs clip instead of wrapping. Keyboard:
  Left / Right / Home / End across the tabs and into More, Down / Enter / Space
  opens the menu and focuses its first link, arrows inside, Esc returns to More
  (without closing a surrounding sheet). `<nav aria-label>` + `aria-current`,
  disclosure button (`aria-expanded`, `aria-controls`); 40px tabs and 44px
  menu rows on touch.
- **`<.chip_row>`** (`ShadcnChipRow` hook): one line of removable badge chips
  (`<:chip value on_remove remove_label removable>`, `variant="secondary|outline"`).
  Chips that don't fit collapse into a "+N" chip (named "Show N more") that
  opens a popover listing them, each still removable; `<:action>` content (e.g.
  "Clear all") always keeps its space. Remove buttons are named "Remove" plus
  the chip text. In LiveView `on_remove` is a `phx-click`; without it the hook
  dispatches a cancelable `chip-remove` event (`{ value, index }`) and removes
  the chip itself, and `data-chip-row-clear` buttons do the same for every chip
  (`chip-clear`). After a removal focus moves to the chip that took its place,
  then +N, then the last chip. 32px chips and 44px hit areas on touch.
- **`<.reveal open>`** and the `.reveal` / `.reveal-track` recipe: slides a row
  open and closed with `grid-template-rows` 0fr ↔ 1fr plus opacity, 180ms
  ease-out, no transition under reduced motion. Closed content is
  `visibility: hidden` (out of the tab order and the a11y tree); once open the
  track stops clipping, so a popover inside (the chip row's +N) isn't cut off.
  The server owns `open`; for client toggles, `<button data-reveal-toggle="id">`
  (CSP-safe delegated listener, sets `aria-expanded` / `aria-controls`) with
  `client` on the reveal so patches keep its state.
- `/lab/csp` now exercises the tab nav (counts change width every tick, a
  `?view=` patch per tab) and a chip row of the active filters inside a reveal
  (server-side removal).

### Changed

- **Motion rules** (`usage-rules/styles-motion.md`): the collapsing-row reveal
  is the one sanctioned layout animation, for rows that appear and disappear in
  the page flow (filter chips, inline alerts, bulk-action bars), the way the
  accordion / collapse already animates. New "row reveal" tier in the table and
  on the Motion guide page, with a live sample.
- **Navigation rules**: in-page link-tab rows are `<.tab_nav>`; tab rows never
  wrap or scroll. `usage-rules.md` gains the three components, the reveal
  recipe and the non-negotiables for overflowing and collapsing rows.

## [0.7.0] - 2026-10-09

Multi-select and form-bound date ranges, matching shadcn-svelte (bits-ui
`Select type="multiple"` and the data-table faceted filter: Popover + Command
with checkbox rows). New docs pages: **Multi Select** (`/docs/components/multi-select`)
and **Date Range Picker** (`/docs/components/date-range-picker`), each with specs,
accessibility and SwiftUI notes.

### Added

- **`multiple` on `<.select>` and `<.combobox>`** (not a new component). Options
  become checkbox rows (16px primary box, filled when selected), the list stays
  open while toggling, and a Clear row (`clear_label`) appears once anything is
  selected. The trigger shows the placeholder, or up to two selected labels then
  a muted "+N". `<.combobox multiple>` keeps its search box (Space types, Enter
  toggles). Keyboard: arrows, Home/End (select), Space/Enter toggle, Tab to Clear,
  Esc closes (without closing a surrounding sheet).
- **Form binding for multiple**: `value` takes a list; the component emits an
  always-present `name=""` input plus one `name[]` input per value, so params are
  `["a", "b"]`, and `""` when cleared (Ecto casts it to the field default). Every
  toggle dispatches `input` + `change` on the form, so `phx-change` fires. A
  `select-change` / `combobox-change` event with `{ value }` bubbles from the root.
- **`field` on `<.select>` and `<.combobox>`** (single and multiple): derives
  name and value, gives the trigger the field id (so `<.label for>` / `<.field>`
  name it), and sets `aria-invalid` (destructive border and ring) once the field
  is used and has errors.
- **`count` on `:option`** - a right-aligned muted `font-mono text-xs` number, as
  in the faceted filter.
- `full_width`, `disabled`, `aria-label` / `aria-labelledby` on both pickers;
  `search_placeholder` and `empty` on the combobox.
- **`<.date_range>` form binding**: `start_name` / `end_name` + `start` / `end`
  (ISO `YYYY-MM-DD` hidden inputs, like `<.range_calendar>`). They dispatch
  `input` + `change` once per complete range (two days or a preset), not per
  click; a half-picked range is dropped on close. The label is server-rendered,
  and `range-change` bubbles with `{ start, end }`. Also `months` (default 2).
- **`<:preset>` slots on `<.date_range>`**: `<:preset label="This month" start end>`,
  or `<:preset label="Last 7 days" days={7}>` computed in the browser (for cached
  and static pages). A column beside the calendar, wrapping above it on compact.
- **Customizable native select**: where `appearance: base-select` is supported
  (Chrome 135+), `.select`'s `::picker(select)` uses the floating-content recipe
  (popover surface, `ring-1 ring-foreground/10`, `shadow-md`, `rounded-md`, `p-1`),
  options get accent highlight, `rounded-sm` and the check on the right, and the
  duplicate `::picker-icon` is hidden. daisyUI >= 5.1 opts `.select` into
  base-select with its own picker look; this replaces it. `multiple` / `size`
  list boxes keep native rendering.

### Changed

- **Select / combobox / date-picker / date-range state survives LiveView
  patches.** The hooks now implement `updated()`: an open list or popover, the
  label, checks, search text and hidden inputs are re-applied after every patch.
  The server's value wins whenever it changes (a reset, a cap); echoes of the
  user's own changes are ignored, so fast toggling never snaps back.
- Select and combobox share one JS engine with delegated listeners, so options
  the server adds or replaces keep working. The trigger label is the option's
  text (it was the `value`), rendered on the server for a preselected value.
- Select triggers are `role="combobox"` (bits-ui), option rows are
  `tabindex="-1"`, and clicking a row no longer moves focus off the trigger.
- Option rows are 44px tall on touch (`pointer: coarse`), single and multiple.
- `<.date_picker>` / `<.date_range>`: Esc closes the popover, and opening with
  the keyboard focuses the calendar.

### Fixed

- The combobox search box no longer triggers the surrounding form's
  `phx-change` on every keystroke.
- `<.calendar>`, `<.date_picker>` and `<.date_range>` calendars are no longer
  wiped by a LiveView patch (`phx-update="ignore"` on the JS-built grid).
- `initShadcnDaisyui()` plus the LiveView hooks no longer double-bind the select,
  combobox and date pickers on the same element.

### Docs

- The strict-CSP LiveView lab (`/lab/csp`) gains a form with a multiple select,
  a multiple combobox whose counts change on every tick, and a bound date range
  with presets, to prove open state, `phx-change` and server resets under patches.
- Select, Combobox, Date Picker and Select Native pages: multiple / form / props
  notes, and stale specs refreshed (floating ring instead of a border, 44px touch
  rows, Esc on date pickers).
- The docs site no longer uses inline event handlers anywhere except the
  deliberate canary on `/docs/dark-mode`. Sonner, Attachment, Message, Bubble
  and Marker previews use `data-toast*` attributes, the Range Calendar booking
  form uses `data-demo-booking`, and the motion guide's replay buttons use
  `data-motion-play`, each handled by a delegated listener in the demo's
  `app.js`. A test sweeps every exported page for `on*=` attributes.

## [0.6.0] - 2026-10-09

Dark-mode and CSP parity with shadcn-svelte's neutral dark theme
(`registry-base-colors.ts`, `style-vega.css` and its popover, dropdown-menu,
dialog, sheet, select, tooltip and command components). The shadcn token values
themselves are unchanged - they already matched. See the new **Dark mode & CSP**
docs page (`/docs/dark-mode`) for every change side by side in light and dark.

### Breaking

- **Requires `phoenix_live_view ~> 1.1`** (was `~> 1.0`). The overlay components
  now open/close through `Phoenix.LiveView.JS` and keep `open` with
  `JS.ignore_attributes/1`, both of which need 1.1. The page must call
  `liveSocket.connect()` (Phoenix's default `app.js` does; LiveView 1.1 runs JS
  commands on dead views too). Without a LiveSocket, open dialogs with
  `el.showModal()` or invoker commands (`<button commandfor="id" command="show-modal">`).
- **Brand themes generated before 0.6.0** carry a copy of the old dark block, so
  they keep the old dark field fill and base-200/base-300. To adopt the fixes,
  replace these three lines in your `[data-theme="<brand>-dark"]` block:
  `--input-background: color-mix(in oklab, var(--input) 30%, transparent);`,
  `--color-base-200: var(--muted);`, `--color-base-300: var(--border-color);`
  (or regenerate with `mix shadcn_daisyui.gen.theme`).

### Changed

- **Dark form fields** use shadcn's `dark:bg-input/30`.
  `--input-background` (dark): `var(--background)` (oklch 0.145, darker than
  cards and popovers) → `color-mix(in oklab, var(--input) 30%, transparent)`.
  Applies to `.input`, `.select`, `.textarea`, `.file-input`, the
  `<.select>` / `<.combobox>` / date-picker / date-range triggers and the OTP
  slots, on the page, on cards and inside sheets, dialogs and popovers. Light
  mode is unchanged.
- **Custom select / combobox / date-picker / date-range triggers**: border
  `var(--border-color)` → `var(--input)` (the field border; identical in light,
  white/10% → white/15% in dark); dark hover `var(--accent)` →
  `color-mix(in oklab, var(--input) 50%, transparent)` (shadcn `dark:hover:bg-input/50`).
- **OTP slot**: background `transparent` → `var(--input-background)`, and it now
  carries `shadow-xs` like the other fields.
- **`--color-base-200` (dark)**: `oklch(0.205 0 0)` → `var(--muted)` (0.269).
  It equalled `--card`/`--popover`, so `bg-base-200` hover and selected fills were
  invisible on cards and in popovers. Side effects: daisyUI's plain `.btn`,
  zebra rows, pinned table columns and disabled fields step up to 0.269 too.
- **`--color-base-300` (dark)**: `oklch(0.269 0 0)` → `var(--border-color)`
  (`oklch(1 0 0 / 10%)`), so `border-base-300` matches shadcn's translucent
  border. Nothing in the package uses base-300 as a fill except daisyUI's
  `.avatar-offline` dot, which is now pinned to `var(--muted)` in dark (it would
  have gone see-through), and the drawer grab handle, now `bg-muted`. Zebra-row
  hover and daisyUI tab borders become translucent, as intended.
- **One modal backdrop**: `.modal` `oklch(0 0 0 / 0.4)` and the `dialog.sheet`,
  `dialog.drawer-bottom`, `dialog.command-dialog` `::backdrop`s
  `rgb(0 0 0 / 0.5)` → all `oklch(0 0 0 / 0.5)`. This follows shadcn/ui's
  `bg-black/50` rather than vega's `bg-black/10` + `backdrop-blur-xs`: blur
  repaints everything behind the overlay on every frame of the 300ms
  sheet/drawer slide, and black/10 leaves too little separation for the flat
  surfaces this package uses elsewhere.
- **Floating content** (`.dropdown-content.menu`, non-menu `.dropdown-content`
  popovers, `.popover-panel` select/combobox/date panels, `.context-menu`):
  `1px solid var(--border-color)` + `shadow-sm` → no border, a 1px
  `ring-foreground/10` (`0 0 0 1px color-mix(in oklab, var(--foreground) 10%, transparent)`)
  + `shadow-md` (`0 4px 6px -1px / 0 2px 4px -2px`, 10% black).
- **`.modal-box`**: `rounded-lg` + 1px border + `shadow-sm` → `rounded-xl`, the
  same 1px ring, `shadow-lg`.
- **Command dialog**: `rounded-lg` + 1px border + `shadow-sm` → `rounded-xl`,
  ring, `shadow-lg` (vega's `rounded-xl` command dialog).
- **Sheet and drawer**: `shadow-sm` → `shadow-lg` (shadcn's sheet).
- **Tooltip**: background `var(--primary)` / text `var(--primary-foreground)` →
  `var(--foreground)` / `var(--background)` (`bg-foreground text-background`).
- New shadow tokens `--shadow-md` and `--shadow-lg` (Tailwind v4 values) beside
  `--shadow-xs`/`--shadow-sm`.
- Usage rules: the elevation ladder (`styles-shape-elevation.md`) now has a
  floating level (`shadow-md` + ring) and an overlay level (`bg-black/50` +
  `shadow-lg`); popovers and menus are `rounded-md` and dialogs `rounded-xl`, as
  the CSS already rendered. `styles-color.md`, the main Theme tokens section and
  the recipes now say `border-border` for borders, `bg-muted`/`bg-accent` for
  hover and selected states, and never `bg-base-300` as a fill.

### Fixed

- **Strict CSP**: no component renders an inline event handler any more, so they
  work under `script-src 'self' 'nonce-…'`. `<.dialog>`, `<.sheet>`, `<.drawer>`
  and `<.command>` triggers use `phx-click={show_modal(id)}`, the sheet's close
  button `hide_modal(id)`, and backdrop-click closing moved from per-element
  `onclick` into one delegated listener in `shadcn-daisyui.js` (for `.sheet`,
  `.drawer-bottom`, `.command-dialog`). Esc still closes natively.
- Clicking a sheet's or drawer's own padding no longer closes it. The old inline
  check (`event.target === this`) treated the panel's padding as backdrop; the
  listener now compares the click point with the panel rect.
- Every modal `<dialog>` carries `phx-mounted={JS.ignore_attributes(["open"])}`,
  so an open dialog stays open when a LiveView patch re-renders it.
- Docs recipes for dialog, alert dialog, sheet, drawer and command open/close
  with invoker commands (`commandfor` / `command`) instead of `onclick`.
- Docs site: the theme toggle no longer reverts to light on every page load (the
  root layout hardcoded `data-theme`, which made the stored choice unreachable).

### Docs

- New `/docs/dark-mode` page: the before/after table above, fields on page / card
  / popover, hover and selected fills, floating surfaces and all four overlays in
  light and dark, served under a strict nonce CSP (header + meta tag) with a live
  violation counter and an inline-handler canary that must be blocked.
- New `/lab/csp` LiveView (not part of the static export): overlays under the
  same policy, re-rendered every 500ms, to show an open dialog survives patches.

## [0.5.0] - 2026-10-04

### Added

Seven components shadcn-svelte added since this package was set up, matching its
default ("vega") style. The composition components are styled by `data-slot` /
`data-variant` attributes like upstream (zero-specificity selectors, so a utility
class on the element always wins), and each has a docs page with Specs,
Accessibility, and SwiftUI sections.

- **Item** - `<.item>`, `<.item_group>`, `<.item_separator>`: a row with media
  (`icon` / `image`), title, description, actions, and optional header/footer;
  `variant="default|outline|muted"`, `size="default|sm|xs"`, `href`/`navigate`/
  `patch` turn the row into a link.
- **Attachment** - `<.attachment>`, `<.attachment_group>`, `<.attachment_action>`:
  a file or image tile with `state="idle|uploading|processing|error|done"` (dashed,
  shimmering, dimmed, or destructive-tinted), three sizes, horizontal/vertical
  orientation, labeled icon actions, and an optional full-tile `<:trigger>`.
- **Message** - `<.message>`, `<.message_group>`: a conversation turn with avatar,
  header, content, footer, and `align="start|end"`.
- **Bubble** - `<.bubble>`, `<.bubble_group>`: seven variants (default, secondary,
  muted, tinted, outline, ghost, destructive), alignment, edge reactions, and
  `as="button"` / `as="a"` for suggested replies.
- **Marker** - `<.marker>`: an inline transcript line (default, separator, border)
  with an icon slot, `status` (role=status), and `shimmer`. Also ships a `.shimmer`
  utility class (respects reduced motion).
- **Sonner** - a real toast system replacing the docs-only `showToast()` stub:
  `toast()` / `toast.success|info|warning|error|loading()` / `toast.promise()` /
  `toast.dismiss()` exported from `shadcn-daisyui.js`, with descriptions, action
  and cancel buttons, per-toast position, a collapsed stack that expands on hover or
  focus, pause-on-hover timers, swipe to dismiss, and the Alt+T hotkey. Render
  `<.toaster />` (options: `position`, `rich_colors`, `close_button`, `expand`,
  `duration`) once in the root layout; from a LiveView use
  `push_toast(socket, "Saved", type: :success, action: %{label: "Undo", event: "undo"})`
  (needs the new `ShadcnToaster` hook).
- **Range Calendar** - `<.range_calendar>`: an inline date-range calendar (1 or 2
  months) that binds to two form fields via `start_name` / `end_name` (ISO dates in
  hidden inputs that dispatch `input` + `change`) and emits a `range-change` event.
  New `ShadcnRangeCalendar` hook.


### Changed

- **Surface-color guidance now matches shadcn and the theme CSS.** The rules said
  `bg-base-100` was for "page and cards", but in `shadcn-dark` `--background`
  (oklch 0.145) is darker than `--card` / `--popover` (oklch 0.205), so apps
  following them painted card-level surfaces darker than cards. `usage-rules.md`
  and `usage-rules/styles-color.md` now give each surface one role: page
  `bg-base-100` / `bg-background`; cards and opaque fills inside a card `bg-card`;
  overlays (sheets, dialogs, popovers, dropdown/command content) `bg-popover` +
  `text-popover-foreground`; subtle insets `bg-base-200` / `bg-muted`. New rule: a
  sticky `<thead>` (or sticky footer bar) inside a card uses `bg-card`, since the
  table header has no fill of its own. The token → SwiftUI table gains `sdCard` and
  `sdPopover` rows, and the docs-site examples that used `bg-base-100` for cards
  and dialog mocks now use `bg-card` / `bg-popover`.
- **Every calendar is keyboard navigable.** `<.calendar>`, `<.date_picker>`,
  `<.date_range>`, and `<.range_calendar>` now use a single roving tab stop with
  Arrow keys (day/week), Home/End (week edges), and PageUp/PageDown (month; Shift
  for year), the view following focus across months; day cells get the 3px focus
  ring and the month buttons get `aria-label`s.
- **Deprecated: `<.toast_host>` and `showToast()`.** `toast_host/1` now renders a
  `<.toaster>` (keeping the `toast-host` id) and `showToast(variant)` calls
  `toast()`, so existing layouts and calls keep working; move to `<.toaster />` and
  `toast()`. The docs-site Toast page is now Sonner (`/docs/components/toast`
  redirects).
- **`.drawer-side` panels use the popover surface.** `.drawer-side > .menu` and
  `.drawer-side > :where(aside, nav, div)` now paint `--popover` /
  `--popover-foreground` (was `--background` / `--foreground`), matching
  `dialog.sheet`, since a drawer slides over content. A persistent app sidebar
  should use `<.sidebar_layout>`, which stays on the page surface.

## [0.4.0] - 2026-10-04

### Upgrading from 0.3

The theme-toggle transition guard is now scoped to theme swaps (see Changed), so
anything that sets `data-theme` directly will fade-flicker on light/dark swap.
Re-run `mix shadcn_daisyui.install` (idempotent) - it now wraps Phoenix 1.8's
stock theme script in the guard - or switch your toggle to `setTheme` from
`shadcn-daisyui.js`. A hand-written theme script needs the same wrap:

```js
const setTheme = (theme) => {
  document.documentElement.classList.add("theme-transition");
  // ... set or remove data-theme as before ...
  requestAnimationFrame(() =>
    requestAnimationFrame(() => document.documentElement.classList.remove("theme-transition"))
  );
};
```

### Added

- **`priv/tokens.json`** - a machine-readable single source of truth for the
  color tokens (name, light value, dark value, role group), mirroring the values
  in `priv/static/shadcn-daisyui.css`. Intended to power a Tokens reference page,
  per-component specs, and the Swift-package sync. An agreement test in the demo
  fails CI if the JSON and the CSS drift apart.
- **Validated docs catalog schema** - the docs-site component catalog is now
  built through a `Catalog.Spec` struct that enforces required fields and rejects
  unknown/typo'd keys, with a test suite (schema validation, sidebar-group
  coverage, render-every-component-page) that fails CI on drift.
- **Per-component Specs, Accessibility, and Native (SwiftUI) sections** across all
  77 components in the docs site. Specs render anatomy, token-expressed
  measurements, and the tokens a component consumes as live color swatches;
  Accessibility renders the keyboard map plus role/ARIA, focus, screen-reader,
  touch-target, and reduced-motion notes (grounded in each component's real markup
  and JS); Native shows the SwiftUI equivalent with an honest parity badge
  (`ios_status`). All three are schema-validated and exported to the AI markdown /
  `design-guidelines.md` bundle. Design metadata lives in per-group enrichment
  files (`catalog/enrichment/*.ex`) merged onto the base catalog by slug.
- **Tokens reference page** (`/docs/tokens`) - every color token grouped by role,
  shown as light/dark swatch pairs with OKLCH values, read from `priv/tokens.json`.
- **Visual polish:** labeled SVG anatomy diagrams (numbered to match the anatomy
  list) on Button, Input, and Card; rendered Do/Don't example pairs on Button,
  Input, and Dialog; and interactive "Replay" motion demos on the Motion
  guidelines page driven by the Web Animations API (so they survive the
  instant-theme transition guard). Do/Don't pairs are schema-validated and
  exported to the AI markdown.
- **`setTheme(theme)` export in `shadcn-daisyui.js`** - switches the active theme
  flicker-free by adding the `theme-transition` class, swapping `data-theme`, and
  dropping the class on the next frame. Wire it to your theme control (or the
  standard `phx:set-theme` event) instead of setting `data-theme` directly.
- **`<.select>` and `<.combobox>` are now form-bindable.** Pass `name` (and
  `value`) and the component emits a hidden `<input>` the JS hook keeps in sync
  (dispatching `input` + `change` so LiveView `phx-change` fires), so the
  shadcn-style dropdowns can back a real changeset field. A preselected `value` is
  reflected in the trigger on mount, so edit forms show the current selection. Also
  fixes the combobox check icon, which never toggled (it queried `svg`, but the
  mark is a `hero-check` span).

### Changed

- **Repository moved to the `infinity-home-services` GitHub organization.** All
  three repos (`shadcn_daisyui`, `shadcn_daisyui_swift`, `shadcn_daisyui_design`)
  now live under `github.com/infinity-home-services`. Updated the package
  `@source_url`, install snippets in the README and docs site, the Pages URL
  (`infinity-home-services.github.io/shadcn_daisyui`), and the cross-repo
  references in the "Sync design guidelines" CI workflow. GitHub redirects the old
  `N00nDay/*` URLs for reads, but pushes and the design-sync workflow require the
  new owner. (The `SYNC_TOKEN` secret must be reissued as a fine-grained PAT scoped
  to the new org's consumer repos.)
- **Docs-site navigation & component pages.** The catalog sidebar now groups
  components by function (Forms & inputs, Actions, Navigation, Overlays, Feedback
  & status, Data display, Layout), alphabetized within each group, and every
  component page splits its content into Usage and Design & specs tabs.
- **`usage-rules.md`: documented the `context-menu` and bottom-`dock` recipes**
  (previously shipped in the JS/demo but absent from the consuming-app rules), and
  clarified that the `ShadcnDataTable` JS hook is docs-demo only - apps build data
  tables with `<.table>` + LiveView events.
- **Layout guidelines: content-width rationale + a dense/data-entry-form
  exception.** `usage-rules/foundations-layout.md` now explains *why* prose and
  forms are width-capped (the readable measure, not the container) and sanctions a
  wider `max-w-2xl`-`max-w-4xl` two-column field grid for data-entry-heavy forms
  (service tickets, work orders) on medium/expanded screens, while keeping the
  single-column `max-w-md` default for short/sequential forms and all compact
  screens.
- **Theme-toggle transition guard is now scoped, not global.** The rule that
  zeroes out `transition-duration` previously applied to every element at all
  times, silently killing any consumer hover/focus/micro transitions. It now fires
  only while `<html>` carries the `theme-transition` class (added for the duration
  of a swap by `setTheme`), so the toggle stays flicker-free while ordinary
  transitions work again. Apps that switch the theme by setting `data-theme`
  directly should move to `setTheme` to keep the swap from fading.
- **`mix shadcn_daisyui.install` patches Phoenix's stock theme script.** For root
  layouts using Phoenix 1.8's inline `phx:set-theme` script, the installer now
  wraps its `setTheme` in the `theme-transition` guard (add the class, swap
  `data-theme`, remove it after the next frame) instead of leaving the layout
  untouched. Already-guarded scripts are left alone.
- **Form controls no longer hard-set `background-color: transparent`.** `.input`,
  `.textarea`, `.select`, and `.file-input` (plus the custom `<.select>` /
  `<.combobox>` triggers) now use `var(--input-background)`, which defaults to
  `var(--background)`, so fields stay legible on tinted surfaces (e.g. inside a
  `.modal-box`). Retint all fields by overriding `--input-background` (per app or
  per `[data-theme]`); a one-off `bg-*` utility still needs `!` since the base
  rule lives in `@layer utilities`.

## [0.3.0] - 2026-06-11

### Added

- **Design guidelines layer** - ten platform-portable guideline files under
  `usage-rules/` covering Foundations (platforms, accessibility & content,
  layout, spacing, navigation, interaction) and Styles (color usage, typography
  & icons, shape & elevation, motion). Each file pairs terse agent rules with
  reference tables in dual units (rem/px for web, pt for iOS/iPadOS), tagged
  `[web]`/`[ios]` where platform-specific. `usage-rules.md` gains a
  "Design guidelines" section inlining the load-bearing values and indexing the
  files; ExDoc groups them under Foundations/Styles.

### Changed

- **Theme toggle is now instant** (no color fade). Fading between light and dark
  inherently flickers: a fading background sweeps through the lightness of the
  text/borders in front of it, so they cross at a gray midpoint and briefly lose
  contrast (text vanishes, borders trail). No fade - however synchronized -
  avoids that, so the theme switches instantly instead (flicker-free, like
  Tailwind's and GitHub's sites). One CSS rule forces `transition-duration: 0` on
  every element except the components whose own enter/exit animations must stay
  (dialog, drawer, tooltip, carousel, skeleton, countdown). Replaces the earlier
  JS transition window and the synchronized-CSS-fade attempts, both of which
  hit this inherent crossover. Hover/focus color changes are instant too (the
  cost of doing it without a JS guard).
- Docs site now imports the theme CSS/JS straight from the package source
  instead of keeping copies that drift.

## [0.2.0] - 2026-06-11

### Added

- `usage-rules.md` (+ `usage-rules/forms.md`, `usage-rules/theming.md`) - design-system
  rules consuming apps sync into their `AGENTS.md`/`CLAUDE.md` via the `usage_rules` package.
- `ShadcnDaisyui.FormComponents` - `Phoenix.HTML.FormField`-aware `input`, `checkbox`,
  `switch`, `radio_group`, `textarea`, `native_select`, `field`, `error` with
  configurable error translation (`config :shadcn_daisyui, :translate_error, {Mod, :fun}`).
- `ShadcnDaisyui.CoreComponents` - drop-in replacement for Phoenix 1.8 generated
  core components (`input`, `button`, `error`, `header`, `table`, `list`, `icon`,
  `flash`, `flash_group`) styled by the theme; generators work unmodified.
- New function components: dialog/modal, dropdown_menu, tabs, tooltip, accordion,
  breadcrumb, pagination, avatar, progress, skeleton, sheet, drawer, command,
  popover, sidebar, toast/flash bridge.
- `mix shadcn_daisyui.gen.theme NAME` - generates a brand theme override file
  (`[data-theme="NAME"]` / `"NAME-dark"`) and wires it into `app.css`.
- `mix shadcn_daisyui.upgrade` - refresh copied assets for `--copy` installs.
- Package test suite (component render tests, form field tests, installer patcher tests).
- Docs site: `/llms.txt`, `/llms-full.txt`, `/docs/components/:slug.md` markdown
  endpoints and a Cmd+K search palette.
- `package.json` so esbuild resolves `import { Hooks } from "shadcn_daisyui"` from deps.

### Changed

- **Breaking:** `mix shadcn_daisyui.install` now defaults to importing CSS/JS from
  `deps/` (upgradable via `mix deps.update`) instead of copying into `assets/`.
  Use `--copy` for the old behavior; `mix shadcn_daisyui.upgrade` refreshes copies.
- Installer now patches `assets/js/app.js` (hook registration) and the root layout
  (`data-theme`) automatically - no manual steps for a standard Phoenix 1.8 app.

## [0.1.0] - 2026-06-10

### Added

- Initial release: daisyUI v5 theme that reproduces shadcn/ui (neutral OKLCH palette,
  light `shadcn` + dark `shadcn-dark` themes, shadcn metrics override layer).
- 26 Phoenix function components (`ShadcnDaisyui.Components`), including interactive
  calendar, date picker/range, combobox, select, OTP input, carousel, resizable.
- Vanilla-JS interactivity: `initShadcnDaisyui()` for dead views + LiveView `Hooks`.
- `mix shadcn_daisyui.install` - copies assets and patches `app.css`.
- Docs/demo site (`demo/`) with 77-component gallery, installation and theming guides,
  interactive theme creator; static export + GitHub Pages deploy.
