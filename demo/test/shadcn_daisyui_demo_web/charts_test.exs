defmodule ShadcnDaisyuiDemoWeb.ChartsTest do
  @moduledoc """
  The chart kit on the docs site: the Chart and Number Card gallery pages
  render every example from the real components (in the Data display group),
  and `/lab/charts` takes clicks on the server - a leaderboard bar opens a
  sheet, a progress part reaches its LiveComponent through `target` - and
  moves every chart to the next day's data.
  """
  use ShadcnDaisyuiDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias ShadcnDaisyuiDemoWeb.Catalog

  test "the Chart page shows every example, rendered from the component", %{conn: conn} do
    html = conn |> get(~p"/docs/components/chart") |> html_response(200)

    for title <- [
          "Bars by day",
          "Leaderboard",
          "Progress row",
          "Progress row, counts on the parts",
          "Lines: one series in colour",
          "Any Chart.js type",
          "Light and dark"
        ] do
      assert html =~ ~r{>\s*#{title}\s*</h[23]>}, "missing example #{title}"
    end

    assert html =~ ~s(<figure id="sales-by-day" class="chart mt-4" data-slot="chart")
    assert html =~ ~s(id="leaderboard" class="chart mt-4" data-slot="chart")
    assert html =~ ~s(data-on-click="open_person")
    assert html =~ "endLabels"
    assert html =~ ~s(id="week-progress" class="chart mt-4" data-slot="chart")
    assert html =~ "segmentLabels"
    assert html =~ ~s(data-theme="shadcn-dark")
    # the numbers, for screen readers
    assert html =~ "<caption>Sales by day, last 2 weeks</caption>"
    # no hand-drawn chart left
    refute html =~ ~s(class="chart-bar)
    # the page points at the chart kit's own entry
    assert html =~ "Requires the chart kit"
    # the previews carry no LiveView-only wiring
    refute html =~ ~s(phx-hook="ShadcnChart")
  end

  test "the Number Card page shows the cards with their trends", %{conn: conn} do
    html = conn |> get(~p"/docs/components/number-card") |> html_response(200)

    assert html =~ ~s(data-slot="number-card")
    assert html =~ ~s(<p class="number-card-value">$42,000</p>)
    assert html =~ ~s(id="sales-trend" class="chart number-card-trend")
    assert html =~ "<caption>Sales trend</caption>"
    assert html =~ "<caption>New branch sales trend</caption>"
  end

  test "both pages are in Data display, with specs and accessibility" do
    group = Enum.find(Catalog.groups(), &(&1.title == "Data display"))
    slugs = Enum.map(group.components, & &1.slug)
    assert "chart" in slugs
    assert "number-card" in slugs

    for slug <- ~w(chart number-card) do
      spec = Catalog.component(slug)
      assert spec.hook
      assert spec.specs.anatomy != []
      assert spec.accessibility.screen_reader =~ "table"
    end
  end

  describe "/lab/charts" do
    test "renders the cards and the charts with their hooks", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/lab/charts")

      for id <- ~w(lab-leaderboard lab-progress lab-daily lab-sales-trend) do
        assert has_element?(view, "##{id}[phx-hook=ShadcnChart]")
      end

      assert has_element?(view, "#lab-leaderboard[data-on-click=open_person]")
      assert has_element?(view, "#lab-progress[data-on-click=open_state][phx-target]")
      assert has_element?(view, "#lab-leaderboard-canvas[phx-update=ignore]")
      # the table's numbers through format
      assert has_element?(view, "#lab-daily [data-slot=chart-table] td", "$18,400")
    end

    test "a leaderboard click opens the sheet of that person's appointments", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/lab/charts")

      render_hook(view, "open_person", %{
        "id" => "lab-leaderboard",
        "key" => "pat",
        "series" => "margin",
        "index" => 0
      })

      assert has_element?(view, "#detail[data-show]")
      assert has_element?(view, "#detail", "Pat Lee")
      assert has_element?(view, "#detail", "$24,500 · $9,310 margin · 2 for 3")
      assert view |> element("#detail ul") |> render() |> String.split("<li") |> length() == 4
      assert has_element?(view, "#chart-clicks", ~s("key" => "pat"))
    end

    test "a progress part reaches its LiveComponent through target", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/lab/charts")

      view
      |> element("#lab-progress")
      |> render_hook("open_state", %{
        "id" => "lab-progress",
        "key" => "x",
        "series" => "needs_result"
      })

      assert has_element?(view, "#detail[data-show]")
      assert has_element?(view, "#detail", "Needs a result")
      assert has_element?(view, "#detail", "3 of today's appointments")
    end

    test "Next day moves the data; the charts stay the same elements", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/lab/charts")

      config = fn ->
        view
        |> element("#lab-daily")
        |> render()
        |> then(&Regex.run(~r/data-config="([^"]*)"/, &1))
      end

      before = config.()

      view |> element("#next-day") |> render_click()

      refute config.() == before
      assert has_element?(view, "#lab-daily-canvas canvas")
      refute has_element?(view, "#lab-sales .number-card-value", "$96,100")
    end
  end
end
