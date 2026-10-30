defmodule ShadcnDaisyui.Components.Chart do
  @moduledoc """
  The chart kit: `chart/1` (any stock Chart.js chart) and `number_card/1` (a
  label, a big number and a faint trend). Opt-in: the charts need the
  separate `shadcn_daisyui/charts` JS entry, which carries a pinned copy of
  Chart.js, so apps without charts load nothing new.

      // app.js
      import { Hooks } from "shadcn_daisyui"
      import { ChartHooks } from "shadcn_daisyui/charts"
      new LiveSocket("/live", Socket, { hooks: { ...Hooks, ...ChartHooks } })

      <.chart id="sales-by-day" label="Sales by day" config={@sales_by_day} />

  Imported by `use ShadcnDaisyui.Components`.
  """
  use Phoenix.Component

  @doc """
  A chart: an ordinary Chart.js config (`type`, `data`, `options`) as Elixir
  maps, drawn by the `ShadcnChart` hook (from `shadcn_daisyui/charts`; dead
  views: `initCharts()`). One component and one hook for every chart type.

      <.chart
        id="sales-by-day"
        label="Sales by day, last 2 weeks"
        config={%{
          type: "bar",
          data: %{labels: @days, datasets: [%{label: "Sales", data: @sales}]}
        }}
      />

  Labels arrive formatted ("Mon 27", "Pat Lee"): there is no date adapter.
  When LiveView changes `config`, the hook updates the same chart in place
  (the bars or lines move to their new values).

  ## The look comes from the theme

  Never put colours in the config. Series take `--chart-1` … `--chart-5` in
  order (a pie's slices too), text uses `--foreground` and
  `--muted-foreground`, grid lines `--border-color`, the tooltip is styled
  like the package's popovers, and the font is the page's. The chart redraws
  when the theme changes (`setTheme`, `data-theme`, brand themes).

  The kit reads a few keys of its own (Chart.js ignores them):

    * a dataset's `color` - a theme token instead of slot order: `"chart-3"`,
      `"muted"`, `"muted-foreground"`, `"primary"`, `"destructive"`,
      `"success"`, `"warning"`, `"info"`, with an optional opacity suffix
      (`"chart-1/40"`: a lighter part of the same series). A list gives each
      bar or slice its own (`["muted", "muted", "chart-1"]`: emphasis)
    * a dataset's `key` - sent with clicks (default: its label)
    * `data.keys` - one key per label, sent with clicks (default: the label)
    * `options.plugins.endLabels.labels` - one text per bar, drawn at the bar's
      end (`"$24,500 · 38% margin · 2 for 3"`); on a narrow screen a
      horizontal bar's name and label move above the bar (on two lines when
      they don't fit side by side). `position: "above"` puts them above at
      every width (default `"auto"`)
    * `options.plugins.segmentLabels: true` - on stacked bars, each part
      shows its value (as its tooltip writes it) centred in it, in 12px text,
      when the text and 4px either side fit inside the part and the bar is
      at least 16px thick; a part too small has no label. On a one-row stack
      (a progress row) the legend gives each part's number too
      (`"Completed 61"`), so every number stays on screen. The text is
      foreground or the surface colour, whichever reads at 4.5:1 or more on
      the part (black or white where neither does).
      `segmentLabels: "legend"` gives a one-row stack's legend the numbers
      and draws nothing on the bar

  Values in tooltips follow the value axis's `ticks.format` (Chart.js's own
  `Intl.NumberFormat` options, e.g.
  `%{style: "currency", currency: "USD", maximumFractionDigits: 0}`); the axis
  ticks show the same format, compacted ($25K).

  ## Size

  The canvas is 16rem high; `canvas_class="h-80"` changes it. Horizontal bar
  charts (`indexAxis: "y"`) size themselves to their rows instead (36px
  each; 48px, or 72px on two lines, with the labels above the bars, plus
  16px over the first row for its text).

  ## Clicks

  `on_click="open_bucket"` makes bars, points and slices clickable (pointer,
  Enter and Space). The hook pushes
  `%{"id" => id, "key" => key, "series" => series, "index" => index}`: `key`
  is the clicked label's key (`data.keys`, or the label), `series` the
  clicked dataset's `key` (or label; nil when the click wasn't on a bar).
  `target` sends it to a LiveComponent. In a dead view the figure dispatches
  a bubbling `chart:click` DOM event with the same detail.

  ## Accessibility

  `label` names the chart. Below the canvas, the chart's numbers render as a
  visually hidden table (a screen reader can't read a canvas), with `label`
  as its caption and `format` turning each number into text (default: digits
  grouped, `24,500`). The canvas takes focus when it has tooltips: the arrow
  keys move between labels (or between a single bar's parts), showing the
  tooltip, and a polite live region reads it. Reduced motion turns animation
  off.
  """
  attr(:id, :string, required: true)
  attr(:label, :string, required: true, doc: "the chart's accessible name and table caption")
  attr(:config, :map, required: true, doc: "a Chart.js config: type, data, options")

  attr(:on_click, :string,
    default: nil,
    doc: "event pushed with %{id, key, series, index} when a bar, point or slice is clicked"
  )

  attr(:target, :any, default: nil, doc: "phx-target for on_click (a LiveComponent)")

  attr(:format, :any,
    default: nil,
    doc: "fn number -> text end for the table's numbers (default: digits grouped)"
  )

  attr(:canvas_class, :any, default: nil, doc: "on the canvas box, e.g. h-80 (default 16rem)")
  attr(:variant, :string, default: "default", values: ~w(default trend))
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def chart(assigns) do
    assigns =
      assigns
      |> assign(:json, encode(assigns.config))
      |> assign(:table, table(assigns.config, assigns.format || (&format_number/1)))

    ~H"""
    <figure
      id={@id}
      class={["chart", @class]}
      data-slot="chart"
      data-variant={@variant != "default" && @variant}
      data-config={@json}
      data-on-click={@on_click}
      data-label={@label}
      phx-target={@target}
      phx-hook="ShadcnChart"
      {@rest}
    >
      <div
        id={"#{@id}-canvas"}
        data-slot="chart-canvas"
        class={@canvas_class}
        phx-update="ignore"
        role={if(@on_click, do: "application", else: "img")}
        aria-roledescription={@on_click && "chart"}
        aria-label={@label}
        aria-hidden={@variant == "trend" && "true"}
      >
        <canvas></canvas>
        <div data-slot="chart-status" class="sr-only" aria-live="polite"></div>
      </div>
      <table data-slot="chart-table" class="sr-only">
        <caption>{@label}</caption>
        <thead>
          <tr>
            <td></td>
            <th :for={head <- @table.head} scope="col">{head}</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={{label, cells} <- @table.rows}>
            <th scope="row">{label}</th>
            <td :for={cell <- cells}>{cell}</td>
          </tr>
        </tbody>
      </table>
    </figure>
    """
  end

  @doc """
  A number card: a label, a big number, a line under it, and a faint trend
  behind the number. The trend is a `chart/1` line with its axes, grid,
  legend and points hidden and its area filled (it needs the charts entry;
  without it the card still shows the number).

      <.number_card
        id="sales-today"
        label="Booked Sales"
        value="$42,000"
        help="Every sale booked today, at its sold price."
        trend={@sales_trend}
        patch={~p"/dashboard?open=sales"}
      >
        3 sales
        <:change vs="vs PP" by="+$8,000" percent="+24%" direction="up" />
      </.number_card>

  `value` and the line under it arrive formatted. `trend` is a list of
  numbers, or `{label, number}` tuples (the labels name the rows of the
  trend's screen-reader table: `[{"Mon", 12_400}, {"Tue", 9_800}]`). A
  missing point (`nil`) in the middle is bridged, so the line has no gaps;
  missing points at either end are dropped, so the line runs edge to edge,
  and with fewer than two points left there is no trend. Its range comes
  from the data: the peak always sits a sixth of the trend's height below
  its top, and the range is at least a fifth of the top value, so a flat
  series is a level line and a 1-point wiggle a gentle one. `color` picks
  the trend's series token (default `chart-1`).

    * `help` - a "?" beside the label that shows this text on hover, focus or
      tap: what the number counts, in plain words.
    * `<:change>` - badges comparing the number with another period, floating
      over the trend: `vs` names the period ("vs PP"), `by` the difference and
      `percent` the change, both formatted on the server ("-2.4 pts",
      "-2.7%"). `direction` (`"up"`, `"down"`, `"flat"`) sets the arrow, and
      `good` (`"up"`, the default, `"down"` or `"none"`) says which way is
      good news: good news is green, bad news red, the rest neutral. The sign
      and the arrow say it too, never colour alone.
    * `navigate` / `patch` / `href` - the whole card opens what's behind the
      number (the label is the link's text); the help stays its own button.
  """
  attr(:id, :string, required: true)
  attr(:label, :string, required: true)
  attr(:value, :string, required: true, doc: "the number, formatted")

  attr(:help, :string,
    default: nil,
    doc: "what the number counts, shown from a ? beside the label"
  )

  attr(:trend, :list,
    default: [],
    doc: "numbers, or {label, number} tuples, oldest first; nil at either end is dropped"
  )

  attr(:color, :string, default: "chart-1", doc: "the trend's colour token")
  attr(:format, :any, default: nil, doc: "fn number -> text end for the trend's table")
  attr(:navigate, :any, default: nil, doc: "the card is a link: navigate there")
  attr(:patch, :any, default: nil, doc: "the card is a link: patch there")
  attr(:href, :any, default: nil, doc: "the card is a link: go there")
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, doc: "the line under the number: a comparison or a breakdown")

  slot :change, doc: "badges comparing the number with another period" do
    attr(:vs, :string, required: true, doc: ~s(the period compared with: "vs PP"))
    attr(:by, :string, doc: ~s(the difference, formatted: "+$8,000", "-2.4 pts"))
    attr(:percent, :string, doc: ~s(the change, formatted: "+24%"))
    attr(:direction, :string, required: true, values: ~w(up down flat))
    attr(:good, :string, values: ~w(up down none), doc: ~s(which way is good news; default "up"))
  end

  def number_card(assigns) do
    assigns =
      assigns
      |> assign(:trend_config, trend_config(assigns))
      |> assign(:link?, !!(assigns.navigate || assigns.patch || assigns.href))

    ~H"""
    <div id={@id} class={["card number-card", @class]} data-slot="number-card" {@rest}>
      <.chart
        :if={@trend_config}
        id={"#{@id}-trend"}
        label={"#{@label} trend"}
        config={@trend_config}
        format={@format}
        variant="trend"
        class="number-card-trend"
      />
      <div class="number-card-body">
        <p class="number-card-label">
          <.link
            :if={@link?}
            navigate={@navigate}
            patch={@patch}
            href={@href}
            class="number-card-link"
          >
            {@label}
          </.link>
          <%= if !@link? do %>
            {@label}
          <% end %>
          <.number_card_help :if={@help} id={"#{@id}-help"} label={@label} help={@help} />
        </p>
        <p class="number-card-value">{@value}</p>
        <p :if={@inner_block != []} class="number-card-description">
          {render_slot(@inner_block)}
        </p>
        <div :if={@change != []} class="number-card-changes">
          <span :for={change <- @change} class="number-card-change-group">
            <span class="badge number-card-vs">{change.vs}</span>
            <span :if={change[:by]} class="badge number-card-change" data-tone={tone(change)}>
              {change.by}
            </span>
            <span :if={change[:percent]} class="badge number-card-change" data-tone={tone(change)}>
              <span class={arrow(change.direction)} aria-hidden="true"></span>{change.percent}
            </span>
          </span>
        </div>
      </div>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:label, :string, required: true)
  attr(:help, :string, required: true)

  # A ? whose text shows on hover, on focus, or when tapped (a CSS-only popover, as `popover/1`)
  defp number_card_help(assigns) do
    ~H"""
    <span class="dropdown dropdown-hover number-card-help">
      <span
        tabindex="0"
        role="button"
        class="number-card-help-trigger"
        aria-label={"About #{@label}"}
        aria-describedby={@id}
      >
        <span class="hero-question-mark-circle" aria-hidden="true"></span>
      </span>
      <span id={@id} role="tooltip" class="dropdown-content number-card-help-content">{@help}</span>
    </span>
    """
  end

  # Good news when it moved the way that's good; a flat change, or one where neither way is good,
  # is neutral
  defp tone(%{direction: "flat"}), do: "neutral"

  defp tone(%{direction: direction} = change) do
    case Map.get(change, :good, "up") do
      "none" -> "neutral"
      ^direction -> "good"
      _other -> "bad"
    end
  end

  # literal class names so the Tailwind scanner can see them
  defp arrow("up"), do: "hero-arrow-up-mini"
  defp arrow("down"), do: "hero-arrow-down-mini"
  defp arrow("flat"), do: "hero-minus-mini"

  defp trend_config(%{trend: trend, label: label, color: color}) do
    case trim_trend(trend) do
      [_, _ | _] = points ->
        {labels, values} =
          points
          |> Enum.with_index(1)
          |> Enum.map(fn
            {{point_label, value}, _} -> {to_string(point_label), value}
            {value, n} -> {Integer.to_string(n), value}
          end)
          |> Enum.unzip()

        %{
          type: "line",
          data: %{
            labels: labels,
            # a step with no number (no sales that day) is bridged rather than left as a gap
            datasets: [
              %{label: label, data: values, color: color, fill: "start", spanGaps: true}
            ]
          },
          # no layout: the hook draws a trend edge to edge (variant="trend")
          options: %{
            plugins: %{legend: %{display: false}, tooltip: %{enabled: false}},
            scales: %{x: %{display: false}, y: %{display: false}}
          }
        }

      _too_few ->
        nil
    end
  end

  # Missing points at the ends go: the x axis would carry on past the last number and leave the
  # line and its fill stopping in a vertical cliff
  defp trim_trend(trend) do
    trend
    |> Enum.drop_while(&missing_point?/1)
    |> Enum.reverse()
    |> Enum.drop_while(&missing_point?/1)
    |> Enum.reverse()
  end

  defp missing_point?({_label, value}), do: is_nil(value)
  defp missing_point?(value), do: is_nil(value)

  # ---------------------------------------------------------------------------
  # The screen-reader table: the config's numbers, one row per label (a pie's
  # slices, a bar chart's bars) and one column per dataset; a scatter or bubble
  # chart lists its points. End labels add a last column.
  # ---------------------------------------------------------------------------

  @points_types ~w(scatter bubble)

  @doc false
  def table(config, format) do
    type = to_string(get(config, :type) || "bar")
    data = get(config, :data) || %{}
    labels = get(data, :labels) || []
    datasets = get(data, :datasets) || []
    end_labels = config |> get(:options) |> get(:plugins) |> get(:endLabels) |> get(:labels)

    if type in @points_types do
      points_table(datasets, format, type)
    else
      head = Enum.map(datasets, &(get(&1, :label) || "Value"))

      rows =
        labels
        |> Enum.with_index()
        |> Enum.map(fn {label, i} ->
          cells = Enum.map(datasets, fn ds -> cell(Enum.at(get(ds, :data) || [], i), format) end)
          {to_string(label), cells ++ end_label_cell(end_labels, i)}
        end)

      %{head: head ++ if(is_list(end_labels), do: [""], else: []), rows: rows}
    end
  end

  defp end_label_cell(labels, i) when is_list(labels), do: [to_string(Enum.at(labels, i) || "")]
  defp end_label_cell(_, _), do: []

  defp points_table(datasets, format, type) do
    keys = [:x, :y] ++ if type == "bubble", do: [:r], else: []

    rows =
      for ds <- datasets, point <- get(ds, :data) || [] do
        values = Enum.map(keys, &cell(get(point, &1), format))
        {to_string(get(ds, :label) || ""), values}
      end

    %{head: Enum.map(keys, &Atom.to_string/1), rows: rows}
  end

  # a point given as {x, y} (a bar's object data): its value is y, or x for a
  # horizontal bar - whichever isn't the label
  defp cell(%{} = point, format) when not is_struct(point) do
    cell(get(point, :y) || get(point, :x), format)
  end

  defp cell(nil, _format), do: "-"
  defp cell(value, format), do: format.(value)

  defp get(%{} = map, key) when is_atom(key) and not is_struct(map),
    do: Map.get(map, key, Map.get(map, Atom.to_string(key)))

  defp get(_, _), do: nil

  @doc false
  # 24500 -> "24,500"; 1234.5 -> "1,234.5"; strings and anything else as text.
  def format_number(n) when is_integer(n) do
    sign = if n < 0, do: "-", else: ""
    sign <> group(Integer.to_string(abs(n)))
  end

  def format_number(n) when is_float(n) do
    rounded = Float.round(n, 2)

    if rounded == trunc(rounded) do
      format_number(trunc(rounded))
    else
      [int, frac] = :erlang.float_to_binary(abs(rounded), decimals: 2) |> String.split(".")
      sign = if rounded < 0, do: "-", else: ""
      sign <> group(int) <> "." <> String.trim_trailing(frac, "0")
    end
  end

  def format_number(%{__struct__: Decimal} = d), do: format_number(decimal_to_number(d))
  def format_number(other), do: to_string(other)

  defp group(digits) do
    digits
    |> String.reverse()
    |> String.graphemes()
    |> Enum.chunk_every(3)
    |> Enum.map_join(",", &Enum.join/1)
    |> String.reverse()
  end

  # ---------------------------------------------------------------------------
  # A small JSON encoder for the config (the package has no JSON dependency).
  # Decimals (money from Ecto) encode as numbers; dates and other structs with
  # a String.Chars implementation as strings.
  # ---------------------------------------------------------------------------

  @doc false
  def encode(%{__struct__: Decimal} = d), do: number(decimal_to_number(d))

  def encode(%{__struct__: _} = struct) do
    if String.Chars.impl_for(struct) do
      encode(to_string(struct))
    else
      raise ArgumentError, "chart config: can't encode #{inspect(struct)} as JSON"
    end
  end

  def encode(%{} = map) do
    "{" <>
      Enum.map_join(map, ",", fn {k, v} -> encode(to_string(k)) <> ":" <> encode(v) end) <> "}"
  end

  def encode(list) when is_list(list), do: "[" <> Enum.map_join(list, ",", &encode/1) <> "]"
  def encode(v) when is_number(v), do: number(v)
  def encode(v) when is_boolean(v), do: to_string(v)
  def encode(nil), do: "null"
  def encode(v) when is_atom(v), do: encode(Atom.to_string(v))

  def encode(s) when is_binary(s) do
    escaped =
      for <<c::utf8 <- s>>, into: "" do
        case c do
          ?" -> "\\\""
          ?\\ -> "\\\\"
          ?\n -> "\\n"
          ?\r -> "\\r"
          ?\t -> "\\t"
          c when c < 0x20 -> "\\u" <> String.pad_leading(Integer.to_string(c, 16), 4, "0")
          c -> <<c::utf8>>
        end
      end

    "\"" <> escaped <> "\""
  end

  def encode(other) do
    raise ArgumentError, "chart config: can't encode #{inspect(other)} as JSON"
  end

  defp number(n) when is_integer(n), do: Integer.to_string(n)
  defp number(n) when is_float(n), do: Float.to_string(n)

  defp decimal_to_number(d) do
    # Decimal is the app's dependency, not ours: call it at runtime
    if apply(Decimal, :integer?, [d]),
      do: apply(Decimal, :to_integer, [d]),
      else: apply(Decimal, :to_float, [d])
  end
end
