defmodule ShadcnDaisyuiDemoWeb.CommandSearchLive do
  @moduledoc """
  `/lab/command-search` (not in the static export): `<.command on_search>` in a
  connected LiveView. A LiveComponent owns the palette (`phx-target={@myself}`)
  and searches a made-up directory on the server, 400ms per search so the busy
  state shows. Only the latest search's answer lands (`start_async/3` drops
  the older ones), and it echoes the text it answers as `query`.

  Each result is one action, by where the person stands with the team: Add,
  Add back (confirms first), Open (a patch to their row) or, while their
  removal is scheduled, nothing (disabled).
  """
  use ShadcnDaisyuiDemoWeb, :live_view

  import ShadcnDaisyui.Components.Overlay, only: [show_modal: 1]
  import ShadcnDaisyui.Components.Display, only: [push_toast: 3]

  alias __MODULE__.PersonSearch

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Server search",
       members: %{"2" => :active, "4" => :removed, "6" => :removal_scheduled}
     )}
  end

  @impl true
  def handle_params(params, _uri, socket),
    do: {:noreply, assign(socket, opened: params["person"])}

  @impl true
  def handle_info({:added, id}, socket) do
    {name, _email} = PersonSearch.person(id)
    back? = socket.assigns.members[id] == :removed

    {:noreply,
     socket
     |> update(:members, &Map.put(&1, id, :active))
     |> push_toast(if(back?, do: "#{name} is back", else: "#{name} is in the team"),
       type: :success
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="mx-auto max-w-2xl space-y-6 px-4 py-12 sm:px-6">
      <div class="space-y-1">
        <h1 class="text-3xl font-bold tracking-tight">Server search</h1>
        <p class="text-sm text-muted-foreground">
          The palette's search runs on the server, 400ms a search, so the busy state shows.
        </p>
      </div>

      <button
        id="add-person"
        type="button"
        class="btn btn-primary btn-sm"
        phx-click={show_modal("find-person")}
      >
        <span class="hero-plus size-4" aria-hidden="true"></span> Add person
      </button>

      <.live_component module={PersonSearch} id="person-search" members={@members} />

      <div class="card w-full overflow-hidden">
        <table id="members" class="table">
          <thead>
            <tr>
              <th>Name</th>
              <th class="text-right">Status</th>
            </tr>
          </thead>
          <tbody>
            <tr
              :for={
                {id, status} <- Enum.sort_by(@members, &elem(PersonSearch.person(elem(&1, 0)), 0))
              }
              id={"member-" <> id}
              class={@opened == id && "bg-accent"}
            >
              <td>{elem(PersonSearch.person(id), 0)}</td>
              <td class="text-right">
                <span class={["badge", status != :active && "badge-outline"]}>
                  {status_label(status)}
                </span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </main>
    """
  end

  defp status_label(:active), do: "Active"
  defp status_label(:removed), do: "Removed"
  defp status_label(:removal_scheduled), do: "Removal scheduled"

  defmodule PersonSearch do
    @moduledoc false
    # The palette and its search. A made-up directory stands in for a remote
    # one; `members` (from the page) says what each result offers.
    use ShadcnDaisyuiDemoWeb, :live_component

    import ShadcnDaisyui.Components.Overlay, only: [command: 1]

    @delay 400

    @directory %{
      "1" => {"Pat Rivera", "pat.rivera@example.test"},
      "2" => {"Jordan Lee", "jordan.lee@example.test"},
      "3" => {"Sam Okafor", "sam.okafor@example.test"},
      "4" => {"Alex Morgan", "alex.morgan@example.test"},
      "5" => {"Casey Nguyen", "casey.nguyen@example.test"},
      "6" => {"Riley Chen", "riley.chen@example.test"},
      "7" => {"Morgan Patel", "morgan.patel@example.test"},
      "8" => {"Taylor Brooks", "taylor.brooks@example.test"},
      "9" => {"Jamie Ortiz", "jamie.ortiz@example.test"},
      "10" => {"Drew Santos", "drew.santos@example.test"},
      "11" => {"Robin Park", "robin.park@example.test"},
      "12" => {"Patricia Hale", "patricia.hale@example.test"}
    }

    @doc false
    def person(id), do: Map.fetch!(@directory, id)

    @impl true
    def mount(socket), do: {:ok, assign(socket, query: nil, pending: nil, results: [])}

    @impl true
    def handle_event("search", %{"query" => query}, socket) do
      socket = assign(socket, pending: query)

      if query == "" do
        # opening the palette: drop the last results at once
        {:noreply, assign(socket, query: "", results: [])}
      else
        {:noreply,
         start_async(socket, :search, fn ->
           Process.sleep(@delay)
           {query, search(query)}
         end)}
      end
    end

    def handle_event("add", %{"id" => id}, socket) do
      if Map.has_key?(@directory, id) and socket.assigns.members[id] in [nil, :removed] do
        send(self(), {:added, id})
      end

      {:noreply, socket}
    end

    # Only the answer to the latest text lands (an empty search may have
    # answered since this one started)
    @impl true
    def handle_async(:search, {:ok, {query, results}}, socket) do
      if query == socket.assigns.pending,
        do: {:noreply, assign(socket, query: query, results: results)},
        else: {:noreply, socket}
    end

    def handle_async(:search, {:exit, _reason}, socket),
      do: {:noreply, assign(socket, query: socket.assigns.pending, results: [])}

    # Names and emails starting with each typed word, by name
    defp search(query) do
      words = query |> String.downcase() |> String.split()

      for {id, {name, email}} <- @directory,
          haystack = [email | String.split(String.downcase(name))],
          Enum.all?(words, fn word -> Enum.any?(haystack, &String.starts_with?(&1, word)) end) do
        %{id: id, name: name, email: email}
      end
      |> Enum.sort_by(& &1.name)
    end

    @impl true
    def render(assigns) do
      ~H"""
      <div>
        <.command
          id="find-person"
          label="Add person"
          placeholder="Name or email"
          shortcut={nil}
          on_search="search"
          query={@query}
          phx-target={@myself}
        >
          <:hint>Type a name or email.</:hint>
          <:empty>No one matches "{@query}".</:empty>
          <:item
            :for={person <- @results}
            id={"person-" <> person.id}
            icon="hero-user"
            description={person.email}
            {action(person, @members[person.id])}
          >
            {person.name}
          </:item>
        </.command>
      </div>
      """
    end

    # What a result does, by where they stand with the team
    defp action(person, nil),
      do: ["phx-click": "add", values: %{id: person.id}, shortcut: "Add"]

    defp action(person, :removed) do
      [
        "phx-click": "add",
        values: %{id: person.id},
        shortcut: "Add back",
        confirm: "Add #{person.name} back? They start with no roles."
      ]
    end

    defp action(person, :active),
      do: [patch: ~p"/lab/command-search?person=#{person.id}", shortcut: "Open"]

    defp action(_person, :removal_scheduled),
      do: [disabled: true, shortcut: "Removal scheduled"]
  end
end
