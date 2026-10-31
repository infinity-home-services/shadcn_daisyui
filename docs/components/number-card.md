# Number Card

A label, a big number, a line under it, and a faint trend behind the number: a dashboard's headline figures.

> Requires the optional chart kit: `import { ChartHooks } from "shadcn_daisyui/charts"` and spread `ChartHooks` into the LiveSocket's hooks (dead views: `initCharts()`).

The trend is a <.chart> line with its axes, grid, legend, tooltip and points hidden and its area filled, so it needs the chart entry (shadcn_daisyui/charts); without it the card still shows the number and the line under it. Labels name the rows of the trend's hidden table ({"Mon 13", 18_400}); bare numbers are numbered 1, 2, 3. A nil (a day with nothing to count) in the middle is bridged, never a gap; nils at either end are dropped, so the line runs edge to edge rather than stopping in a cliff; with fewer than two points left there is no trend. The value, the line under it and the changes arrive formatted from the server. A change is good news (green) when it moved the way `good` says, bad news (red) the other way, neutral when flat; its sign and arrow say the same, never colour alone. A linked card's label is the link, stretched over the card, so the help stays its own button.

## Usage guidance

Use when:

- A dashboard's headline figures: today's sales, appointments, close rate
- One number that matters, with how it got there as a faint trend
- A number with its breakdown under it ("Margin $14,700 (35%)") and its change on another period as badges (vs PP)
- A number people open to see what's behind it: the whole card is a link

Don't use for:

- Several series or values people compare - use a chart
- A list of figures with labels - use a table or a description list
- A status (on track, late) - say it in words with a badge, not a number

Sizing: Card padding 24px; the label 14px / 500 muted, with a 16px ? after it; the number 30px / 600, the line under it 14px muted, the change badges 12px, 8px below it. The trend fills the lower 60% of the card at 50% opacity behind the text and the badges, its peaks as clear as the rest of it.

Responsive: Lay a row of cards out in a grid: one column on phones, two from sm, four from lg. The number never wraps mid-figure; keep it short (format it on the server: $42K, 38%).

iOS: A GroupBox with the label, a .title.weight(.semibold) number and a caption, over a Chart with an AreaMark + LineMark and .chartXAxis(.hidden) / .chartYAxis(.hidden).

## Specs

| Part | Description |
| --- | --- |
| Card | The card surface (rounded-xl, 1px border, shadow-sm). It doesn't clip, so the help can float over its edge; the trend clips itself. |
| Label | What the number is, sentence case, no colon; the link's text when the card is a link. |
| Help | A ? after the label; what the number counts, in a popover on hover, focus or tap. |
| Value | The number, formatted on the server, proportional figures. |
| Line under | A comparison or breakdown: "Margin $14,700 (35%)". |
| Changes | Per period, an outline badge naming it (vs PP), then the difference and the change, tinted good, bad or neutral, each edged in its own tone. |
| Trend | A filled line chart behind the text and badges, edge to edge inside the card's border, aria-hidden, with its own hidden table. |

| Property | Value |
| --- | --- |
| Padding | 1.5rem (24px) |
| Label | 0.875rem / 500, muted-foreground |
| Value | 1.875rem / 600, letter-spacing -0.025em |
| Line under | 0.875rem, muted-foreground |
| Help | 16px icon, 44px target on touch, 16rem popover |
| Changes | 12px badges, 8px apart (4px within a period), 8px below the line; tints of success and destructive on the card, a 1px border in the badge's tone at 30% over the card (the period's: foreground at 18%); text at least 4.5:1 |
| Trend | lower 60% of the card, edge to edge (no auto padding), the peak a sixth of its height below the top and the range at least a fifth of the top value (a flat series is a level line), 50% opacity, 2px line, 25% area fill, gaps bridged |

Tokens used: `card`, `border-color`, `foreground`, `muted`, `muted-foreground`, `chart-1`, `color-success`, `destructive`, `popover`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | The card's link (when it is one), then the help |
| Enter | Opens the card's link |

Role / ARIA: Text (a <p> each for the label, the number and the line under it), the label a link when the card is one, the help a button described by its text (role=tooltip). The trend's canvas is aria-hidden; its numbers are in a visually hidden table named "<label> trend".

Focus: A linked card shows the 3px ring around the whole card; the help shows it around the ? and opens its text.

Screen reader: Reads the label ("Sales, link"), the number, the line under it and the changes ("vs PP, +$8,000, +24%"), then the trend's table. The help button reads "About Sales" and its text.

Touch target: A linked card is one big target; the help's ? has a 44px target and opens on tap.

Reduced motion: The trend doesn't animate under prefers-reduced-motion.

## Native (SwiftUI)

Parity: guidance only - no native component yet.

```swift
GroupBox {
    VStack(alignment: .leading, spacing: 4) {
        Text("Sales").font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
        Text("$42,000").font(.title.weight(.semibold))
        Text("Margin $14,700 (35%)").font(.subheadline).foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
}
.background(alignment: .bottom) {
    Chart(trend) { AreaMark(x: .value("Day", $0.day), y: .value("Sales", $0.value)) }
        .chartXAxis(.hidden).chartYAxis(.hidden)
        .foregroundStyle(Color.chart1.opacity(0.25))
        .frame(height: 60)
        .accessibilityHidden(true)
}
```

Keep the number in Text so VoiceOver reads it; the trend behind it is decoration (accessibilityHidden), with the comparison said in words under the number.

## Props

| Name | Type | Default |
| --- | --- | --- |
| id | string (required) | - |
| label | string (required) | - |
| value | string (required): the number, formatted | - |
| trend | [number] or [{label, number}], oldest first; nil at either end is dropped | [] (no trend) |
| color | the trend's colour token | chart-1 |
| help | string: what the number counts, in plain words (a ? beside the label) | nil |
| navigate / patch / href | the whole card is a link (the label is its text) | nil |
| format | fn number -> text end, for the trend's hidden table | digits grouped |
| class | any | nil |
| inner_block | slot: the line under the number | - |
| :change | slot, one per period: vs ("vs PP"), by ("+$8,000"), percent ("+24%"), direction (up/down/flat), good (up/down/none, default up) | - |

## A row of number cards

HEEx:

```heex
<div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
  <.number_card
    id="sales"
    label="Sales"
    value="$42,000"
    help="Every sale booked this week, at its sold price."
    trend={@sales_trend}
    patch={~p"/dashboard?open=sales"}
  >
    Margin $14,700 (35%)
    <:change vs="vs PP" by="+$8,000" percent="+24%" direction="up" />
  </.number_card>
  <.number_card id="appointments" label="Appointments" value="30" trend={@appointments_trend}>
    vs. 27 last Tuesday
  </.number_card>
  <.number_card
    id="close-rate"
    label="Close rate"
    value="38%"
    help="Visits that sold, out of visits that happened."
    trend={@close_rate_trend}
    color="chart-3"
  >
    11 of 29 run
    <:change vs="vs PP" by="-2.4 pts" percent="-6%" direction="down" />
  </.number_card>
  <.number_card id="average-sale" label="Average sale" value="$3,818">
    2 cancellations
  </.number_card>
</div>
```

```html
<div class="grid w-full gap-4 sm:grid-cols-2 lg:grid-cols-4">
  <div id="sales" class="card number-card" data-slot="number-card">
    <figure id="sales-trend" class="chart number-card-trend" data-slot="chart" data-variant="trend" data-config="{&quot;data&quot;:{&quot;labels&quot;:[&quot;Mon 13&quot;,&quot;Tue 14&quot;,&quot;Wed 15&quot;,&quot;Thu 16&quot;,&quot;Fri 17&quot;,&quot;Sat 18&quot;,&quot;Sun 19&quot;,&quot;Mon 20&quot;,&quot;Tue 21&quot;,&quot;Wed 22&quot;,&quot;Thu 23&quot;,&quot;Fri 24&quot;,&quot;Sat 25&quot;,&quot;Sun 26&quot;],&quot;datasets&quot;:[{&quot;data&quot;:[18400,22100,19800,26300,31200,12400,6800,20900,24700,21500,28900,33600,14100,7900],&quot;label&quot;:&quot;Sales&quot;,&quot;color&quot;:&quot;chart-1&quot;,&quot;fill&quot;:&quot;start&quot;,&quot;spanGaps&quot;:true}]},&quot;type&quot;:&quot;line&quot;,&quot;options&quot;:{&quot;plugins&quot;:{&quot;legend&quot;:{&quot;display&quot;:false},&quot;tooltip&quot;:{&quot;enabled&quot;:false}},&quot;scales&quot;:{&quot;y&quot;:{&quot;display&quot;:false},&quot;x&quot;:{&quot;display&quot;:false}}}}" data-label="Sales trend">
      <div id="sales-trend-canvas" data-slot="chart-canvas" role="img" aria-label="Sales trend" aria-hidden="true">
        <canvas></canvas>
        <div data-slot="chart-status" class="sr-only" aria-live="polite"></div>
      </div>
      <table data-slot="chart-table" class="sr-only">
        <caption>Sales trend</caption>
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
    <div class="number-card-body">
      <p class="number-card-label">
        <a href="#number-cards" class="number-card-link">
          Sales
        </a>
        <span class="dropdown dropdown-hover number-card-help">
          <span tabindex="0" role="button" class="number-card-help-trigger" aria-label="About Sales" aria-describedby="sales-help">
            <span class="hero-question-mark-circle" aria-hidden="true"></span>
          </span>
          <span id="sales-help" role="tooltip" class="dropdown-content number-card-help-content">Every sale booked this week, at its sold price.</span>
        </span>
      </p>
      <p class="number-card-value">$42,000</p>
      <p class="number-card-description">
        Margin $14,700 (35%)
      </p>
      <div class="number-card-changes">
        <span class="number-card-change-group">
          <span class="badge number-card-vs">vs PP</span>
          <span class="badge number-card-change" data-tone="good">
            +$8,000
          </span>
          <span class="badge number-card-change" data-tone="good">
            <span class="hero-arrow-up-mini" aria-hidden="true"></span>+24%
          </span>
        </span>
      </div>
    </div>
  </div>
  <div id="appointments" class="card number-card" data-slot="number-card">
    <figure id="appointments-trend" class="chart number-card-trend" data-slot="chart" data-variant="trend" data-config="{&quot;data&quot;:{&quot;labels&quot;:[&quot;Mon 13&quot;,&quot;Tue 14&quot;,&quot;Wed 15&quot;,&quot;Thu 16&quot;,&quot;Fri 17&quot;,&quot;Sat 18&quot;,&quot;Sun 19&quot;,&quot;Mon 20&quot;,&quot;Tue 21&quot;,&quot;Wed 22&quot;,&quot;Thu 23&quot;,&quot;Fri 24&quot;,&quot;Sat 25&quot;,&quot;Sun 26&quot;],&quot;datasets&quot;:[{&quot;data&quot;:[9,11,10,12,14,6,3,10,12,11,13,15,7,4],&quot;label&quot;:&quot;Appointments&quot;,&quot;color&quot;:&quot;chart-1&quot;,&quot;fill&quot;:&quot;start&quot;,&quot;spanGaps&quot;:true}]},&quot;type&quot;:&quot;line&quot;,&quot;options&quot;:{&quot;plugins&quot;:{&quot;legend&quot;:{&quot;display&quot;:false},&quot;tooltip&quot;:{&quot;enabled&quot;:false}},&quot;scales&quot;:{&quot;y&quot;:{&quot;display&quot;:false},&quot;x&quot;:{&quot;display&quot;:false}}}}" data-label="Appointments trend">
      <div id="appointments-trend-canvas" data-slot="chart-canvas" role="img" aria-label="Appointments trend" aria-hidden="true">
        <canvas></canvas>
        <div data-slot="chart-status" class="sr-only" aria-live="polite"></div>
      </div>
      <table data-slot="chart-table" class="sr-only">
        <caption>Appointments trend</caption>
        <thead>
          <tr>
            <td></td>
            <th scope="col">Appointments</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <th scope="row">Mon 13</th>
            <td>9</td>
          </tr>
          <tr>
            <th scope="row">Tue 14</th>
            <td>11</td>
          </tr>
          <tr>
            <th scope="row">Wed 15</th>
            <td>10</td>
          </tr>
          <tr>
            <th scope="row">Thu 16</th>
            <td>12</td>
          </tr>
          <tr>
            <th scope="row">Fri 17</th>
            <td>14</td>
          </tr>
          <tr>
            <th scope="row">Sat 18</th>
            <td>6</td>
          </tr>
          <tr>
            <th scope="row">Sun 19</th>
            <td>3</td>
          </tr>
          <tr>
            <th scope="row">Mon 20</th>
            <td>10</td>
          </tr>
          <tr>
            <th scope="row">Tue 21</th>
            <td>12</td>
          </tr>
          <tr>
            <th scope="row">Wed 22</th>
            <td>11</td>
          </tr>
          <tr>
            <th scope="row">Thu 23</th>
            <td>13</td>
          </tr>
          <tr>
            <th scope="row">Fri 24</th>
            <td>15</td>
          </tr>
          <tr>
            <th scope="row">Sat 25</th>
            <td>7</td>
          </tr>
          <tr>
            <th scope="row">Sun 26</th>
            <td>4</td>
          </tr>
        </tbody>
      </table>
    </figure>
    <div class="number-card-body">
      <p class="number-card-label">
        Appointments
      </p>
      <p class="number-card-value">30</p>
      <p class="number-card-description">
        vs. 27 last Tuesday
      </p>
    </div>
  </div>
  <div id="close-rate" class="card number-card" data-slot="number-card">
    <figure id="close-rate-trend" class="chart number-card-trend" data-slot="chart" data-variant="trend" data-config="{&quot;data&quot;:{&quot;labels&quot;:[&quot;Mon 13&quot;,&quot;Tue 14&quot;,&quot;Wed 15&quot;,&quot;Thu 16&quot;,&quot;Fri 17&quot;,&quot;Sat 18&quot;,&quot;Sun 19&quot;,&quot;Mon 20&quot;,&quot;Tue 21&quot;,&quot;Wed 22&quot;,&quot;Thu 23&quot;,&quot;Fri 24&quot;,&quot;Sat 25&quot;,&quot;Sun 26&quot;],&quot;datasets&quot;:[{&quot;data&quot;:[33,35,31,36,38,30,29,34,37,35,40,41,36,38],&quot;label&quot;:&quot;Close rate&quot;,&quot;color&quot;:&quot;chart-3&quot;,&quot;fill&quot;:&quot;start&quot;,&quot;spanGaps&quot;:true}]},&quot;type&quot;:&quot;line&quot;,&quot;options&quot;:{&quot;plugins&quot;:{&quot;legend&quot;:{&quot;display&quot;:false},&quot;tooltip&quot;:{&quot;enabled&quot;:false}},&quot;scales&quot;:{&quot;y&quot;:{&quot;display&quot;:false},&quot;x&quot;:{&quot;display&quot;:false}}}}" data-label="Close rate trend">
      <div id="close-rate-trend-canvas" data-slot="chart-canvas" role="img" aria-label="Close rate trend" aria-hidden="true">
        <canvas></canvas>
        <div data-slot="chart-status" class="sr-only" aria-live="polite"></div>
      </div>
      <table data-slot="chart-table" class="sr-only">
        <caption>Close rate trend</caption>
        <thead>
          <tr>
            <td></td>
            <th scope="col">Close rate</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <th scope="row">Mon 13</th>
            <td>33</td>
          </tr>
          <tr>
            <th scope="row">Tue 14</th>
            <td>35</td>
          </tr>
          <tr>
            <th scope="row">Wed 15</th>
            <td>31</td>
          </tr>
          <tr>
            <th scope="row">Thu 16</th>
            <td>36</td>
          </tr>
          <tr>
            <th scope="row">Fri 17</th>
            <td>38</td>
          </tr>
          <tr>
            <th scope="row">Sat 18</th>
            <td>30</td>
          </tr>
          <tr>
            <th scope="row">Sun 19</th>
            <td>29</td>
          </tr>
          <tr>
            <th scope="row">Mon 20</th>
            <td>34</td>
          </tr>
          <tr>
            <th scope="row">Tue 21</th>
            <td>37</td>
          </tr>
          <tr>
            <th scope="row">Wed 22</th>
            <td>35</td>
          </tr>
          <tr>
            <th scope="row">Thu 23</th>
            <td>40</td>
          </tr>
          <tr>
            <th scope="row">Fri 24</th>
            <td>41</td>
          </tr>
          <tr>
            <th scope="row">Sat 25</th>
            <td>36</td>
          </tr>
          <tr>
            <th scope="row">Sun 26</th>
            <td>38</td>
          </tr>
        </tbody>
      </table>
    </figure>
    <div class="number-card-body">
      <p class="number-card-label">
        Close rate
        <span class="dropdown dropdown-hover number-card-help">
          <span tabindex="0" role="button" class="number-card-help-trigger" aria-label="About Close rate" aria-describedby="close-rate-help">
            <span class="hero-question-mark-circle" aria-hidden="true"></span>
          </span>
          <span id="close-rate-help" role="tooltip" class="dropdown-content number-card-help-content">Visits that sold, out of visits that happened.</span>
        </span>
      </p>
      <p class="number-card-value">38%</p>
      <p class="number-card-description">
        11 of 29 run
      </p>
      <div class="number-card-changes">
        <span class="number-card-change-group">
          <span class="badge number-card-vs">vs PP</span>
          <span class="badge number-card-change" data-tone="bad">
            -2.4 pts
          </span>
          <span class="badge number-card-change" data-tone="bad">
            <span class="hero-arrow-down-mini" aria-hidden="true"></span>-6%
          </span>
        </span>
      </div>
    </div>
  </div>
  <div id="average-sale" class="card number-card" data-slot="number-card">
    <div class="number-card-body">
      <p class="number-card-label">
        Average sale
      </p>
      <p class="number-card-value">$3,818</p>
      <p class="number-card-description">
        2 cancellations
      </p>
    </div>
  </div>
</div>
```

## A trend with missing days

HEEx:

```heex
<%!-- [{"Mon 13", nil}, {"Tue 14", nil}, {"Wed 15", nil}, {"Thu 16", 11}, {"Fri 17", 13}, {"Sat 18", nil}, ...] --%>
<.number_card id="new-branch" label="New branch sales" value="83" trend={@partial_trend}>
  Open for a week
</.number_card>
```

```html
<div class="w-full max-w-xs">
  <div id="new-branch" class="card number-card" data-slot="number-card">
    <figure id="new-branch-trend" class="chart number-card-trend" data-slot="chart" data-variant="trend" data-config="{&quot;data&quot;:{&quot;labels&quot;:[&quot;Thu 16&quot;,&quot;Fri 17&quot;,&quot;Sat 18&quot;,&quot;Sun 19&quot;,&quot;Mon 20&quot;,&quot;Tue 21&quot;,&quot;Wed 22&quot;],&quot;datasets&quot;:[{&quot;data&quot;:[11,13,null,12,15,14,18],&quot;label&quot;:&quot;New branch sales&quot;,&quot;color&quot;:&quot;chart-1&quot;,&quot;fill&quot;:&quot;start&quot;,&quot;spanGaps&quot;:true}]},&quot;type&quot;:&quot;line&quot;,&quot;options&quot;:{&quot;plugins&quot;:{&quot;legend&quot;:{&quot;display&quot;:false},&quot;tooltip&quot;:{&quot;enabled&quot;:false}},&quot;scales&quot;:{&quot;y&quot;:{&quot;display&quot;:false},&quot;x&quot;:{&quot;display&quot;:false}}}}" data-label="New branch sales trend">
      <div id="new-branch-trend-canvas" data-slot="chart-canvas" role="img" aria-label="New branch sales trend" aria-hidden="true">
        <canvas></canvas>
        <div data-slot="chart-status" class="sr-only" aria-live="polite"></div>
      </div>
      <table data-slot="chart-table" class="sr-only">
        <caption>New branch sales trend</caption>
        <thead>
          <tr>
            <td></td>
            <th scope="col">New branch sales</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <th scope="row">Thu 16</th>
            <td>11</td>
          </tr>
          <tr>
            <th scope="row">Fri 17</th>
            <td>13</td>
          </tr>
          <tr>
            <th scope="row">Sat 18</th>
            <td>-</td>
          </tr>
          <tr>
            <th scope="row">Sun 19</th>
            <td>12</td>
          </tr>
          <tr>
            <th scope="row">Mon 20</th>
            <td>15</td>
          </tr>
          <tr>
            <th scope="row">Tue 21</th>
            <td>14</td>
          </tr>
          <tr>
            <th scope="row">Wed 22</th>
            <td>18</td>
          </tr>
        </tbody>
      </table>
    </figure>
    <div class="number-card-body">
      <p class="number-card-label">
        New branch sales
      </p>
      <p class="number-card-value">83</p>
      <p class="number-card-description">
        Open for a week
      </p>
    </div>
  </div>
</div>
```
