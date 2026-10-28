defmodule ShadcnDaisyui.Components.ChartTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.Components.Chart

  alias ShadcnDaisyui.Components.Chart

  defp render(template) do
    template |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  defp unescape(s) do
    s
    |> String.replace("&quot;", "\"")
    |> String.replace("&#39;", "'")
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
    |> String.replace("&amp;", "&")
  end

  # the figure's data-config, decoded
  defp config(html, id) do
    [_, json] = Regex.run(~r/<figure id="#{id}"[^>]*data-config="([^"]*)"/, html)
    json |> unescape() |> JSON.decode!()
  end

  # the hidden table: {head, rows}
  defp table(html) do
    [_, t] = Regex.run(~r{<table data-slot="chart-table" class="sr-only">(.*?)</table>}s, html)
    [_, caption] = Regex.run(~r{<caption>(.*?)</caption>}s, t)

    head =
      Regex.scan(~r{<th scope="col">(.*?)</th>}s, t, capture: :all_but_first) |> List.flatten()

    rows =
      ~r{<tr>\s*<th scope="row">(.*?)</th>(.*?)</tr>}s
      |> Regex.scan(t, capture: :all_but_first)
      |> Enum.map(fn [label, cells] ->
        {label, Regex.scan(~r{<td>(.*?)</td>}s, cells, capture: :all_but_first) |> List.flatten()}
      end)

    {caption, head, rows}
  end

  @bars %{
    type: "bar",
    data: %{
      labels: ["Mon 13", "Tue 14"],
      datasets: [%{label: "Sales", data: [18_400, 22_100.5]}]
    },
    options: %{scales: %{y: %{ticks: %{format: %{style: "currency", currency: "USD"}}}}}
  }

  describe "chart/1" do
    test "a figure with the hook, the config as JSON, and an ignored canvas box" do
      assigns = %{config: @bars}
      html = render(~H|<.chart id="sales" label="Sales by day" config={@config} class="mt-4" />|)

      assert html =~ ~s(<figure id="sales" class="chart mt-4" data-slot="chart")
      assert html =~ ~s(phx-hook="ShadcnChart")
      assert html =~ ~s(data-label="Sales by day")
      assert html =~ ~s(id="sales-canvas" data-slot="chart-canvas")
      assert html =~ ~s(phx-update="ignore")
      assert html =~ ~s(role="img" aria-label="Sales by day")
      assert html =~ ~s(<div data-slot="chart-status" class="sr-only" aria-live="polite"></div>)
      refute html =~ "data-on-click"
      refute html =~ "aria-roledescription"

      assert config(html, "sales") == %{
               "type" => "bar",
               "data" => %{
                 "labels" => ["Mon 13", "Tue 14"],
                 "datasets" => [%{"label" => "Sales", "data" => [18_400, 22_100.5]}]
               },
               "options" => %{
                 "scales" => %{
                   "y" => %{
                     "ticks" => %{"format" => %{"style" => "currency", "currency" => "USD"}}
                   }
                 }
               }
             }
    end

    test "on_click: the event, the target, and an application role" do
      assigns = %{config: @bars}

      html =
        render(~H"""
        <.chart id="sales" label="Sales" config={@config} on_click="open_day" target="#panel" />
        """)

      assert html =~ ~s(data-on-click="open_day")
      assert html =~ ~s(phx-target="#panel")
      assert html =~ ~s(role="application" aria-roledescription="chart" aria-label="Sales")
    end

    test "canvas_class sizes the canvas box" do
      assigns = %{config: @bars}
      html = render(~H|<.chart id="c" label="C" config={@config} canvas_class="h-80" />|)
      assert html =~ ~s(data-slot="chart-canvas" class="h-80")
    end

    test "the numbers render as a hidden table captioned by the label" do
      assigns = %{config: @bars}
      html = render(~H|<.chart id="sales" label="Sales by day" config={@config} />|)

      assert table(html) ==
               {"Sales by day", ["Sales"], [{"Mon 13", ["18,400"]}, {"Tue 14", ["22,100.5"]}]}
    end

    test "format turns the table's numbers into text" do
      assigns = %{config: @bars, money: &("$" <> Chart.format_number(round(&1)))}
      html = render(~H|<.chart id="s" label="Sales" config={@config} format={@money} />|)
      {_, _, rows} = table(html)
      assert rows == [{"Mon 13", ["$18,400"]}, {"Tue 14", ["$22,101"]}]
    end

    test "a column per dataset, end labels as the last column, gaps as -" do
      config = %{
        type: "bar",
        data: %{
          labels: ["Pat Lee", "Sam Okafor"],
          datasets: [
            %{label: "Margin", data: [9_310, nil]},
            %{label: "Rest of the sale", data: [15_190, 14_170]}
          ]
        },
        options: %{
          indexAxis: "y",
          plugins: %{endLabels: %{labels: ["$24,500 · 38% margin", "$21,800 · 35% margin"]}}
        }
      }

      assigns = %{config: config}
      html = render(~H|<.chart id="lb" label="Leaderboard" config={@config} />|)

      assert table(html) ==
               {"Leaderboard", ["Margin", "Rest of the sale", ""],
                [
                  {"Pat Lee", ["9,310", "15,190", "$24,500 · 38% margin"]},
                  {"Sam Okafor", ["-", "14,170", "$21,800 · 35% margin"]}
                ]}
    end

    test "a pie's slices are its rows; string keys work too" do
      config = %{
        "type" => "doughnut",
        "data" => %{
          "labels" => ["Website", "Referral"],
          "datasets" => [%{"label" => "Leads", "data" => [46, 28]}]
        }
      }

      assigns = %{config: config}
      html = render(~H|<.chart id="pie" label="Leads by source" config={@config} />|)

      assert table(html) ==
               {"Leads by source", ["Leads"], [{"Website", ["46"]}, {"Referral", ["28"]}]}
    end

    test "a scatter chart lists its points" do
      config = %{
        type: "scatter",
        data: %{datasets: [%{label: "Jobs", data: [%{x: 3, y: 1200}, %{x: 5, y: 2_400}]}]}
      }

      assigns = %{config: config}
      html = render(~H|<.chart id="sc" label="Jobs" config={@config} />|)

      assert table(html) ==
               {"Jobs", ["x", "y"], [{"Jobs", ["3", "1,200"]}, {"Jobs", ["5", "2,400"]}]}
    end

    test "labels and config text are escaped" do
      config = %{
        type: "bar",
        data: %{labels: ["<b>x</b>"], datasets: [%{label: "A&B", data: [1]}]}
      }

      assigns = %{config: config}
      html = render(~H|<.chart id="esc" label="Q&A <chart>" config={@config} />|)

      refute html =~ "<b>x</b>"
      assert html =~ "<caption>Q&amp;A &lt;chart&gt;</caption>"
      assert config(html, "esc")["data"]["labels"] == ["<b>x</b>"]
    end
  end

  describe "number_card/1" do
    test "label, value, the line under it, and a trend chart behind them" do
      assigns = %{trend: [{"Mon", 12_400}, {"Tue", 9_800}]}

      html =
        render(~H"""
        <.number_card id="sales" label="Sales" value="$42,000" trend={@trend}>
          Margin $14,700 (35%)
        </.number_card>
        """)

      assert html =~ ~r{<div id="sales" class="card number-card\s*" data-slot="number-card">}
      assert html =~ ~r{<p class="number-card-label">\s*Sales\s*</p>}
      assert html =~ ~s(<p class="number-card-value">$42,000</p>)
      assert html =~ ~r{<p class="number-card-description">\s*Margin \$14,700 \(35%\)\s*</p>}

      assert html =~ ~s(<figure id="sales-trend" class="chart number-card-trend")
      assert html =~ ~s(data-variant="trend")
      assert html =~ ~s(aria-hidden="true")

      cfg = config(html, "sales-trend")
      assert cfg["type"] == "line"
      assert cfg["data"]["labels"] == ["Mon", "Tue"]

      assert cfg["data"]["datasets"] == [
               %{
                 "label" => "Sales",
                 "data" => [12_400, 9_800],
                 "color" => "chart-1",
                 "fill" => "start",
                 "spanGaps" => true
               }
             ]

      assert cfg["options"]["plugins"] == %{
               "legend" => %{"display" => false},
               "tooltip" => %{"enabled" => false}
             }

      assert cfg["options"]["scales"] == %{
               "x" => %{"display" => false},
               "y" => %{"display" => false}
             }

      # no layout: the hook draws variant="trend" edge to edge, and a padding here
      # would replace its own
      assert Map.keys(cfg["options"]) == ["plugins", "scales"]

      assert {"Sales trend", ["Sales"], [{"Mon", ["12,400"]}, {"Tue", ["9,800"]}]} = table(html)
    end

    test "bare numbers are numbered; color picks the trend's token" do
      assigns = %{}

      html =
        render(
          ~H|<.number_card id="rate" label="Close rate" value="38%" trend={[31, 34]} color="chart-3" />|
        )

      cfg = config(html, "rate-trend")
      assert cfg["data"]["labels"] == ["1", "2"]
      assert [%{"color" => "chart-3"}] = cfg["data"]["datasets"]
      refute html =~ "number-card-description"
    end

    test "help: a ? beside the label, its text tied to it" do
      assigns = %{}

      html =
        render(~H"""
        <.number_card id="rate" label="Same Day rate" value="38%" help="Initial appointments sold." />
        """)

      assert html =~ ~s(class="dropdown dropdown-hover number-card-help")
      assert html =~ ~s(aria-label="About Same Day rate")
      assert html =~ ~s(aria-describedby="rate-help")

      assert html =~
               ~s(<span id="rate-help" role="tooltip" class="dropdown-content number-card-help-content">Initial appointments sold.</span>)
    end

    test "changes: a badge naming the period, then the difference and the change, toned" do
      assigns = %{}

      html =
        render(~H"""
        <.number_card id="sales" label="Sales" value="$42,000">
          3 sales
          <:change vs="vs PP" by="+$8,000" percent="+24%" direction="up" />
          <:change vs="vs PY" percent="-3%" direction="down" />
          <:change vs="vs plan" by="$0" direction="flat" />
        </.number_card>
        """)

      groups =
        html
        |> String.split(~s(<span class="number-card-change-group">), trim: true)
        |> tl()

      assert [first, second, third] = groups
      assert text(first) =~ ~r/vs PP\s*\+\$8,000\s*\+24%/
      assert length(Regex.scan(~r/data-tone="good"/, first)) == 2
      assert first =~ ~s(<span class="hero-arrow-up-mini" aria-hidden="true"></span>)
      assert second =~ ~s(data-tone="bad")
      assert second =~ "hero-arrow-down-mini"
      refute second =~ "+$"
      assert third =~ ~s(data-tone="neutral")
      refute third =~ "hero-minus-mini"
    end

    test "changes: when down is good news, down is good" do
      assigns = %{}

      html =
        render(~H"""
        <.number_card id="cost" label="Costs" value="$9,000">
          <:change vs="vs PP" percent="-5%" direction="down" good="down" />
          <:change vs="vs PY" percent="+5%" direction="up" good="none" />
        </.number_card>
        """)

      assert html =~ ~s(data-tone="good")
      assert html =~ ~s(data-tone="neutral")
      refute html =~ ~s(data-tone="bad")
    end

    test "a link: the label opens it, the whole card its target" do
      assigns = %{}

      html =
        render(~H"""
        <.number_card id="sales" label="Sales" value="$42,000" patch="/board?open=sales" help="What sold." />
        """)

      assert html =~
               ~r{<a href="/board\?open=sales" data-phx-link="patch" data-phx-link-state="push" class="number-card-link">\s*Sales\s*</a>}

      # the help is beside the link, never inside it
      refute html =~ ~r{<a [^>]*number-card-link[^>]*>(?:(?!</a>).)*number-card-help}s
    end

    test "no trend, no chart" do
      assigns = %{}
      html = render(~H|<.number_card id="avg" label="Average sale" value="$3,818" />|)
      refute html =~ "<figure"
      refute html =~ "ShadcnChart"
    end
  end

  # The text of some markup, tags dropped and spaces squeezed
  defp text(html), do: html |> String.replace(~r/<[^>]+>/, " ") |> String.replace(~r/\s+/, " ")

  describe "format_number/1" do
    test "groups digits, keeps up to two decimals, passes text through" do
      assert Chart.format_number(0) == "0"
      assert Chart.format_number(999) == "999"
      assert Chart.format_number(24_500) == "24,500"
      assert Chart.format_number(-1_234_567) == "-1,234,567"
      assert Chart.format_number(1234.5) == "1,234.5"
      assert Chart.format_number(-0.125) == "-0.13"
      assert Chart.format_number(12.0) == "12"
      assert Chart.format_number("n/a") == "n/a"
    end
  end

  describe "encode/1" do
    test "JSON for maps, lists, numbers, booleans, nil, atoms and strings" do
      json = Chart.encode(%{a: [1, 2.5, true, nil, :x], b: "q\"\\\n\t<"})
      assert JSON.decode!(json) == %{"a" => [1, 2.5, true, nil, "x"], "b" => "q\"\\\n\t<"}
    end

    test "structs with String.Chars encode as strings; others raise" do
      assert Chart.encode(~D[2026-10-28]) == ~s("2026-10-28")
      assert_raise ArgumentError, ~r/can't encode/, fn -> Chart.encode(%{t: {1, 2}}) end
      assert_raise ArgumentError, ~r/can't encode/, fn -> Chart.encode(MapSet.new([1])) end
    end
  end
end
