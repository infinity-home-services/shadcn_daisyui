defmodule ShadcnDaisyuiDemoWeb.Catalog.ChartPages do
  @moduledoc """
  The catalog pages for the chart kit: `<.chart>` and `<.number_card>`. Like
  `ShadcnDaisyuiDemoWeb.Catalog.CodeBlockPage`, each example's `code` is
  rendered from the real components at runtime (through `DataPages.code/1`,
  minus the LiveView-only attributes), so the code tab is the markup the
  component renders today, as a plain-HTML recipe that works with
  `initCharts()`. Everything renders from fixed, made-up data; the config
  builders are public so the `/lab/charts` LiveView draws the same charts.
  """
  use Phoenix.Component

  import ShadcnDaisyui.Components,
    only: [card: 1, card_body: 1, card_title: 1, card_description: 1]

  import ShadcnDaisyui.Components.Chart

  alias ShadcnDaisyuiDemoWeb.Catalog.DataPages

  @sources [__MODULE__, DataPages, ShadcnDaisyui.Components, ShadcnDaisyui.Components.Chart]

  @doc "The pages, built once per code version (see `DataPages.all/0`)."
  def all do
    key = {__MODULE__, Enum.map(@sources, & &1.module_info(:md5))}

    case :persistent_term.get(key, nil) do
      nil ->
        pages = [chart(), number_card()]
        :persistent_term.put(key, pages)
        pages

      pages ->
        pages
    end
  end

  # ---------------------------------------------------------------------------
  # Fixed, made-up data and the configs built from it
  # ---------------------------------------------------------------------------

  @days for d <- 13..26, do: "#{Enum.at(~w(Mon Tue Wed Thu Fri Sat Sun), rem(d - 13, 7))} #{d}"
  @daily_sales [
    18_400,
    22_100,
    19_800,
    26_300,
    31_200,
    12_400,
    6_800,
    20_900,
    24_700,
    21_500,
    28_900,
    33_600,
    14_100,
    7_900
  ]

  @doc false
  def days, do: @days
  @doc false
  def daily_sales, do: @daily_sales

  # name, sale, margin, closed, ran
  @people [
    {"pat", "Pat Lee", 24_500, 9_310, 2, 3},
    {"sam", "Sam Okafor", 21_800, 7_630, 3, 4},
    {"riley", "Riley Chen", 17_200, 6_880, 2, 2},
    {"jordan", "Jordan Diaz", 14_900, 4_470, 1, 3},
    {"morgan", "Morgan Ito", 11_300, 4_290, 2, 5},
    {"casey", "Casey Park", 6_400, 1_920, 1, 2}
  ]

  @doc false
  def people, do: @people

  @usd %{style: "currency", currency: "USD", maximumFractionDigits: 0}

  @doc false
  def money(n), do: "$" <> ShadcnDaisyui.Components.Chart.format_number(round(n))

  @doc "Sales by day: one series of vertical bars."
  def daily_config(days \\ @days, sales \\ @daily_sales) do
    %{
      type: "bar",
      data: %{labels: days, datasets: [%{label: "Sales", data: sales}]},
      options: %{scales: %{y: %{ticks: %{format: @usd}}}}
    }
  end

  @doc """
  A leaderboard: longest first, the margin as the darker part of each sale.
  `position: "above"` puts each name and label above its bar at every width.
  """
  def leaderboard_config(people \\ @people, opts \\ []) do
    people = Enum.sort_by(people, fn {_, _, sale, _, _, _} -> -sale end)

    %{
      type: "bar",
      data: %{
        labels: Enum.map(people, &elem(&1, 1)),
        keys: Enum.map(people, &elem(&1, 0)),
        datasets: [
          %{
            label: "Margin",
            key: "margin",
            data: Enum.map(people, &elem(&1, 3)),
            color: "chart-1"
          },
          %{
            label: "Rest of the sale",
            key: "rest",
            data: Enum.map(people, fn {_, _, sale, margin, _, _} -> sale - margin end),
            color: "chart-1/35"
          }
        ]
      },
      options: %{
        indexAxis: "y",
        scales: %{
          x: %{stacked: true, display: false, ticks: %{format: @usd}},
          y: %{stacked: true}
        },
        plugins: %{
          endLabels:
            Map.merge(
              %{
                labels:
                  Enum.map(people, fn {_, _, sale, margin, closed, ran} ->
                    "#{money(sale)} · #{round(margin * 100 / sale)}% margin · #{closed} for #{ran}"
                  end)
              },
              Map.new(Keyword.take(opts, [:position]))
            )
        }
      }
    }
  end

  @progress [
    {"resulted", "Resulted", 14, "chart-1"},
    {"needs_result", "Needs a result", 3, "chart-1/65"},
    {"in_progress", "In progress", 4, "chart-1/35"},
    {"to_come", "Still to come", 9, "muted-foreground/25"}
  ]

  @doc false
  def progress, do: @progress

  @doc """
  A progress row: one stacked bar, its parts the states, the axes hidden.
  `segment_labels: true` puts each part's count on it (where it fits) and in
  the legend.
  """
  def progress_config(parts \\ @progress, opts \\ []) do
    total = parts |> Enum.map(&elem(&1, 2)) |> Enum.sum()

    %{
      type: "bar",
      data: %{
        labels: [Keyword.get(opts, :label, "Today's appointments")],
        datasets:
          Enum.map(parts, fn {key, label, n, color} ->
            %{label: label, key: key, data: [n], color: color}
          end)
      },
      options:
        Map.merge(
          %{
            indexAxis: "y",
            scales: %{
              x: %{stacked: true, display: false, max: total},
              y: %{stacked: true, display: false}
            }
          },
          if(opts[:segment_labels], do: %{plugins: %{segmentLabels: true}}, else: %{})
        )
    }
  end

  # where a week's appointments stand: the 4 is too narrow for its number on a phone
  @week_parts [
    {"completed", "Completed", 61, "chart-1"},
    {"needs_result", "Needs a result", 9, "chart-1/65"},
    {"no_show", "Didn't happen", 4, "chart-1/35"},
    {"to_come", "Still to come", 26, "muted-foreground/25"}
  ]

  @doc false
  def week_parts, do: @week_parts

  @week ~w(Mon Tue Wed Thu Fri Sat Sun)

  @doc "This week against last week: the comparison is muted (emphasis)."
  def weeks_config do
    %{
      type: "line",
      data: %{
        labels: @week,
        datasets: [
          %{label: "This week", data: [18_400, 22_100, 19_800, 26_300, 31_200, 12_400, 6_800]},
          %{
            label: "Last week",
            data: [16_900, 18_200, 21_400, 19_700, 24_800, 15_100, 5_900],
            color: "muted-foreground"
          }
        ]
      },
      options: %{scales: %{y: %{ticks: %{format: @usd}}}}
    }
  end

  @doc "Leads by source: a doughnut (part to whole, a few slices)."
  def sources_config do
    %{
      type: "doughnut",
      data: %{
        labels: ["Website", "Referral", "Phone", "Events"],
        datasets: [%{label: "Leads", data: [46, 28, 17, 9]}]
      },
      options: %{cutout: "62%", plugins: %{legend: %{position: "right"}}}
    }
  end

  @doc false
  def sales_trend,
    do: Enum.zip(@days, @daily_sales)

  @doc false
  def appointments_trend,
    do: Enum.zip(@days, [9, 11, 10, 12, 14, 6, 3, 10, 12, 11, 13, 15, 7, 4])

  @doc false
  def close_rate_trend,
    do: Enum.zip(@days, [33, 35, 31, 36, 38, 30, 29, 34, 37, 35, 40, 41, 36, 38])

  # ---------------------------------------------------------------------------
  # <.chart>
  # ---------------------------------------------------------------------------

  defp chart do
    %{
      slug: "chart",
      title: "Chart",
      description:
        "Bar, line and any other Chart.js chart, drawn from the theme: one component and one hook, data from the server.",
      hook: true,
      guidance: %{
        use_when: [
          "Change over time: a line (one or a few series), or vertical bars for days and weeks",
          "A ranking or leaderboard: horizontal bars, longest first, each bar labelled at its end",
          "Progress through states: one horizontal stacked bar (resulted, needs a result, in progress, still to come)",
          "Comparing a handful of series: grouped or stacked bars with a legend"
        ],
        avoid_when: [
          "A single number, with or without a trend - use a number card",
          "Exact values people look up or copy - use a table (every chart also renders its numbers as a hidden table)",
          "More than five series - fold the rest into \"Other\", or split into small charts",
          "Comparing close values as slices - a pie or doughnut only shows part to whole at a glance"
        ],
        sizing:
          "The canvas is 16rem high (canvas_class=\"h-80\" changes it); horizontal bar charts size themselves to their rows (36px each, 48px with the labels above the bars, plus 16px over the first row for its text). Bars are at most 24px thick with a 4px rounded end, lines 2px, text 12px.",
        responsive:
          "Charts fill their container's width and redraw on resize. On a narrow screen a leaderboard's end labels move above each bar with the name, so the bars keep their width (endLabels position: \"above\" keeps them there at every width), and a segment label shows only while its part is wide enough for it - the legend keeps every number. Put charts in a grid that stacks on phones (one column below sm).",
        ios:
          "Swift Charts: BarMark / LineMark / SectorMark with the same five chart colours, .chartXAxis(.hidden) for a leaderboard, and .accessibilityChartDescriptor for the numbers."
      },
      props: [
        %{name: "id", type: "string (required)", default: "-"},
        %{
          name: "label",
          type: "string (required): the accessible name and table caption",
          default: "-"
        },
        %{
          name: "config",
          type: "map (required): a Chart.js config - type, data, options",
          default: "-"
        },
        %{
          name: "on_click",
          type: "event: pushes %{id, key, series, index} for a clicked bar, point or slice",
          default: "nil"
        },
        %{name: "target", type: "phx-target for on_click (a LiveComponent)", default: "nil"},
        %{
          name: "format",
          type: "fn number -> text end, for the hidden table's numbers",
          default: "digits grouped (24,500)"
        },
        %{
          name: "canvas_class",
          type: "any (on the canvas box, e.g. h-80)",
          default: "16rem high"
        },
        %{name: "class", type: "any (on the figure)", default: "nil"},
        %{
          name: "dataset color",
          type:
            "token: chart-1…5, muted, muted-foreground, primary, destructive, success, warning, info; \"chart-1/40\" = 40% opacity; a list colours each bar",
          default: "chart-1…5 in order"
        },
        %{name: "dataset key", type: "sent as series with a click", default: "the label"},
        %{
          name: "data.keys",
          type: "one key per label, sent as key with a click",
          default: "the labels"
        },
        %{
          name: "options.plugins.endLabels.labels",
          type: "one text per bar, drawn at its end",
          default: "nil"
        },
        %{
          name: "options.plugins.endLabels.position",
          type:
            "\"auto\" (at the bar's end; a horizontal bar's name and label move above it on a narrow screen) | \"above\" (above the bar at every width)",
          default: "\"auto\""
        },
        %{
          name: "options.plugins.segmentLabels",
          type:
            "true: on stacked bars, each part's value centred in it where the text and 4px either side fit (the bar 16px thick or more); a one-row stack's legend gives every part's number | \"legend\": the legend's numbers only, nothing drawn on the bar",
          default: "false"
        }
      ],
      notes:
        "Needs the optional chart entry: import { ChartHooks } from \"shadcn_daisyui/charts\" and spread it into the LiveSocket's hooks (dead views: initCharts()). Chart.js ships inside the package (vendor/, pinned), so nothing loads from a CDN and the core shadcn_daisyui import stays free of it. Never put colours in the config: series take --chart-1…5 in order (or a dataset's color token), text --foreground / --muted-foreground, grid lines --border-color, and the tooltip is a popover. The chart redraws when the theme changes. Values in tooltips follow the value axis's ticks.format (Chart.js's Intl.NumberFormat options); the ticks show the same format, compacted ($25K). Labels arrive formatted - there is no date adapter. When LiveView changes config, the same chart moves to the new data.",
      specs: %{
        anatomy: [
          %{
            part: "Figure",
            description:
              "The <figure> with the hook; data-config holds the Chart.js config as JSON."
          },
          %{
            part: "Canvas box",
            description:
              "phx-update=\"ignore\": Chart.js's container (role img, or application when clickable), focusable when it has tooltips."
          },
          %{
            part: "Tooltip",
            description:
              "A popover in the top layer: the label, then a colour key, the series name and the value per series."
          },
          %{
            part: "Legend",
            description: "Under the chart for two or more series; click a series to hide it."
          },
          %{
            part: "Table",
            description:
              "The numbers as a visually hidden table, captioned by label, for screen readers."
          }
        ],
        measurements: [
          %{
            property: "Height",
            value: "16rem; horizontal bars: 36px rows (48px with labels above)"
          },
          %{property: "Bars", value: "max 24px thick, 4px rounded data end, square baseline"},
          %{property: "Stacked parts", value: "2px gap in the surface colour between parts"},
          %{
            property: "Segment labels",
            value:
              "12px, centred in the part; shown where the text's width + 8px fits inside the part and the bar is 16px thick or more; foreground or the surface colour, whichever reads 4.5:1 on the fill (black or white where neither does)"
          },
          %{
            property: "Lines",
            value:
              "2px, round joins; area fill at 10%; points hidden, 8px on hover with a 2px ring"
          },
          %{
            property: "Grid",
            value: "1px var(--border-color) on the value axis only, no axis lines"
          },
          %{
            property: "Text",
            value: "12px; ticks muted-foreground, legend and end labels foreground"
          },
          %{
            property: "Tooltip",
            value: "popover surface, rounded-lg, shadow-lg, 12px; values tabular"
          }
        ],
        tokens: [
          "chart-1",
          "chart-2",
          "chart-3",
          "chart-4",
          "chart-5",
          "foreground",
          "muted-foreground",
          "border-color",
          "popover"
        ]
      },
      accessibility: %{
        roles:
          "The canvas box is role=\"img\" named by label (role=\"application\" with aria-roledescription=\"chart\" when on_click is set). A visually hidden <table> after it holds every number, with label as its caption: the canvas itself says nothing to a screen reader.",
        keyboard: [
          %{keys: "Tab", action: "Focuses the chart (when it has tooltips)"},
          %{
            keys: "Arrow keys / Home / End",
            action:
              "Move between labels (or a single bar's parts, or a doughnut's slices), showing the tooltip"
          },
          %{keys: "Enter / Space", action: "Sends on_click for the shown label or part"},
          %{keys: "Escape", action: "Hides the tooltip"}
        ],
        focus:
          "A 3px ring around the canvas box. Moving the pointer over the chart hands the tooltip back to the pointer.",
        screen_reader:
          "The hidden table reads the numbers; while the arrow keys move, a polite live region reads the tooltip (\"Mon 13: Sales $18,400\").",
        touch_target:
          "A tap anywhere in a bar's row (or a line's column) picks that label: the hit area is the row, not the painted bar.",
        reduced_motion:
          "Animation is off under prefers-reduced-motion; otherwise new data moves in 300ms. Theme changes redraw instantly."
      },
      swiftui: %{
        code: ~S"""
        Chart(people) { person in
            BarMark(x: .value("Margin", person.margin), y: .value("Person", person.name))
                .foregroundStyle(Color.chart1)
            BarMark(x: .value("Rest", person.sale - person.margin), y: .value("Person", person.name))
                .foregroundStyle(Color.chart1.opacity(0.35))
                .annotation(position: .trailing) { Text(person.summary).font(.caption) }
        }
        .chartXAxis(.hidden)
        .accessibilityChartDescriptor(LeaderboardDescriptor(people: people))
        """,
        notes:
          "Swift Charts draws the same forms: stacked BarMarks for a leaderboard (an annotation at the end), LineMark + AreaMark for trends, SectorMark for part to whole. Use the five chart colours in order and give each chart an AXChartDescriptor so VoiceOver reads the numbers."
      },
      ios_status: :partial,
      examples: [
        %{
          title: "Bars by day",
          heex: ~S"""
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
          """,
          center: false,
          code: daily_code()
        },
        %{
          title: "Leaderboard",
          heex: ~S"""
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
          """,
          center: false,
          code: leaderboard_code()
        },
        %{
          title: "Leaderboard, labels above",
          heex: ~S"""
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
          """,
          center: false,
          code: leaderboard_above_code()
        },
        %{
          title: "Progress row",
          heex: ~S"""
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
          """,
          center: false,
          code: progress_code()
        },
        %{
          title: "Progress row, counts on the parts",
          heex: ~S"""
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
          """,
          center: false,
          code: week_progress_code()
        },
        %{
          title: "Lines: one series in colour",
          heex: ~S"""
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
          """,
          center: false,
          code: weeks_code()
        },
        %{
          title: "Any Chart.js type",
          heex: ~S"""
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
          """,
          center: false,
          code: sources_code()
        },
        %{
          title: "Light and dark",
          heex: ~S"""
          <%!-- The look comes from the tokens where the chart sits: these two islands
            pin a theme each; the page's own toggle redraws every chart. --%>
          <div data-theme="shadcn" class="rounded-xl bg-background p-4 text-foreground">
            <.chart id="themes-light" label="Leads by week (light)" config={@config} />
          </div>
          <div data-theme="shadcn-dark" class="rounded-xl bg-background p-4 text-foreground">
            <.chart id="themes-dark" label="Leads by week (dark)" config={@config} />
          </div>
          """,
          center: false,
          code: themes_code()
        }
      ]
    }
  end

  # The components' markup without LiveView-only attributes.
  defp code(rendered),
    do: rendered |> DataPages.code() |> String.replace(~s( phx-update="ignore"), "")

  defp daily_code do
    assigns = %{config: daily_config()}

    code(~H"""
    <.card class="w-full">
      <.card_body>
        <.card_title>Sales by day</.card_title>
        <.card_description>Last 2 weeks</.card_description>
        <.chart id="sales-by-day" label="Sales by day, last 2 weeks" class="mt-4" config={@config} />
      </.card_body>
    </.card>
    """)
  end

  defp leaderboard_code do
    assigns = %{config: leaderboard_config()}

    code(~H"""
    <.card class="w-full">
      <.card_body>
        <.card_title>Leaderboard</.card_title>
        <.card_description>Sales this week · click a person</.card_description>
        <.chart
          id="leaderboard"
          label="Sales by person, this week"
          on_click="open_person"
          class="mt-4"
          config={@config}
        />
      </.card_body>
    </.card>
    """)
  end

  defp leaderboard_above_code do
    assigns = %{config: leaderboard_config(@people, position: "above")}

    code(~H"""
    <.card class="w-full">
      <.card_body>
        <.card_title>Leaderboard</.card_title>
        <.card_description>Sales this week · labels above the bars</.card_description>
        <.chart
          id="leaderboard-above"
          label="Sales by person, this week"
          class="mt-4"
          config={@config}
        />
      </.card_body>
    </.card>
    """)
  end

  defp week_progress_code do
    assigns = %{
      config:
        progress_config(@week_parts, label: "This week's appointments", segment_labels: true)
    }

    code(~H"""
    <.card class="w-full">
      <.card_body>
        <.card_title>This week's appointments</.card_title>
        <.card_description>100 booked · counts on the parts</.card_description>
        <.chart id="week-progress" label="This week's appointments" class="mt-4" config={@config} />
      </.card_body>
    </.card>
    """)
  end

  defp progress_code do
    assigns = %{config: progress_config()}

    code(~H"""
    <.card class="w-full">
      <.card_body>
        <.card_title>Today's appointments</.card_title>
        <.card_description>30 booked · click a part</.card_description>
        <.chart
          id="appointments-progress"
          label="Today's appointments"
          on_click="open_state"
          class="mt-4"
          config={@config}
        />
      </.card_body>
    </.card>
    """)
  end

  defp weeks_code do
    assigns = %{config: weeks_config()}

    code(~H"""
    <.card class="w-full">
      <.card_body>
        <.card_title>Sales</.card_title>
        <.card_description>This week against last week</.card_description>
        <.chart id="sales-weeks" label="Sales this week and last week" class="mt-4" config={@config} />
      </.card_body>
    </.card>
    """)
  end

  defp sources_code do
    assigns = %{config: sources_config()}

    code(~H"""
    <.card class="w-full max-w-md">
      <.card_body>
        <.card_title>Leads by source</.card_title>
        <.card_description>This month · 100 leads</.card_description>
        <.chart
          id="lead-sources"
          label="Leads by source, this month"
          class="mt-4"
          canvas_class="h-48"
          config={@config}
        />
      </.card_body>
    </.card>
    """)
  end

  defp themes_code do
    config = %{
      type: "bar",
      data: %{
        labels: ~w(W40 W41 W42 W43),
        datasets: [
          %{label: "Website", data: [12, 15, 11, 17]},
          %{label: "Referral", data: [8, 6, 9, 10]},
          %{label: "Phone", data: [5, 7, 4, 6]}
        ]
      }
    }

    assigns = %{config: config}

    code(~H"""
    <div class="grid w-full gap-4 md:grid-cols-2">
      <div
        data-theme="shadcn"
        class="rounded-xl border border-border bg-background p-4 text-foreground"
      >
        <.chart
          id="themes-light"
          label="Leads by week and source (light)"
          canvas_class="h-56"
          config={@config}
        />
      </div>
      <div
        data-theme="shadcn-dark"
        class="rounded-xl border border-border bg-background p-4 text-foreground"
      >
        <.chart
          id="themes-dark"
          label="Leads by week and source (dark)"
          canvas_class="h-56"
          config={@config}
        />
      </div>
    </div>
    """)
  end

  # ---------------------------------------------------------------------------
  # <.number_card>
  # ---------------------------------------------------------------------------

  defp number_card do
    %{
      slug: "number-card",
      title: "Number Card",
      description:
        "A label, a big number, a line under it, and a faint trend behind the number: a dashboard's headline figures.",
      hook: true,
      guidance: %{
        use_when: [
          "A dashboard's headline figures: today's sales, appointments, close rate",
          "One number that matters, with how it got there as a faint trend",
          "A number with its breakdown under it (\"Margin $14,700 (35%)\") and its change on another period as badges (vs PP)",
          "A number people open to see what's behind it: the whole card is a link"
        ],
        avoid_when: [
          "Several series or values people compare - use a chart",
          "A list of figures with labels - use a table or a description list",
          "A status (on track, late) - say it in words with a badge, not a number"
        ],
        sizing:
          "Card padding 24px; the label 14px / 500 muted, with a 16px ? after it; the number 30px / 600, the line under it 14px muted, the change badges 12px, 8px below it. The trend fills the lower 60% of the card at 50% opacity behind the text and the badges, its peaks as clear as the rest of it.",
        responsive:
          "Lay a row of cards out in a grid: one column on phones, two from sm, four from lg. The number never wraps mid-figure; keep it short (format it on the server: $42K, 38%).",
        ios:
          "A GroupBox with the label, a .title.weight(.semibold) number and a caption, over a Chart with an AreaMark + LineMark and .chartXAxis(.hidden) / .chartYAxis(.hidden)."
      },
      props: [
        %{name: "id", type: "string (required)", default: "-"},
        %{name: "label", type: "string (required)", default: "-"},
        %{name: "value", type: "string (required): the number, formatted", default: "-"},
        %{
          name: "trend",
          type: "[number] or [{label, number}], oldest first",
          default: "[] (no trend)"
        },
        %{name: "color", type: "the trend's colour token", default: "chart-1"},
        %{
          name: "help",
          type: "string: what the number counts, in plain words (a ? beside the label)",
          default: "nil"
        },
        %{
          name: "navigate / patch / href",
          type: "the whole card is a link (the label is its text)",
          default: "nil"
        },
        %{
          name: "format",
          type: "fn number -> text end, for the trend's hidden table",
          default: "digits grouped"
        },
        %{name: "class", type: "any", default: "nil"},
        %{name: "inner_block", type: "slot: the line under the number", default: "-"},
        %{
          name: ":change",
          type:
            "slot, one per period: vs (\"vs PP\"), by (\"+$8,000\"), percent (\"+24%\"), direction (up/down/flat), good (up/down/none, default up)",
          default: "-"
        }
      ],
      notes:
        "The trend is a <.chart> line with its axes, grid, legend, tooltip and points hidden and its area filled, so it needs the chart entry (shadcn_daisyui/charts); without it the card still shows the number and the line under it. Labels name the rows of the trend's hidden table ({\"Mon 13\", 18_400}); bare numbers are numbered 1, 2, 3, and a nil (a day with nothing to count) is bridged, never a gap. The value, the line under it and the changes arrive formatted from the server. A change is good news (green) when it moved the way `good` says, bad news (red) the other way, neutral when flat; its sign and arrow say the same, never colour alone. A linked card's label is the link, stretched over the card, so the help stays its own button.",
      specs: %{
        anatomy: [
          %{
            part: "Card",
            description:
              "The card surface (rounded-xl, 1px border, shadow-sm). It doesn't clip, so the help can float over its edge; the trend clips itself."
          },
          %{
            part: "Label",
            description:
              "What the number is, sentence case, no colon; the link's text when the card is a link."
          },
          %{
            part: "Help",
            description:
              "A ? after the label; what the number counts, in a popover on hover, focus or tap."
          },
          %{
            part: "Value",
            description: "The number, formatted on the server, proportional figures."
          },
          %{
            part: "Line under",
            description: "A comparison or breakdown: \"Margin $14,700 (35%)\"."
          },
          %{
            part: "Changes",
            description:
              "Per period, an outline badge naming it (vs PP), then the difference and the change, tinted good, bad or neutral, each edged in its own tone."
          },
          %{
            part: "Trend",
            description:
              "A filled line chart behind the text and badges, edge to edge inside the card's border, aria-hidden, with its own hidden table."
          }
        ],
        measurements: [
          %{property: "Padding", value: "1.5rem (24px)"},
          %{property: "Label", value: "0.875rem / 500, muted-foreground"},
          %{property: "Value", value: "1.875rem / 600, letter-spacing -0.025em"},
          %{property: "Line under", value: "0.875rem, muted-foreground"},
          %{property: "Help", value: "16px icon, 44px target on touch, 16rem popover"},
          %{
            property: "Changes",
            value:
              "12px badges, 8px apart (4px within a period), 8px below the line; tints of success and destructive on the card, a 1px border in the badge's tone at 30% over the card (the period's: foreground at 18%); text at least 4.5:1"
          },
          %{
            property: "Trend",
            value:
              "lower 60% of the card, edge to edge (no auto padding), the peak a sixth of its height below the top and the range at least a fifth of the top value (a flat series is a level line), 50% opacity, 2px line, 25% area fill, gaps bridged"
          }
        ],
        tokens: [
          "card",
          "border-color",
          "foreground",
          "muted",
          "muted-foreground",
          "chart-1",
          "color-success",
          "destructive",
          "popover"
        ]
      },
      accessibility: %{
        roles:
          "Text (a <p> each for the label, the number and the line under it), the label a link when the card is one, the help a button described by its text (role=tooltip). The trend's canvas is aria-hidden; its numbers are in a visually hidden table named \"<label> trend\".",
        keyboard: [
          %{keys: "Tab", action: "The card's link (when it is one), then the help"},
          %{keys: "Enter", action: "Opens the card's link"}
        ],
        focus:
          "A linked card shows the 3px ring around the whole card; the help shows it around the ? and opens its text.",
        screen_reader:
          "Reads the label (\"Sales, link\"), the number, the line under it and the changes (\"vs PP, +$8,000, +24%\"), then the trend's table. The help button reads \"About Sales\" and its text.",
        touch_target:
          "A linked card is one big target; the help's ? has a 44px target and opens on tap.",
        reduced_motion: "The trend doesn't animate under prefers-reduced-motion."
      },
      swiftui: %{
        code: ~S"""
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
        """,
        notes:
          "Keep the number in Text so VoiceOver reads it; the trend behind it is decoration (accessibilityHidden), with the comparison said in words under the number."
      },
      ios_status: :guidance_only,
      examples: [
        %{
          title: "A row of number cards",
          heex: ~S"""
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
          """,
          center: false,
          code: number_cards_code()
        }
      ]
    }
  end

  defp number_cards_code do
    assigns = %{
      sales: sales_trend(),
      appointments: appointments_trend(),
      close_rate: close_rate_trend()
    }

    code(~H"""
    <div class="grid w-full gap-4 sm:grid-cols-2 lg:grid-cols-4">
      <.number_card
        id="sales"
        label="Sales"
        value="$42,000"
        help="Every sale booked this week, at its sold price."
        trend={@sales}
        href="#number-cards"
      >
        Margin $14,700 (35%) <:change vs="vs PP" by="+$8,000" percent="+24%" direction="up" />
      </.number_card>
      <.number_card id="appointments" label="Appointments" value="30" trend={@appointments}>
        vs. 27 last Tuesday
      </.number_card>
      <.number_card
        id="close-rate"
        label="Close rate"
        value="38%"
        trend={@close_rate}
        color="chart-3"
        help="Visits that sold, out of visits that happened."
      >
        11 of 29 run <:change vs="vs PP" by="-2.4 pts" percent="-6%" direction="down" />
      </.number_card>
      <.number_card id="average-sale" label="Average sale" value="$3,818">
        2 cancellations
      </.number_card>
    </div>
    """)
  end
end
