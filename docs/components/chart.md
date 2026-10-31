# Chart

Bar, line and any other Chart.js chart, drawn from the theme: one component and one hook, data from the server.

> Requires the optional chart kit: `import { ChartHooks } from "shadcn_daisyui/charts"` and spread `ChartHooks` into the LiveSocket's hooks (dead views: `initCharts()`).

Needs the optional chart entry: import { ChartHooks } from "shadcn_daisyui/charts" and spread it into the LiveSocket's hooks (dead views: initCharts()). Chart.js ships inside the package (vendor/, pinned), so nothing loads from a CDN and the core shadcn_daisyui import stays free of it. Never put colours in the config: series take --chart-1…5 in order (or a dataset's color token), text --foreground / --muted-foreground, grid lines --border-color, and the tooltip is a popover. The chart redraws when the theme changes. Values in tooltips follow the value axis's ticks.format (Chart.js's Intl.NumberFormat options); the ticks show the same format, compacted ($25K). Labels arrive formatted - there is no date adapter. When LiveView changes config, the same chart moves to the new data.

## Usage guidance

Use when:

- Change over time: a line (one or a few series), or vertical bars for days and weeks
- A ranking or leaderboard: horizontal bars, longest first, each bar labelled at its end
- Progress through states: one horizontal stacked bar (resulted, needs a result, in progress, still to come)
- Comparing a handful of series: grouped or stacked bars with a legend

Don't use for:

- A single number, with or without a trend - use a number card
- Exact values people look up or copy - use a table (every chart also renders its numbers as a hidden table)
- More than five series - fold the rest into "Other", or split into small charts
- Comparing close values as slices - a pie or doughnut only shows part to whole at a glance

Sizing: The canvas is 16rem high (canvas_class="h-80" changes it); horizontal bar charts size themselves to their rows (36px each, 48px with the labels above the bars, plus 16px over the first row for its text). Bars are at most 24px thick with a 4px rounded end, lines 2px, text 12px.

Responsive: Charts fill their container's width and redraw on resize. On a narrow screen a leaderboard's end labels move above each bar with the name, so the bars keep their width (endLabels position: "above" keeps them there at every width), and a segment label shows only while its part is wide enough for it - the legend keeps every number. Put charts in a grid that stacks on phones (one column below sm).

iOS: Swift Charts: BarMark / LineMark / SectorMark with the same five chart colours, .chartXAxis(.hidden) for a leaderboard, and .accessibilityChartDescriptor for the numbers.

## Specs

| Part | Description |
| --- | --- |
| Figure | The <figure> with the hook; data-config holds the Chart.js config as JSON. |
| Canvas box | phx-update="ignore": Chart.js's container (role img, or application when clickable), focusable when it has tooltips. |
| Tooltip | A popover in the top layer: the label, then a colour key, the series name and the value per series. |
| Legend | Under the chart for two or more series; click a series to hide it. |
| Table | The numbers as a visually hidden table, captioned by label, for screen readers. |

| Property | Value |
| --- | --- |
| Height | 16rem; horizontal bars: 36px rows (48px with labels above) |
| Bars | max 24px thick, 4px rounded data end, square baseline |
| Stacked parts | 2px gap in the surface colour between parts |
| Segment labels | 12px, centred in the part; shown where the text's width + 8px fits inside the part and the bar is 16px thick or more; foreground or the surface colour, whichever reads 4.5:1 on the fill (black or white where neither does) |
| Lines | 2px, round joins; area fill at 10%; points hidden, 8px on hover with a 2px ring |
| Grid | 1px var(--border-color) on the value axis only, no axis lines |
| Text | 12px; ticks muted-foreground, legend and end labels foreground |
| Tooltip | popover surface, rounded-lg, shadow-lg, 12px; values tabular |

Tokens used: `chart-1`, `chart-2`, `chart-3`, `chart-4`, `chart-5`, `foreground`, `muted-foreground`, `border-color`, `popover`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Focuses the chart (when it has tooltips) |
| Arrow keys / Home / End | Move between labels (or a single bar's parts, or a doughnut's slices), showing the tooltip |
| Enter / Space | Sends on_click for the shown label or part |
| Escape | Hides the tooltip |

Role / ARIA: The canvas box is role="img" named by label (role="application" with aria-roledescription="chart" when on_click is set). A visually hidden <table> after it holds every number, with label as its caption: the canvas itself says nothing to a screen reader.

Focus: A 3px ring around the canvas box. Moving the pointer over the chart hands the tooltip back to the pointer.

Screen reader: The hidden table reads the numbers; while the arrow keys move, a polite live region reads the tooltip ("Mon 13: Sales $18,400").

Touch target: A tap anywhere in a bar's row (or a line's column) picks that label: the hit area is the row, not the painted bar.

Reduced motion: Animation is off under prefers-reduced-motion; otherwise new data moves in 300ms. Theme changes redraw instantly.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
Chart(people) { person in
    BarMark(x: .value("Margin", person.margin), y: .value("Person", person.name))
        .foregroundStyle(Color.chart1)
    BarMark(x: .value("Rest", person.sale - person.margin), y: .value("Person", person.name))
        .foregroundStyle(Color.chart1.opacity(0.35))
        .annotation(position: .trailing) { Text(person.summary).font(.caption) }
}
.chartXAxis(.hidden)
.accessibilityChartDescriptor(LeaderboardDescriptor(people: people))
```

Swift Charts draws the same forms: stacked BarMarks for a leaderboard (an annotation at the end), LineMark + AreaMark for trends, SectorMark for part to whole. Use the five chart colours in order and give each chart an AXChartDescriptor so VoiceOver reads the numbers.

## Props

| Name | Type | Default |
| --- | --- | --- |
| id | string (required) | - |
| label | string (required): the accessible name and table caption | - |
| config | map (required): a Chart.js config - type, data, options | - |
| on_click | event: pushes %{id, key, series, index} for a clicked bar, point or slice | nil |
| target | phx-target for on_click (a LiveComponent) | nil |
| format | fn number -> text end, for the hidden table's numbers | digits grouped (24,500) |
| canvas_class | any (on the canvas box, e.g. h-80) | 16rem high |
| class | any (on the figure) | nil |
| dataset color | token: chart-1…5, muted, muted-foreground, primary, destructive, success, warning, info; "chart-1/40" = 40% opacity; a list colours each bar | chart-1…5 in order |
| dataset key | sent as series with a click | the label |
| data.keys | one key per label, sent as key with a click | the labels |
| options.plugins.endLabels.labels | one text per bar, drawn at its end | nil |
| options.plugins.endLabels.position | "auto" (at the bar's end; a horizontal bar's name and label move above it on a narrow screen) \| "above" (above the bar at every width) | "auto" |
| options.plugins.segmentLabels | true: on stacked bars, each part's value centred in it where the text and 4px either side fit (the bar 16px thick or more); a one-row stack's legend gives every part's number \| "legend": the legend's numbers only, nothing drawn on the bar | false |

## Bars by day

HEEx:

```heex
<.card>
  <.card_body>
    <.card_title>Sales by day</.card_title>
    <.card_description>Last 2 weeks</.card_description>
    <.chart
      id="sales-by-day"
      label="Sales by day, last 2 weeks"
      class="mt-4"
      config={%{
        type: "bar",
        data: %{labels: @days, datasets: [%{label: "Sales", data: @sales}]},
        options: %{scales: %{y: %{ticks: %{format: %{style: "currency", currency: "USD", maximumFractionDigits: 0}}}}}
      }}
    />
  </.card_body>
</.card>
```

```html
<div class="card w-full">
  <div class="card-body">
    <h3 class="card-title">Sales by day</h3>
    <p class="text-sm text-muted-foreground">Last 2 weeks</p>
    <figure id="sales-by-day" class="chart mt-4" data-slot="chart" data-config="{&quot;data&quot;:{&quot;labels&quot;:[&quot;Mon 13&quot;,&quot;Tue 14&quot;,&quot;Wed 15&quot;,&quot;Thu 16&quot;,&quot;Fri 17&quot;,&quot;Sat 18&quot;,&quot;Sun 19&quot;,&quot;Mon 20&quot;,&quot;Tue 21&quot;,&quot;Wed 22&quot;,&quot;Thu 23&quot;,&quot;Fri 24&quot;,&quot;Sat 25&quot;,&quot;Sun 26&quot;],&quot;datasets&quot;:[{&quot;data&quot;:[18400,22100,19800,26300,31200,12400,6800,20900,24700,21500,28900,33600,14100,7900],&quot;label&quot;:&quot;Sales&quot;}]},&quot;type&quot;:&quot;bar&quot;,&quot;options&quot;:{&quot;scales&quot;:{&quot;y&quot;:{&quot;ticks&quot;:{&quot;format&quot;:{&quot;currency&quot;:&quot;USD&quot;,&quot;style&quot;:&quot;currency&quot;,&quot;maximumFractionDigits&quot;:0}}}}}}" data-label="Sales by day, last 2 weeks">
      <div id="sales-by-day-canvas" data-slot="chart-canvas" role="img" aria-label="Sales by day, last 2 weeks">
        <canvas></canvas>
        <div data-slot="chart-status" class="sr-only" aria-live="polite"></div>
      </div>
      <table data-slot="chart-table" class="sr-only">
        <caption>Sales by day, last 2 weeks</caption>
        <thead>
          <tr>
            <td></td>
            <th scope="col">Sales</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <th scope="row">Mon 13</th>
            <td>18,400</td>
          </tr>
          <tr>
            <th scope="row">Tue 14</th>
            <td>22,100</td>
          </tr>
          <tr>
            <th scope="row">Wed 15</th>
            <td>19,800</td>
          </tr>
          <tr>
            <th scope="row">Thu 16</th>
            <td>26,300</td>
          </tr>
          <tr>
            <th scope="row">Fri 17</th>
            <td>31,200</td>
          </tr>
          <tr>
            <th scope="row">Sat 18</th>
            <td>12,400</td>
          </tr>
          <tr>
            <th scope="row">Sun 19</th>
            <td>6,800</td>
          </tr>
          <tr>
            <th scope="row">Mon 20</th>
            <td>20,900</td>
          </tr>
          <tr>
            <th scope="row">Tue 21</th>
            <td>24,700</td>
          </tr>
          <tr>
            <th scope="row">Wed 22</th>
            <td>21,500</td>
          </tr>
          <tr>
            <th scope="row">Thu 23</th>
            <td>28,900</td>
          </tr>
          <tr>
            <th scope="row">Fri 24</th>
            <td>33,600</td>
          </tr>
          <tr>
            <th scope="row">Sat 25</th>
            <td>14,100</td>
          </tr>
          <tr>
            <th scope="row">Sun 26</th>
            <td>7,900</td>
          </tr>
        </tbody>
      </table>
    </figure>
  </div>
</div>
```

## Leaderboard

HEEx:

```heex
<%!-- Longest first; the margin is the darker part of each sale.
  Every bar is labelled at its end, so the value axis is hidden. --%>
<.chart
  id="leaderboard"
  label="Sales by person, this week"
  on_click="open_person"
  config={%{
    type: "bar",
    data: %{
      labels: Enum.map(@people, & &1.name),
      keys: Enum.map(@people, & &1.id),
      datasets: [
        %{label: "Margin", key: "margin", data: Enum.map(@people, & &1.margin), color: "chart-1"},
        %{label: "Rest of the sale", key: "rest", data: Enum.map(@people, &(&1.sale - &1.margin)), color: "chart-1/35"}
      ]
    },
    options: %{
      indexAxis: "y",
      scales: %{x: %{stacked: true, display: false, ticks: %{format: @usd}}, y: %{stacked: true}},
      plugins: %{endLabels: %{labels: Enum.map(@people, & &1.summary)}}
    }
  }}
/>

<%!-- def handle_event("open_person", %{"key" => id}, socket) -> open the sheet of that person's appointments --%>
```

```html
<div class="card w-full">
  <div class="card-body">
    <h3 class="card-title">Leaderboard</h3>
    <p class="text-sm text-muted-foreground">Sales this week · click a person</p>
    <figure id="leaderboard" class="chart mt-4" data-slot="chart" data-config="{&quot;data&quot;:{&quot;keys&quot;:[&quot;pat&quot;,&quot;sam&quot;,&quot;riley&quot;,&quot;jordan&quot;,&quot;morgan&quot;,&quot;casey&quot;],&quot;labels&quot;:[&quot;Pat Lee&quot;,&quot;Sam Okafor&quot;,&quot;Riley Chen&quot;,&quot;Jordan Diaz&quot;,&quot;Morgan Ito&quot;,&quot;Casey Park&quot;],&quot;datasets&quot;:[{&quot;data&quot;:[9310,7630,6880,4470,4290,1920],&quot;label&quot;:&quot;Margin&quot;,&quot;key&quot;:&quot;margin&quot;,&quot;color&quot;:&quot;chart-1&quot;},{&quot;data&quot;:[15190,14170,10320,10430,7010,4480],&quot;label&quot;:&quot;Rest of the sale&quot;,&quot;key&quot;:&quot;rest&quot;,&quot;color&quot;:&quot;chart-1/35&quot;}]},&quot;type&quot;:&quot;bar&quot;,&quot;options&quot;:{&quot;plugins&quot;:{&quot;endLabels&quot;:{&quot;labels&quot;:[&quot;$24,500 · 38% margin · 2 for 3&quot;,&quot;$21,800 · 35% margin · 3 for 4&quot;,&quot;$17,200 · 40% margin · 2 for 2&quot;,&quot;$14,900 · 30% margin · 1 for 3&quot;,&quot;$11,300 · 38% margin · 2 for 5&quot;,&quot;$6,400 · 30% margin · 1 for 2&quot;]}},&quot;scales&quot;:{&quot;y&quot;:{&quot;stacked&quot;:true},&quot;x&quot;:{&quot;display&quot;:false,&quot;ticks&quot;:{&quot;format&quot;:{&quot;currency&quot;:&quot;USD&quot;,&quot;style&quot;:&quot;currency&quot;,&quot;maximumFractionDigits&quot;:0}},&quot;stacked&quot;:true}},&quot;indexAxis&quot;:&quot;y&quot;}}" data-on-click="open_person" data-label="Sales by person, this week">
      <div id="leaderboard-canvas" data-slot="chart-canvas" role="application" aria-roledescription="chart" aria-label="Sales by person, this week">
        <canvas></canvas>
        <div data-slot="chart-status" class="sr-only" aria-live="polite"></div>
      </div>
      <table data-slot="chart-table" class="sr-only">
        <caption>Sales by person, this week</caption>
        <thead>
          <tr>
            <td></td>
            <th scope="col">Margin</th>
            <th scope="col">Rest of the sale</th>
            <th scope="col"></th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <th scope="row">Pat Lee</th>
            <td>9,310</td>
            <td>15,190</td>
            <td>$24,500 · 38% margin · 2 for 3</td>
          </tr>
          <tr>
            <th scope="row">Sam Okafor</th>
            <td>7,630</td>
            <td>14,170</td>
            <td>$21,800 · 35% margin · 3 for 4</td>
          </tr>
          <tr>
            <th scope="row">Riley Chen</th>
            <td>6,880</td>
            <td>10,320</td>
            <td>$17,200 · 40% margin · 2 for 2</td>
          </tr>
          <tr>
            <th scope="row">Jordan Diaz</th>
            <td>4,470</td>
            <td>10,430</td>
            <td>$14,900 · 30% margin · 1 for 3</td>
          </tr>
          <tr>
            <th scope="row">Morgan Ito</th>
            <td>4,290</td>
            <td>7,010</td>
            <td>$11,300 · 38% margin · 2 for 5</td>
          </tr>
          <tr>
            <th scope="row">Casey Park</th>
            <td>1,920</td>
            <td>4,480</td>
            <td>$6,400 · 30% margin · 1 for 2</td>
          </tr>
        </tbody>
      </table>
    </figure>
  </div>
</div>
```

## Leaderboard, labels above

HEEx:

```heex
<%!-- position: "above" puts each name and label above its bar at every
  width, so the bars run the card's full width; side by side while they
  fit, on two lines when they don't. --%>
<.chart
  id="leaderboard-above"
  label="Sales by person, this week"
  config={%{
    type: "bar",
    data: %{
      labels: Enum.map(@people, & &1.name),
      datasets: [
        %{label: "Margin", data: Enum.map(@people, & &1.margin), color: "chart-1"},
        %{label: "Rest of the sale", data: Enum.map(@people, &(&1.sale - &1.margin)), color: "chart-1/35"}
      ]
    },
    options: %{
      indexAxis: "y",
      scales: %{x: %{stacked: true, display: false, ticks: %{format: @usd}}, y: %{stacked: true}},
      plugins: %{endLabels: %{labels: Enum.map(@people, & &1.summary), position: "above"}}
    }
  }}
/>
```

```html
<div class="card w-full">
  <div class="card-body">
    <h3 class="card-title">Leaderboard</h3>
    <p class="text-sm text-muted-foreground">Sales this week · labels above the bars</p>
    <figure id="leaderboard-above" class="chart mt-4" data-slot="chart" data-config="{&quot;data&quot;:{&quot;keys&quot;:[&quot;pat&quot;,&quot;sam&quot;,&quot;riley&quot;,&quot;jordan&quot;,&quot;morgan&quot;,&quot;casey&quot;],&quot;labels&quot;:[&quot;Pat Lee&quot;,&quot;Sam Okafor&quot;,&quot;Riley Chen&quot;,&quot;Jordan Diaz&quot;,&quot;Morgan Ito&quot;,&quot;Casey Park&quot;],&quot;datasets&quot;:[{&quot;data&quot;:[9310,7630,6880,4470,4290,1920],&quot;label&quot;:&quot;Margin&quot;,&quot;key&quot;:&quot;margin&quot;,&quot;color&quot;:&quot;chart-1&quot;},{&quot;data&quot;:[15190,14170,10320,10430,7010,4480],&quot;label&quot;:&quot;Rest of the sale&quot;,&quot;key&quot;:&quot;rest&quot;,&quot;color&quot;:&quot;chart-1/35&quot;}]},&quot;type&quot;:&quot;bar&quot;,&quot;options&quot;:{&quot;plugins&quot;:{&quot;endLabels&quot;:{&quot;position&quot;:&quot;above&quot;,&quot;labels&quot;:[&quot;$24,500 · 38% margin · 2 for 3&quot;,&quot;$21,800 · 35% margin · 3 for 4&quot;,&quot;$17,200 · 40% margin · 2 for 2&quot;,&quot;$14,900 · 30% margin · 1 for 3&quot;,&quot;$11,300 · 38% margin · 2 for 5&quot;,&quot;$6,400 · 30% margin · 1 for 2&quot;]}},&quot;scales&quot;:{&quot;y&quot;:{&quot;stacked&quot;:true},&quot;x&quot;:{&quot;display&quot;:false,&quot;ticks&quot;:{&quot;format&quot;:{&quot;currency&quot;:&quot;USD&quot;,&quot;style&quot;:&quot;currency&quot;,&quot;maximumFractionDigits&quot;:0}},&quot;stacked&quot;:true}},&quot;indexAxis&quot;:&quot;y&quot;}}" data-label="Sales by person, this week">
      <div id="leaderboard-above-canvas" data-slot="chart-canvas" role="img" aria-label="Sales by person, this week">
        <canvas></canvas>
        <div data-slot="chart-status" class="sr-only" aria-live="polite"></div>
      </div>
      <table data-slot="chart-table" class="sr-only">
        <caption>Sales by person, this week</caption>
        <thead>
          <tr>
            <td></td>
            <th scope="col">Margin</th>
            <th scope="col">Rest of the sale</th>
            <th scope="col"></th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <th scope="row">Pat Lee</th>
            <td>9,310</td>
            <td>15,190</td>
            <td>$24,500 · 38% margin · 2 for 3</td>
          </tr>
          <tr>
            <th scope="row">Sam Okafor</th>
            <td>7,630</td>
            <td>14,170</td>
            <td>$21,800 · 35% margin · 3 for 4</td>
          </tr>
          <tr>
            <th scope="row">Riley Chen</th>
            <td>6,880</td>
            <td>10,320</td>
            <td>$17,200 · 40% margin · 2 for 2</td>
          </tr>
          <tr>
            <th scope="row">Jordan Diaz</th>
            <td>4,470</td>
            <td>10,430</td>
            <td>$14,900 · 30% margin · 1 for 3</td>
          </tr>
          <tr>
            <th scope="row">Morgan Ito</th>
            <td>4,290</td>
            <td>7,010</td>
            <td>$11,300 · 38% margin · 2 for 5</td>
          </tr>
          <tr>
            <th scope="row">Casey Park</th>
            <td>1,920</td>
            <td>4,480</td>
            <td>$6,400 · 30% margin · 1 for 2</td>
          </tr>
        </tbody>
      </table>
    </figure>
  </div>
</div>
```

## Progress row

HEEx:

```heex
<%!-- One stacked bar: the states in order, the last one a grey track.
  The axes are hidden, so the bar rounds at both ends. --%>
<.chart
  id="appointments-progress"
  label="Today's appointments"
  on_click="open_state"
  config={%{
    type: "bar",
    data: %{
      labels: ["Today's appointments"],
      datasets: [
        %{label: "Resulted", key: "resulted", data: [14], color: "chart-1"},
        %{label: "Needs a result", key: "needs_result", data: [3], color: "chart-1/65"},
        %{label: "In progress", key: "in_progress", data: [4], color: "chart-1/35"},
        %{label: "Still to come", key: "to_come", data: [9], color: "muted-foreground/25"}
      ]
    },
    options: %{
      indexAxis: "y",
      scales: %{x: %{stacked: true, display: false, max: 30}, y: %{stacked: true, display: false}}
    }
  }}
/>

<%!-- a click on a part sends %{"series" => "needs_result", ...} --%>
```

```html
<div class="card w-full">
  <div class="card-body">
    <h3 class="card-title">Today's appointments</h3>
    <p class="text-sm text-muted-foreground">30 booked · click a part</p>
    <figure id="appointments-progress" class="chart mt-4" data-slot="chart" data-config="{&quot;data&quot;:{&quot;labels&quot;:[&quot;Today&#39;s appointments&quot;],&quot;datasets&quot;:[{&quot;data&quot;:[14],&quot;label&quot;:&quot;Resulted&quot;,&quot;key&quot;:&quot;resulted&quot;,&quot;color&quot;:&quot;chart-1&quot;},{&quot;data&quot;:[3],&quot;label&quot;:&quot;Needs a result&quot;,&quot;key&quot;:&quot;needs_result&quot;,&quot;color&quot;:&quot;chart-1/65&quot;},{&quot;data&quot;:[4],&quot;label&quot;:&quot;In progress&quot;,&quot;key&quot;:&quot;in_progress&quot;,&quot;color&quot;:&quot;chart-1/35&quot;},{&quot;data&quot;:[9],&quot;label&quot;:&quot;Still to come&quot;,&quot;key&quot;:&quot;to_come&quot;,&quot;color&quot;:&quot;muted-foreground/25&quot;}]},&quot;type&quot;:&quot;bar&quot;,&quot;options&quot;:{&quot;scales&quot;:{&quot;y&quot;:{&quot;display&quot;:false,&quot;stacked&quot;:true},&quot;x&quot;:{&quot;max&quot;:30,&quot;display&quot;:false,&quot;stacked&quot;:true}},&quot;indexAxis&quot;:&quot;y&quot;}}" data-on-click="open_state" data-label="Today&#39;s appointments">
      <div id="appointments-progress-canvas" data-slot="chart-canvas" role="application" aria-roledescription="chart" aria-label="Today&#39;s appointments">
        <canvas></canvas>
        <div data-slot="chart-status" class="sr-only" aria-live="polite"></div>
      </div>
      <table data-slot="chart-table" class="sr-only">
        <caption>Today&#39;s appointments</caption>
        <thead>
          <tr>
            <td></td>
            <th scope="col">Resulted</th>
            <th scope="col">Needs a result</th>
            <th scope="col">In progress</th>
            <th scope="col">Still to come</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <th scope="row">Today&#39;s appointments</th>
            <td>14</td>
            <td>3</td>
            <td>4</td>
            <td>9</td>
          </tr>
        </tbody>
      </table>
    </figure>
  </div>
</div>
```

## Progress row, counts on the parts

HEEx:

```heex
<%!-- segmentLabels: each part's count centred on it, where it fits;
  a part too narrow has none (on a phone, the 4), and the legend
  gives every part's number: "Didn't happen 4". --%>
<.chart
  id="week-progress"
  label="This week's appointments"
  config={%{
    type: "bar",
    data: %{
      labels: ["This week's appointments"],
      datasets: [
        %{label: "Completed", key: "completed", data: [61], color: "chart-1"},
        %{label: "Needs a result", key: "needs_result", data: [9], color: "chart-1/65"},
        %{label: "Didn't happen", key: "no_show", data: [4], color: "chart-1/35"},
        %{label: "Still to come", key: "to_come", data: [26], color: "muted-foreground/25"}
      ]
    },
    options: %{
      indexAxis: "y",
      scales: %{x: %{stacked: true, display: false, max: 100}, y: %{stacked: true, display: false}},
      plugins: %{segmentLabels: true}
    }
  }}
/>
```

```html
<div class="card w-full">
  <div class="card-body">
    <h3 class="card-title">This week's appointments</h3>
    <p class="text-sm text-muted-foreground">100 booked · counts on the parts</p>
    <figure id="week-progress" class="chart mt-4" data-slot="chart" data-config="{&quot;data&quot;:{&quot;labels&quot;:[&quot;This week&#39;s appointments&quot;],&quot;datasets&quot;:[{&quot;data&quot;:[61],&quot;label&quot;:&quot;Completed&quot;,&quot;key&quot;:&quot;completed&quot;,&quot;color&quot;:&quot;chart-1&quot;},{&quot;data&quot;:[9],&quot;label&quot;:&quot;Needs a result&quot;,&quot;key&quot;:&quot;needs_result&quot;,&quot;color&quot;:&quot;chart-1/65&quot;},{&quot;data&quot;:[4],&quot;label&quot;:&quot;Didn&#39;t happen&quot;,&quot;key&quot;:&quot;no_show&quot;,&quot;color&quot;:&quot;chart-1/35&quot;},{&quot;data&quot;:[26],&quot;label&quot;:&quot;Still to come&quot;,&quot;key&quot;:&quot;to_come&quot;,&quot;color&quot;:&quot;muted-foreground/25&quot;}]},&quot;type&quot;:&quot;bar&quot;,&quot;options&quot;:{&quot;plugins&quot;:{&quot;segmentLabels&quot;:true},&quot;scales&quot;:{&quot;y&quot;:{&quot;display&quot;:false,&quot;stacked&quot;:true},&quot;x&quot;:{&quot;max&quot;:100,&quot;display&quot;:false,&quot;stacked&quot;:true}},&quot;indexAxis&quot;:&quot;y&quot;}}" data-label="This week&#39;s appointments">
      <div id="week-progress-canvas" data-slot="chart-canvas" role="img" aria-label="This week&#39;s appointments">
        <canvas></canvas>
        <div data-slot="chart-status" class="sr-only" aria-live="polite"></div>
      </div>
      <table data-slot="chart-table" class="sr-only">
        <caption>This week&#39;s appointments</caption>
        <thead>
          <tr>
            <td></td>
            <th scope="col">Completed</th>
            <th scope="col">Needs a result</th>
            <th scope="col">Didn&#39;t happen</th>
            <th scope="col">Still to come</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <th scope="row">This week&#39;s appointments</th>
            <td>61</td>
            <td>9</td>
            <td>4</td>
            <td>26</td>
          </tr>
        </tbody>
      </table>
    </figure>
  </div>
</div>
```

## Lines: one series in colour

HEEx:

```heex
<%!-- The comparison is muted, so this week reads first --%>
<.chart
  id="sales-weeks"
  label="Sales this week and last week"
  config={%{
    type: "line",
    data: %{
      labels: ~w(Mon Tue Wed Thu Fri Sat Sun),
      datasets: [
        %{label: "This week", data: @this_week},
        %{label: "Last week", data: @last_week, color: "muted-foreground"}
      ]
    },
    options: %{scales: %{y: %{ticks: %{format: @usd}}}}
  }}
/>
```

```html
<div class="card w-full">
  <div class="card-body">
    <h3 class="card-title">Sales</h3>
    <p class="text-sm text-muted-foreground">This week against last week</p>
    <figure id="sales-weeks" class="chart mt-4" data-slot="chart" data-config="{&quot;data&quot;:{&quot;labels&quot;:[&quot;Mon&quot;,&quot;Tue&quot;,&quot;Wed&quot;,&quot;Thu&quot;,&quot;Fri&quot;,&quot;Sat&quot;,&quot;Sun&quot;],&quot;datasets&quot;:[{&quot;data&quot;:[18400,22100,19800,26300,31200,12400,6800],&quot;label&quot;:&quot;This week&quot;},{&quot;data&quot;:[16900,18200,21400,19700,24800,15100,5900],&quot;label&quot;:&quot;Last week&quot;,&quot;color&quot;:&quot;muted-foreground&quot;}]},&quot;type&quot;:&quot;line&quot;,&quot;options&quot;:{&quot;scales&quot;:{&quot;y&quot;:{&quot;ticks&quot;:{&quot;format&quot;:{&quot;currency&quot;:&quot;USD&quot;,&quot;style&quot;:&quot;currency&quot;,&quot;maximumFractionDigits&quot;:0}}}}}}" data-label="Sales this week and last week">
      <div id="sales-weeks-canvas" data-slot="chart-canvas" role="img" aria-label="Sales this week and last week">
        <canvas></canvas>
        <div data-slot="chart-status" class="sr-only" aria-live="polite"></div>
      </div>
      <table data-slot="chart-table" class="sr-only">
        <caption>Sales this week and last week</caption>
        <thead>
          <tr>
            <td></td>
            <th scope="col">This week</th>
            <th scope="col">Last week</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <th scope="row">Mon</th>
            <td>18,400</td>
            <td>16,900</td>
          </tr>
          <tr>
            <th scope="row">Tue</th>
            <td>22,100</td>
            <td>18,200</td>
          </tr>
          <tr>
            <th scope="row">Wed</th>
            <td>19,800</td>
            <td>21,400</td>
          </tr>
          <tr>
            <th scope="row">Thu</th>
            <td>26,300</td>
            <td>19,700</td>
          </tr>
          <tr>
            <th scope="row">Fri</th>
            <td>31,200</td>
            <td>24,800</td>
          </tr>
          <tr>
            <th scope="row">Sat</th>
            <td>12,400</td>
            <td>15,100</td>
          </tr>
          <tr>
            <th scope="row">Sun</th>
            <td>6,800</td>
            <td>5,900</td>
          </tr>
        </tbody>
      </table>
    </figure>
  </div>
</div>
```

## Any Chart.js type

HEEx:

```heex
<%!-- The config is Chart.js's own: a doughnut, a radar, a scatter… The slices
  take chart-1…5 in order, like series. --%>
<.chart
  id="lead-sources"
  label="Leads by source, this month"
  config={%{
    type: "doughnut",
    data: %{labels: ["Website", "Referral", "Phone", "Events"], datasets: [%{label: "Leads", data: [46, 28, 17, 9]}]},
    options: %{cutout: "62%", plugins: %{legend: %{position: "right"}}}
  }}
/>
```

```html
<div class="card w-full max-w-md">
  <div class="card-body">
    <h3 class="card-title">Leads by source</h3>
    <p class="text-sm text-muted-foreground">This month · 100 leads</p>
    <figure id="lead-sources" class="chart mt-4" data-slot="chart" data-config="{&quot;data&quot;:{&quot;labels&quot;:[&quot;Website&quot;,&quot;Referral&quot;,&quot;Phone&quot;,&quot;Events&quot;],&quot;datasets&quot;:[{&quot;data&quot;:[46,28,17,9],&quot;label&quot;:&quot;Leads&quot;}]},&quot;type&quot;:&quot;doughnut&quot;,&quot;options&quot;:{&quot;plugins&quot;:{&quot;legend&quot;:{&quot;position&quot;:&quot;right&quot;}},&quot;cutout&quot;:&quot;62%&quot;}}" data-label="Leads by source, this month">
      <div id="lead-sources-canvas" data-slot="chart-canvas" class="h-48" role="img" aria-label="Leads by source, this month">
        <canvas></canvas>
        <div data-slot="chart-status" class="sr-only" aria-live="polite"></div>
      </div>
      <table data-slot="chart-table" class="sr-only">
        <caption>Leads by source, this month</caption>
        <thead>
          <tr>
            <td></td>
            <th scope="col">Leads</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <th scope="row">Website</th>
            <td>46</td>
          </tr>
          <tr>
            <th scope="row">Referral</th>
            <td>28</td>
          </tr>
          <tr>
            <th scope="row">Phone</th>
            <td>17</td>
          </tr>
          <tr>
            <th scope="row">Events</th>
            <td>9</td>
          </tr>
        </tbody>
      </table>
    </figure>
  </div>
</div>
```

## Light and dark

HEEx:

```heex
<%!-- The look comes from the tokens where the chart sits: these two islands
  pin a theme each; the page's own toggle redraws every chart. --%>
<div data-theme="shadcn" class="rounded-xl bg-background p-4 text-foreground">
  <.chart id="themes-light" label="Leads by week (light)" config={@config} />
</div>
<div data-theme="shadcn-dark" class="rounded-xl bg-background p-4 text-foreground">
  <.chart id="themes-dark" label="Leads by week (dark)" config={@config} />
</div>
```

```html
<div class="grid w-full gap-4 md:grid-cols-2">
  <div data-theme="shadcn" class="rounded-xl border border-border bg-background p-4 text-foreground">
    <figure id="themes-light" class="chart" data-slot="chart" data-config="{&quot;data&quot;:{&quot;labels&quot;:[&quot;W40&quot;,&quot;W41&quot;,&quot;W42&quot;,&quot;W43&quot;],&quot;datasets&quot;:[{&quot;data&quot;:[12,15,11,17],&quot;label&quot;:&quot;Website&quot;},{&quot;data&quot;:[8,6,9,10],&quot;label&quot;:&quot;Referral&quot;},{&quot;data&quot;:[5,7,4,6],&quot;label&quot;:&quot;Phone&quot;}]},&quot;type&quot;:&quot;bar&quot;}" data-label="Leads by week and source (light)">
      <div id="themes-light-canvas" data-slot="chart-canvas" class="h-56" role="img" aria-label="Leads by week and source (light)">
        <canvas></canvas>
        <div data-slot="chart-status" class="sr-only" aria-live="polite"></div>
      </div>
      <table data-slot="chart-table" class="sr-only">
        <caption>Leads by week and source (light)</caption>
        <thead>
          <tr>
            <td></td>
            <th scope="col">Website</th>
            <th scope="col">Referral</th>
            <th scope="col">Phone</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <th scope="row">W40</th>
            <td>12</td>
            <td>8</td>
            <td>5</td>
          </tr>
          <tr>
            <th scope="row">W41</th>
            <td>15</td>
            <td>6</td>
            <td>7</td>
          </tr>
          <tr>
            <th scope="row">W42</th>
            <td>11</td>
            <td>9</td>
            <td>4</td>
          </tr>
          <tr>
            <th scope="row">W43</th>
            <td>17</td>
            <td>10</td>
            <td>6</td>
          </tr>
        </tbody>
      </table>
    </figure>
  </div>
  <div data-theme="shadcn-dark" class="rounded-xl border border-border bg-background p-4 text-foreground">
    <figure id="themes-dark" class="chart" data-slot="chart" data-config="{&quot;data&quot;:{&quot;labels&quot;:[&quot;W40&quot;,&quot;W41&quot;,&quot;W42&quot;,&quot;W43&quot;],&quot;datasets&quot;:[{&quot;data&quot;:[12,15,11,17],&quot;label&quot;:&quot;Website&quot;},{&quot;data&quot;:[8,6,9,10],&quot;label&quot;:&quot;Referral&quot;},{&quot;data&quot;:[5,7,4,6],&quot;label&quot;:&quot;Phone&quot;}]},&quot;type&quot;:&quot;bar&quot;}" data-label="Leads by week and source (dark)">
      <div id="themes-dark-canvas" data-slot="chart-canvas" class="h-56" role="img" aria-label="Leads by week and source (dark)">
        <canvas></canvas>
        <div data-slot="chart-status" class="sr-only" aria-live="polite"></div>
      </div>
      <table data-slot="chart-table" class="sr-only">
        <caption>Leads by week and source (dark)</caption>
        <thead>
          <tr>
            <td></td>
            <th scope="col">Website</th>
            <th scope="col">Referral</th>
            <th scope="col">Phone</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <th scope="row">W40</th>
            <td>12</td>
            <td>8</td>
            <td>5</td>
          </tr>
          <tr>
            <th scope="row">W41</th>
            <td>15</td>
            <td>6</td>
            <td>7</td>
          </tr>
          <tr>
            <th scope="row">W42</th>
            <td>11</td>
            <td>9</td>
            <td>4</td>
          </tr>
          <tr>
            <th scope="row">W43</th>
            <td>17</td>
            <td>10</td>
            <td>6</td>
          </tr>
        </tbody>
      </table>
    </figure>
  </div>
</div>
```
