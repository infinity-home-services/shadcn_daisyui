defmodule ShadcnDaisyuiDemoWeb.ChatLive do
  @moduledoc """
  `/lab/chat` (not in the static export): an AI chat page built from the
  package's parts in a connected LiveView, the way the usage rules lay it
  out. `<.app_shell fill>` (the lab's shell) with the page header, a
  `<.message_scroller>` over a stream of messages, and the
  `<.prompt_input>` composer.

  The assistant is made up: it answers from the lab's orders
  (`ShadcnDaisyuiDemoWeb.LabOrders`) with a fixed script per question. Each
  reply runs in `start_async/3`: the task sends the reply's steps and text
  a chunk at a time, and every message updates the reply in the stream
  (`stream_insert`), its steps a `<.trace>` (a sparkle on the running one,
  a check on the done ones) that folds into one "Worked through" row with
  the sources when it's done. Stop is `cancel_async/2`. The conversation
  opens at its last question (`default_position="last-anchor"`); "Load
  earlier messages" prepends older ones (`at: 0`); files attached in the
  composer show on the question.

  `config :shadcn_daisyui_demo, :chat_delay, %{step: ms, chunk: ms}` sets
  the pace (instant in tests).
  """
  use ShadcnDaisyuiDemoWeb, :live_view

  import ShadcnDaisyuiDemoWeb.CoreComponents, only: []
  import ShadcnDaisyui.CoreComponents, only: [page_header: 1, button: 1]
  import ShadcnDaisyui.Components.Conversation
  import ShadcnDaisyui.Components.Display, only: [attachment: 1]
  import ShadcnDaisyuiDemoWeb.LabOrders, only: [lab_shell: 1]

  alias ShadcnDaisyuiDemoWeb.LabOrders

  @page 6
  @suggestions [
    "Which orders are overdue?",
    "Who are our biggest customers?",
    "Summarize Summit Outfitters"
  ]

  @impl true
  def mount(_params, _session, socket) do
    history = history()
    {older, shown} = Enum.split(history, -@page)

    {:ok,
     socket
     |> assign(
       page_title: "Assistant",
       older: older,
       next_id: length(history) + 1,
       reply: nil,
       form: to_form(%{"text" => ""}, as: :prompt)
     )
     |> allow_upload(:files, accept: ~w(image/* .pdf .csv), max_entries: 3, auto_upload: true)
     |> stream(:messages, shown)}
  end

  # ---------------------------------------------------------------------------
  # The composer
  # ---------------------------------------------------------------------------

  @impl true
  def handle_event("validate", %{"prompt" => params}, socket),
    do: {:noreply, assign(socket, form: to_form(params, as: :prompt))}

  def handle_event("validate", _params, socket), do: {:noreply, socket}

  def handle_event("cancel-upload", %{"ref" => ref}, socket),
    do: {:noreply, cancel_upload(socket, :files, ref)}

  def handle_event("send", %{"prompt" => %{"text" => text}}, socket) do
    text = String.trim(text)
    files = attached(socket)

    if socket.assigns.reply || (text == "" and files == []) do
      {:noreply, socket}
    else
      {:noreply, ask(socket, text, files)}
    end
  end

  def handle_event("stop", _params, socket) do
    case socket.assigns.reply do
      nil ->
        {:noreply, socket}

      reply ->
        steps = Enum.reject(reply.steps, &(&1.status == "running"))

        {:noreply,
         socket
         |> cancel_async(:reply)
         |> finish(%{reply | steps: steps, status: :stopped})}
    end
  end

  # ---------------------------------------------------------------------------
  # The transcript
  # ---------------------------------------------------------------------------

  def handle_event("load-earlier", _params, socket) do
    {older, page} = Enum.split(socket.assigns.older, -@page)

    {:noreply,
     socket
     |> assign(older: older)
     |> stream(:messages, Enum.reverse(page), at: 0)}
  end

  def handle_event("new-chat", _params, socket) do
    {:noreply,
     socket
     |> cancel_async(:reply)
     |> assign(older: [], reply: nil)
     |> stream(:messages, [], reset: true)}
  end

  # A chunk of the reply from the task: a step starting or done, some text.
  # One that arrives after Stop (already in the mailbox) is dropped.
  @impl true
  def handle_info({:reply, id, event}, %{assigns: %{reply: %{id: id} = reply}} = socket) do
    reply = apply_event(reply, event)
    {:noreply, socket |> assign(reply: reply) |> stream_insert(:messages, reply)}
  end

  def handle_info({:reply, _id, _event}, socket), do: {:noreply, socket}

  @impl true
  def handle_async(:reply, {:ok, sources}, %{assigns: %{reply: %{} = reply}} = socket),
    do: {:noreply, finish(socket, %{reply | sources: sources, status: :done})}

  def handle_async(:reply, _result, socket), do: {:noreply, socket}

  # the question (an anchor) and the reply, working, then the task
  defp ask(socket, text, files) do
    id = socket.assigns.next_id
    question = %{id: id, role: :user, text: text, files: files}

    reply = %{
      id: id + 1,
      role: :assistant,
      text: "",
      steps: [],
      sources: [],
      status: :working,
      started: System.monotonic_time(:millisecond),
      seconds: nil
    }

    script = script(text)
    delay = Application.get_env(:shadcn_daisyui_demo, :chat_delay, %{step: 650, chunk: 40})
    lv = self()

    socket
    |> assign(next_id: id + 2, reply: reply, form: to_form(%{"text" => ""}, as: :prompt))
    |> stream_insert(:messages, question)
    |> stream_insert(:messages, reply)
    |> start_async(:reply, fn ->
      for event <- script.events do
        Process.sleep(if match?({:text, _}, event), do: delay.chunk, else: delay.step)
        send(lv, {:reply, reply.id, event})
      end

      script.sources
    end)
  end

  defp finish(socket, reply) do
    seconds = div(System.monotonic_time(:millisecond) - reply.started + 500, 1000)
    reply = %{reply | seconds: seconds}
    socket |> assign(reply: nil) |> stream_insert(:messages, reply)
  end

  defp apply_event(reply, {:step, text}),
    do: %{reply | steps: reply.steps ++ [%{text: text, status: "running"}]}

  defp apply_event(reply, {:step_done, text}),
    do: %{reply | steps: List.update_at(reply.steps, -1, &%{&1 | text: text, status: nil})}

  defp apply_event(reply, {:text, chunk}), do: %{reply | text: reply.text <> chunk}

  # the files done uploading go with the question; one still uploading stays
  # in the composer for the next
  defp attached(socket) do
    {done, _uploading} = uploaded_entries(socket, :files)

    for entry <- done do
      consume_uploaded_entry(socket, entry, fn _meta ->
        {:ok, %{name: entry.client_name, size: size(entry.client_size)}}
      end)
    end
  end

  defp size(bytes) when bytes >= 1_000_000, do: "#{Float.round(bytes / 1_000_000, 1)} MB"
  defp size(bytes) when bytes >= 1_000, do: "#{div(bytes, 1_000)} KB"
  defp size(bytes), do: "#{bytes} bytes"

  # ---------------------------------------------------------------------------
  # Rendering
  # ---------------------------------------------------------------------------

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :suggestions, @suggestions)

    ~H"""
    <.lab_shell active="chat" fill wide={false}>
      <.page_header crumbs={[%{label: "Lab"}, %{label: "Assistant"}]}>
        Assistant
        <:actions>
          <.button id="new-chat" size="sm" variant="outline" phx-click="new-chat">New chat</.button>
        </:actions>
      </.page_header>

      <.message_scroller
        :let={{_id, m}}
        id="chat"
        items={@streams.messages}
        anchor={fn {_id, m} -> m.role == :user end}
        busy={@reply != nil}
        default_position="last-anchor"
        label="Conversation with the assistant"
      >
        <:above :if={@older != []}>
          <div class="flex justify-center">
            <.button id="load-earlier" variant="ghost" size="sm" phx-click="load-earlier">
              Load earlier messages
            </.button>
          </div>
        </:above>
        <.chat_message message={m} />
      </.message_scroller>

      <.form for={@form} id="chat-form" phx-change="validate" phx-submit="send">
        <.prompt_input
          id="composer"
          field={@form[:text]}
          label="Ask the assistant"
          placeholder="Ask about the lab's orders…"
          busy={@reply != nil}
          on_stop="stop"
          upload={@uploads.files}
          on_cancel="cancel-upload"
        >
          <:suggestion :for={s <- @suggestions} :if={@reply == nil} value={s}>{s}</:suggestion>
        </.prompt_input>
      </.form>
    </.lab_shell>
    """
  end

  attr(:message, :map, required: true)

  defp chat_message(%{message: %{role: :user}} = assigns) do
    ~H"""
    <.message align="end">
      <.attachment :for={f <- @message.files} size="sm">
        <:media><span class="hero-document" aria-hidden="true"></span></:media>
        <:title>{f.name}</:title>
        <:description>{f.size}</:description>
      </.attachment>
      <.bubble :if={@message.text != ""}>{@message.text}</.bubble>
    </.message>
    """
  end

  defp chat_message(assigns) do
    ~H"""
    <.message>
      <:header>Assistant</:header>
      <.marker
        :if={@message.status == :working and @message.steps == [] and @message.text == ""}
        status
        shimmer
      >
        Thinking…
      </.marker>
      <.trace :if={@message.status == :working and @message.steps != []}>
        <:line
          :for={s <- @message.steps}
          status={s.status}
          icon={if s.status == "running", do: "hero-sparkles", else: "hero-check"}
        >
          {s.text}
        </:line>
      </.trace>
      <.trace :if={@message.status != :working and (@message.steps != [] or @message.sources != [])}>
        <.trace_line :if={@message.steps != []} id={"msg-#{@message.id}-steps"}>
          <:icon><span class="hero-check-circle"></span></:icon>
          Worked through {length(@message.steps)} {if length(@message.steps) == 1,
            do: "step",
            else: "steps"}
          <:description :if={@message.seconds}>{@message.seconds}s</:description>
          <:detail>
            <.trace>
              <:line :for={s <- @message.steps} icon="hero-check">{s.text}</:line>
            </.trace>
          </:detail>
        </.trace_line>
        <.trace_line :if={@message.sources != []} id={"msg-#{@message.id}-sources"}>
          <:icon><span class="hero-book-open"></span></:icon>
          Used {length(@message.sources)} {if length(@message.sources) == 1,
            do: "source",
            else: "sources"}
          <:detail>
            <.trace>
              <:line
                :for={{label, path} <- @message.sources}
                icon="hero-document-text"
                navigate={path}
              >
                {label}
              </:line>
            </.trace>
          </:detail>
        </.trace_line>
      </.trace>
      <.bubble :if={@message.text != ""} variant="ghost" content_class="whitespace-pre-line">
        {@message.text}
      </.bubble>
      <:footer :if={@message.status == :done and @message.sources != []}>
        {from(@message.sources)}
      </:footer>
      <:footer :if={@message.status == :stopped}>Stopped</:footer>
    </.message>
    """
  end

  # "From order #1240 and the orders list."
  defp from(sources) do
    names = Enum.map(sources, fn {label, _} -> String.downcase(label, :ascii) end)

    list =
      case names do
        [one] -> one
        _ -> Enum.join(Enum.drop(names, -1), ", ") <> " and " <> List.last(names)
      end

    "From " <> list <> "."
  end

  # ---------------------------------------------------------------------------
  # The made-up assistant
  # ---------------------------------------------------------------------------

  # %{events: [{:step, doing} | {:step_done, done} | {:text, chunk}], sources: [{label, path}]}
  defp script(question) do
    {steps, text, sources} = answer(String.downcase(question))

    events =
      Enum.flat_map(steps, fn {doing, done} -> [{:step, doing}, {:step_done, done}] end) ++
        (text
         |> String.split(~r/(?<=\s)/)
         |> Enum.chunk_every(3)
         |> Enum.map(&{:text, Enum.join(&1)}))

    %{events: events, sources: sources}
  end

  defp answer(q) do
    orders = LabOrders.all()

    cond do
      q =~ "overdue" ->
        overdue = Enum.filter(orders, &(&1.status == "overdue"))
        newest = Enum.take(overdue, 3)
        total = overdue |> Enum.map(& &1.total) |> Enum.sum()

        {[
           {"Searching #{length(orders)} orders", "Searched #{length(orders)} orders"},
           {"Checking the overdue invoices", "Checked #{length(overdue)} overdue invoices"}
         ],
         "#{length(overdue)} orders are overdue, #{LabOrders.money(total)} in all. The newest:\n" <>
           Enum.map_join(newest, "\n", fn o ->
             "• #{o.number}, #{o.customer}, #{LabOrders.money(o.total)} (#{o.owner})"
           end) <> "\n\nWant me to draft reminders for them?", order_sources(newest)}

      q =~ "biggest" or q =~ "customers" ->
        top =
          orders
          |> Enum.group_by(& &1.customer)
          |> Enum.map(fn {c, os} -> {c, os |> Enum.map(& &1.total) |> Enum.sum(), length(os)} end)
          |> Enum.sort_by(&elem(&1, 1), :desc)
          |> Enum.take(3)

        {[
           {"Searching #{length(orders)} orders", "Searched #{length(orders)} orders"},
           {"Adding up each customer's totals", "Added up 16 customers' totals"}
         ],
         "Your three biggest customers by total ordered:\n" <>
           Enum.map_join(top, "\n", fn {c, sum, n} ->
             "• #{c}: #{LabOrders.money(sum)} over #{n} orders"
           end), [{"The orders list", "/lab/data-table"}]}

      q =~ "summit" ->
        theirs = Enum.filter(orders, &(&1.customer == "Summit Outfitters"))
        open = Enum.count(theirs, &(&1.status in ~w(open overdue)))
        [latest | _] = theirs

        {[
           {"Finding Summit Outfitters", "Found Summit Outfitters"},
           {"Reading their #{length(theirs)} orders", "Read their #{length(theirs)} orders"}
         ],
         "Summit Outfitters has placed #{length(theirs)} orders; #{open} are still open or overdue. " <>
           "The latest is #{latest.number} for #{LabOrders.money(latest.total)}, handled by #{latest.owner}.",
         order_sources([latest]) ++ [{"The orders list", "/lab/data-table"}]}

      true ->
        {[{"Reading your question", "Read your question"}],
         "I'm a made-up assistant for the lab's orders. Ask me what's overdue, who buys the most, " <>
           "or about one customer, such as Summit Outfitters.", []}
    end
  end

  defp order_sources(orders),
    do: Enum.map(orders, &{"Order #{&1.number}", "/lab/data-table/#{&1.id}"})

  # an earlier conversation, oldest first
  defp history do
    [
      {"How many orders came in this week?",
       "14 orders came in this week, 3 more than last week. Most of them are still open."},
      {"Which ones are the largest?",
       "The largest three are #1238 for Willow Creek Farm, #1236 for Granite Works and #1233 for Lakeside Clinic."},
      {"Who handles Granite Works?", "Sam Okafor handles Granite Works."},
      {"Has Lakeside Clinic paid?",
       "Not yet. Their invoice for #1233 is open; it isn't due until next Friday."},
      {"Remind me what's still open for Pat.",
       "Pat Lee has 9 open orders. The oldest is from three weeks ago, for Copper Kettle."},
      {"Thanks. Anything I should look at first?",
       "Start with Copper Kettle's order: it's the oldest open one and the customer asked about it on Tuesday.\n\n" <>
         "After that, Riverside Dental's overdue invoice is the largest amount outstanding. " <>
         "A short reminder usually does it: they've paid within a week of one every time this year."}
    ]
    |> Enum.with_index()
    |> Enum.flat_map(fn {{q, a}, i} ->
      [
        %{id: 2 * i + 1, role: :user, text: q, files: []},
        %{
          id: 2 * i + 2,
          role: :assistant,
          text: a,
          steps: [%{text: "Searched 240 orders", status: nil}],
          sources: [{"The orders list", "/lab/data-table"}],
          status: :done,
          started: 0,
          seconds: 2
        }
      ]
    end)
  end
end
