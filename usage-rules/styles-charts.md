# shadcn_daisyui - charts

Charts show change, rankings, progress and parts of a whole; a single number
is a number card. Pick the form by the data's job, take colour from the
theme, and give every chart its numbers in text.

## Rules

- **Pick the form by the job first, colour last** (table below). One number,
  with or without its trend, is a number card - never a one-bar chart or a
  two-slice pie.
- [web] **A chart is `<.chart>`** - one component and one hook (`ShadcnChart`,
  from the optional `shadcn_daisyui/charts` entry) for every chart type; a
  headline figure is `<.number_card>`. Never write a chart hook of your own,
  load Chart.js from a CDN, or draw a chart with hand-made SVG or divs.
- [web] The server sends an ordinary Chart.js config (`type`, `data`,
  `options`) as Elixir maps, with the labels already formatted ("Mon 27",
  "Pat Lee"). Values in tooltips follow the value axis's `ticks.format`
  (`Intl.NumberFormat` options); the ticks show the same format, compacted.
- **Colour comes from the theme, never from the chart.** Series take
  `chart-1` … `chart-5` in order, the same order every time: the colour
  follows the entity, not its rank, so hiding or filtering a series never
  repaints the others. [web] No `backgroundColor`, `borderColor` or colour
  literals in a config; a dataset's `color` names a token when the job needs
  one.
- **Five series at most.** Fold the rest into "Other" or split into small
  charts; never generate a sixth hue.
- **One series is the point → emphasis**: that series in `chart-1`, the
  others `muted-foreground`.
- **Parts of one thing are one hue at opacities** (the margin within a sale,
  the states of a pipeline: `chart-1`, `chart-1/65`, `chart-1/35`), with what
  is left as a grey track (`muted-foreground/25`).
- Status colours (`success`, `warning`, `error`) only when a series *means*
  good or bad, and never colour alone - say it in the label too.
- **Marks:** bars at most 24px thick with a 4px rounded data end, square at
  the baseline; lines 2px with round joins; area fills at 10%; a 2px gap in
  the surface colour between stacked parts; grid lines 1px on the value axis
  only, no axis lines. The theme draws all of it - don't restyle marks.
- **Text never wears the series colour.** Labels, values and legend text are
  foreground or muted-foreground; the colour sits on a key beside them.
- **A legend for two or more series** (under the chart), none for one - the
  card title names it. Label selectively: a ranking's bars at their ends,
  never a number on every point.
- **One value axis.** Never two y-scales on one chart: two charts, or both
  series indexed to a common base.
- **Rankings** are horizontal bars, longest first (sort on the server), each
  labelled at its end ("$24,500 · 38% margin · 2 for 3"); hide the value axis
  when every bar is labelled. [web] `indexAxis: "y"` plus
  `options.plugins.endLabels.labels`; on a narrow screen the labels move above
  the bars on their own.
- **Progress through states** is one stacked bar with its axes hidden, the
  states in order and a legend under it.
- **Tooltips enhance, never gate:** every value is also in the chart's text
  (end labels, or the hidden table). A clickable chart works from the
  keyboard. [web] `on_click` pushes `%{"id", "key", "series", "index"}`
  (`target` for a LiveComponent); open the detail in a sheet.
- **Every chart has a name and its numbers as text.** [web] `label` names it
  and captions the visually hidden table the component renders; `format`
  writes its numbers. [ios] `.accessibilityChartDescriptor` (an
  `AXChartDescriptor`).
- **Motion:** new data moves in 300ms; nothing moves under reduced motion; a
  theme change redraws instantly.
- **Layout:** a chart sits in a card - the title says what it is, the
  description its period or scope. Lay charts out in a grid that stacks to one
  column on phones. Filters go in one row above every chart they scope, never
  inside a chart's card.
- **Number card:** the label, the number formatted on the server (proportional
  figures), one line under it - a breakdown in words - and, optionally, its
  trend faint behind it, peaks and all, gaps bridged. Say what it counts in
  plain words behind a ? (`help`). Its change on another period is badges
  under the line (`<:change>`: the period, the difference, the change with
  its sign and arrow), toned good or bad by which way is good news, never
  colour alone. A card that opens its detail is a link as a whole
  (`patch`/`navigate`); never a separate "Zoom" button for it.

## Reference

| The data's job | Form | [web] config | [ios] Swift Charts |
|---|---|---|---|
| One number, maybe its trend | number card | `<.number_card trend={…}>` | GroupBox + AreaMark behind |
| Change over time | line; vertical bars for days or weeks | `type: "line"` / `"bar"` | LineMark / BarMark |
| A ranking, a leaderboard | horizontal bars, longest first, end labels | `indexAxis: "y"`, `endLabels` | BarMark + `.annotation(position: .trailing)` |
| A part within each item | stacked bars, one hue at opacities | `stacked: true`, `color: "chart-1/35"` | stacked BarMark, `.opacity` |
| Progress through states | one stacked bar, a grey track | one label, both axes hidden | stacked BarMark |
| Part to whole, five parts or fewer | doughnut | `type: "doughnut"` | SectorMark |
| A few series compared | grouped bars or lines, a legend | one dataset per series | `.foregroundStyle(by:)` |

| Series | Hue | Light | Dark |
|---|---|---|---|
| chart-1 | blue | `#2a78d6` | `#3987e5` |
| chart-2 | orange | `#eb6834` | `#d95926` |
| chart-3 | aqua | `#1baf7a` | `#199e70` |
| chart-4 | yellow | `#eda100` | `#c98500` |
| chart-5 | magenta | `#e87ba4` | `#d55181` |

The five are checked as a categorical palette against the card surface in
each mode: lightness band, chroma floor, colour-blind separation of
neighbours (worst ΔE 9.1 light, 8.4 dark; target 8) and normal-vision
separation (worst 19.6 / 19.3; floor 15). On a light card chart-3, -4 and -5
are under 3:1, which is why every chart carries its numbers in text. A brand
theme overriding them re-checks all five, in order.

| Mark | Spec |
|---|---|
| Bar | ≤ 24px thick (16px / 12px with labels above), 4px rounded data end |
| Horizontal bar row | 36px (48px / 72px with labels above) |
| Line | 2px, round joins; points hidden, 8px with a 2px ring on hover |
| Area fill | series at 10% (a number card's trend: 25%, faded) |
| Stacked parts | 2px gap in the surface colour |
| Grid | 1px `border-color`, value axis only |
| Text | 12px; ticks muted-foreground, legend and end labels foreground |
| Tooltip | popover surface, label then key · name · value per series |
| Canvas | 16rem high by default |
