defmodule ShadcnDaisyuiDemoWeb.ChartsLive do
  @moduledoc """
  `/lab/charts` (not in the static export): the chart kit in a LiveView, under
  the lab's strict CSP. Number cards over a day's sales, a leaderboard whose
  bars open a sheet of that person's appointments, a progress row inside a
  LiveComponent (its clicks go to the component through `target`), and sales
  by day. "Next day" moves every number, so each chart moves to its new data
  in place. Everything is made up.
  """
  use ShadcnDaisyuiDemoWeb, :live_view

  import ShadcnDaisyui.Components,
    only: [card: 1, card_body: 1, card_title: 1, card_description: 1]

  import ShadcnDaisyui.Components.Chart
  import ShadcnDaisyui.Components.Overlay, only: [sheet: 1]

  alias ShadcnDaisyuiDemoWeb.Catalog.ChartPages

  defmodule ProgressCard do
    @moduledoc false
    # The progress row in a LiveComponent: on_click with target={@myself}
    # reaches this handle_event, which tells the LiveView what to open.
    use Phoenix.LiveComponent

    import ShadcnDaisyui.Components,
      only: [card: 1, card_body: 1, card_title: 1, card_description: 1]

    import ShadcnDaisyui.Components.Chart

    def render(assigns) do
      ~H"""
      <div>
        <.card>
          <.card_body>
            <.card_title>Today's appointments</.card_title>
            <.card_description>{@total} booked · click a part</.card_description>
            <.chart
              id="lab-progress"
              label="Today's appointments"
              on_click="open_state"
              target={@myself}
              class="mt-4"
              config={ChartPages.progress_config(@parts)}
            />
          </.card_body>
        </.card>
      </div>
      """
    end

    def update(assigns, socket) do
      total = assigns.parts |> Enum.map(&elem(&1, 2)) |> Enum.sum()
      {:ok, socket |> assign(assigns) |> assign(:total, total)}
    end

    def handle_event("open_state", %{"series" => key}, socket) do
      send(self(), {:open_state, key})
      {:noreply, socket}
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Charts", day: 0, detail: nil, clicks: [])
     |> assign_data()}
  end

  @impl true
  def handle_event("next_day", _params, socket),
    do: {:noreply, socket |> update(:day, &(&1 + 1)) |> assign_data()}

  def handle_event("open_person", %{"id" => "lab-leaderboard", "key" => key} = params, socket) do
    {_, name, sale, margin, closed, ran} = Enum.find(socket.assigns.people, &(elem(&1, 0) == key))

    detail = %{
      title: name,
      description:
        "#{ChartPages.money(sale)} · #{ChartPages.money(margin)} margin · #{closed} for #{ran}",
      rows: for(n <- 1..ran, do: appointment(key, n, n <= closed))
    }

    {:noreply, socket |> assign(detail: detail) |> log(params)}
  end

  def handle_event("close_detail", _params, socket), do: {:noreply, assign(socket, detail: nil)}

  @impl true
  def handle_info({:open_state, key}, socket) do
    {_, label, n, _} = Enum.find(socket.assigns.parts, &(elem(&1, 0) == key))

    detail = %{
      title: label,
      description: "#{n} of today's appointments",
      rows: for(i <- 1..max(n, 1)//1, n > 0, do: appointment(key, i, key == "resulted"))
    }

    {:noreply,
     socket |> assign(detail: detail) |> log(%{"id" => "lab-progress", "series" => key})}
  end

  defp log(socket, params),
    do: assign(socket, clicks: Enum.take([inspect(params) | socket.assigns.clicks], 3))

  defp appointment(key, n, sold) do
    hour = 8 + 2 * (n - 1) + rem(:erlang.phash2({key, n}), 2)

    customer =
      Enum.at(
        ~w(Harbor Maple Summit Lakeside Copper Birch Cedar),
        rem(:erlang.phash2({n, key}), 7)
      )

    %{
      time: "#{hour}:00",
      customer: "#{customer} residence",
      result: if(sold, do: "Sold", else: "No sale")
    }
  end

  # The made-up numbers for day `day`: day 0 is the docs' data, each next day
  # moves every number a little (seeded, so a day always looks the same).
  defp assign_data(socket) do
    day = socket.assigns.day
    :rand.seed(:exsss, {day, 7, 42})

    nudge = fn n ->
      if day == 0, do: n, else: max(0, round(n * (0.75 + :rand.uniform() * 0.5)))
    end

    people =
      Enum.map(ChartPages.people(), fn {key, name, sale, margin, closed, ran} ->
        moved = nudge.(sale)
        {key, name, moved, round(moved * margin / sale), closed, ran}
      end)

    sales = ChartPages.daily_sales() |> Enum.map(nudge) |> rotate(day)
    days = rotate(ChartPages.days(), day)
    parts = Enum.map(ChartPages.progress(), fn {k, l, n, c} -> {k, l, nudge.(n), c} end)

    socket
    |> assign(people: people, parts: parts, sales: sales, days: days)
    |> assign(total_sales: Enum.sum(Enum.map(people, &elem(&1, 2))))
    |> assign(total_margin: Enum.sum(Enum.map(people, &elem(&1, 3))))
  end

  defp rotate(list, 0), do: list

  defp rotate(list, n),
    do: Enum.drop(list, rem(n, length(list))) ++ Enum.take(list, rem(n, length(list)))

  @impl true
  def render(assigns) do
    ~H"""
    <main class="mx-auto max-w-5xl space-y-8 px-4 py-12 sm:px-6">
      <div class="flex flex-wrap items-end justify-between gap-4">
        <div class="space-y-1">
          <h1 class="text-3xl font-bold tracking-tight">Charts</h1>
          <p class="text-sm text-muted-foreground">
            The chart kit in a LiveView: click a bar or a part; Next day moves every chart in place.
          </p>
        </div>
        <.button id="next-day" phx-click="next_day">Next day</.button>
      </div>

      <div class="grid gap-4 sm:grid-cols-3">
        <.number_card
          id="lab-sales"
          label="Sales"
          value={ChartPages.money(@total_sales)}
          trend={Enum.zip(@days, @sales)}
        >
          Margin {ChartPages.money(@total_margin)} ({round(@total_margin * 100 / max(1, @total_sales))}%)
        </.number_card>
        <.number_card
          id="lab-appointments"
          label="Appointments"
          value={to_string(Enum.sum(Enum.map(@parts, &elem(&1, 2))))}
          trend={ChartPages.appointments_trend()}
        >
          vs. 27 last Tuesday
        </.number_card>
        <.number_card
          id="lab-close-rate"
          label="Close rate"
          value="38%"
          trend={ChartPages.close_rate_trend()}
          color="chart-3"
        >
          11 of 29 run
        </.number_card>
      </div>

      <div class="grid items-start gap-4 lg:grid-cols-2">
        <.card>
          <.card_body>
            <.card_title>Leaderboard</.card_title>
            <.card_description>Sales this week · click a person</.card_description>
            <.chart
              id="lab-leaderboard"
              label="Sales by person, this week"
              on_click="open_person"
              class="mt-4"
              format={&ChartPages.money/1}
              config={ChartPages.leaderboard_config(@people)}
            />
          </.card_body>
        </.card>
        <div class="space-y-4">
          <.live_component module={ProgressCard} id="progress-card" parts={@parts} />
          <.card>
            <.card_body>
              <.card_title>Sales by day</.card_title>
              <.card_description>Last 2 weeks</.card_description>
              <.chart
                id="lab-daily"
                label="Sales by day, last 2 weeks"
                class="mt-4"
                canvas_class="h-48"
                format={&ChartPages.money/1}
                config={ChartPages.daily_config(@days, @sales)}
              />
            </.card_body>
          </.card>
        </div>
      </div>

      <ul id="chart-clicks" class="space-y-1 font-mono text-xs text-muted-foreground">
        <li :for={c <- @clicks}>{c}</li>
      </ul>

      <.sheet id="detail" show={@detail != nil} on_close="close_detail">
        <:title>{@detail && @detail.title}</:title>
        <:description>{@detail && @detail.description}</:description>
        <ul :if={@detail} class="divide-y divide-border text-sm">
          <li :for={row <- @detail.rows} class="flex items-center justify-between gap-4 py-3">
            <span>{row.time} · {row.customer}</span>
            <span class="text-muted-foreground">{row.result}</span>
          </li>
        </ul>
      </.sheet>
    </main>
    """
  end
end
