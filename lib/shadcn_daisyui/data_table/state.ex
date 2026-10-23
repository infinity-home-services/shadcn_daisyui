defmodule ShadcnDaisyui.DataTable.State do
  @moduledoc ~S"""
  What a `<.data_table>` is showing, as plain data: the sort, the search, the
  filters and the ticked rows.

  Sort, search and filters belong in the URL, so a view can be bookmarked and
  Back restores it: read them in `handle_params/3` with `from_params/2` and
  write them with `to_params/2` in a `push_patch/2`. The selection lives only
  on the page (it is never in the URL).

      @opts [filters: %{"status" => "any", "owner" => "any"}, sorts: ~w(number customer total)]

      def handle_params(params, _uri, socket) do
        state = State.from_params(params, @opts)
        {:noreply, assign(socket, state: state, rows: State.run(Orders.list(), state, spec()))}
      end

      def handle_event("dt:sort", %{"key" => key}, socket) do
        state = State.toggle_sort(socket.assigns.state, key)
        {:noreply, push_patch(socket, to: ~p"/orders?#{State.to_params(state, @opts)}")}
      end

      def handle_event("dt:filter", params, socket) do
        state =
          socket.assigns.state
          |> State.put_search(params["q"])
          |> State.put_filters(params, ["status", "owner"], @opts)

        state = State.parse_sort(params["sort"], state, @opts)
        {:noreply, push_patch(socket, to: ~p"/orders?#{State.to_params(state, @opts)}")}
      end

      def handle_event("dt:select", %{"id" => id} = params, socket) do
        ids = Enum.map(socket.assigns.rows, & &1.id)
        {:noreply, update(socket, :state, &State.select(&1, id, params["shift"] == true, ids))}
      end

  ## Options

    * `filters` - `%{key => default}`, every filter the table has and the
      value that means "not filtered" (`"any"`, `""` or a real default such
      as `"open"`).
    * `sorts` - the keys a column may sort by. Without it any key is
      accepted.

  ## Filter values

  A filter holds one value, or several as a comma list (`"open,paid"`).
  `"any"`, `""` and nil mean none. `values/1` splits a value, `any_of?/2`
  tests a row's value against it.

  ## Ids

  Row ids are kept as strings (what the browser sends back), so an integer
  id and its string are the same row.
  """

  defstruct sort: nil, dir: :asc, search: "", filters: %{}, selected: MapSet.new(), anchor: nil

  @type t :: %__MODULE__{
          sort: String.t() | nil,
          dir: :asc | :desc,
          search: String.t(),
          filters: %{optional(String.t()) => String.t()},
          selected: MapSet.t(String.t()),
          anchor: String.t() | nil
        }

  # ---------------------------------------------------------------------------
  # URL params
  # ---------------------------------------------------------------------------

  @doc """
  Builds the state from URL params: `q` (the search), `sort` (a key from
  `sorts`), `dir=desc`, and one param per filter (a missing or empty one is
  its default).

      iex> State.from_params(%{"q" => "pat", "sort" => "total", "dir" => "desc", "status" => "open"},
      ...>   filters: %{"status" => "any"}, sorts: ["total"])
      %State{search: "pat", sort: "total", dir: :desc, filters: %{"status" => "open"}}
  """
  @spec from_params(map() | nil, keyword() | map()) :: t()
  def from_params(params, opts \\ []) do
    params = params || %{}
    sort = params |> Map.get("sort") |> sort_key(opts)

    %__MODULE__{
      search: trim(params["q"]),
      sort: sort,
      dir: if(sort && params["dir"] == "desc", do: :desc, else: :asc),
      filters:
        Map.new(defaults(opts), fn {key, default} ->
          {key, join(params[key]) |> blank_to(default)}
        end)
    }
  end

  @doc """
  The URL params for the state, leaving out everything at its default: no
  `q` without a search, no `sort` in the default order, `dir` only for
  `desc`, and only the filters that differ from their default.

      iex> State.to_params(%State{sort: "total", dir: :desc, filters: %{"status" => "any"}},
      ...>   filters: %{"status" => "any"})
      %{"sort" => "total", "dir" => "desc"}
  """
  @spec to_params(t(), keyword() | map()) :: %{optional(String.t()) => String.t()}
  def to_params(%__MODULE__{} = state, opts \\ []) do
    defaults = defaults(opts)

    filters =
      for {key, value} <- state.filters,
          values(value) != values(Map.get(defaults, key)),
          into: %{},
          do: {key, value || ""}

    filters
    |> put_unless(state.search == "", "q", state.search)
    |> put_unless(is_nil(state.sort), "sort", state.sort)
    |> put_unless(is_nil(state.sort) or state.dir != :desc, "dir", "desc")
  end

  # ---------------------------------------------------------------------------
  # Filters and search
  # ---------------------------------------------------------------------------

  @doc """
  True when the search or any filter is off its default.
  """
  @spec filtered?(t(), keyword() | map()) :: boolean()
  def filtered?(%__MODULE__{} = state, opts \\ []) do
    state.search != "" or
      Enum.any?(defaults(opts), fn {key, default} ->
        values(Map.get(state.filters, key, default)) != values(default)
      end) or
      Enum.any?(state.filters, fn {key, value} ->
        not Map.has_key?(defaults(opts), key) and values(value) != []
      end)
  end

  @doc """
  A filter value as a list: one value, or several from a comma list.
  `"any"`, `""` and nil mean none.

      iex> State.values("open,paid")
      ["open", "paid"]

      iex> State.values("any")
      []
  """
  @spec values(term()) :: [String.t()]
  def values(nil), do: []
  def values(list) when is_list(list), do: Enum.flat_map(list, &values/1)

  def values(value) do
    value
    |> to_string()
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 in ["", "any"]))
  end

  @doc """
  True when nothing is picked in `value`, or `actual` (a row's value) is one
  of the picked values. A list `actual` (a row with several labels) matches
  when any of it does.

      iex> State.any_of?("open,paid", "paid")
      true

      iex> State.any_of?("any", "refunded")
      true
  """
  @spec any_of?(term(), term()) :: boolean()
  def any_of?(value, actual) do
    case values(value) do
      [] -> true
      picked when is_list(actual) -> Enum.any?(actual, &(to_string(&1) in picked))
      picked -> to_string(actual) in picked
    end
  end

  @doc """
  The search, trimmed. nil (the form didn't send `q`) keeps the current one.
  """
  @spec put_search(t(), String.t() | nil) :: t()
  def put_search(%__MODULE__{} = state, nil), do: state
  def put_search(%__MODULE__{} = state, text), do: %{state | search: trim(text)}

  @doc """
  Applies the filter form's params (`dt:filter` from `<.table_toolbar>`) for
  `keys`: each key the form sent becomes a comma list, or its default when
  it was cleared (a multiple select posts `""`); a key it didn't send stays
  as it is.

      iex> State.put_filters(%State{filters: %{"status" => "any"}}, %{"status" => ["open", "paid"]},
      ...>   ["status"], filters: %{"status" => "any"}).filters
      %{"status" => "open,paid"}
  """
  @spec put_filters(t(), map(), [String.t() | atom()], keyword() | map()) :: t()
  def put_filters(%__MODULE__{} = state, params, keys, opts \\ []) do
    defaults = defaults(opts)

    Enum.reduce(keys, state, fn key, acc ->
      key = to_string(key)

      case Map.fetch(params, key) do
        {:ok, value} ->
          case value |> join() |> blank_to(Map.get(defaults, key)) do
            nil -> %{acc | filters: Map.delete(acc.filters, key)}
            value -> %{acc | filters: Map.put(acc.filters, key, value)}
          end

        :error ->
          acc
      end
    end)
  end

  @doc """
  The active filters as chips for `<.table_toolbar chips>`: `{key, "A or B"}`
  for each of `fields` (in that order) that has a value, labelled from
  `options`. `options` maps a key to its choices, as `[{label, value}]`, a
  `%{value => label}` map or plain values; a value without a label shows as
  itself.

      iex> State.chips(%State{filters: %{"status" => "open,paid"}}, ["status"],
      ...>   %{"status" => [{"Open", "open"}, {"Paid", "paid"}]})
      [{"status", "Open or Paid"}]
  """
  @spec chips(t(), [String.t() | atom()], map()) :: [{String.t(), String.t()}]
  def chips(%__MODULE__{} = state, fields, options \\ %{}) do
    for field <- fields,
        key = to_string(field),
        picked = values(Map.get(state.filters, key)),
        picked != [] do
      choices = Map.get(options, key) || Map.get(options, field) || []
      {key, Enum.map_join(picked, " or ", &label(choices, &1))}
    end
  end

  # ---------------------------------------------------------------------------
  # Sorting
  # ---------------------------------------------------------------------------

  @doc """
  The sort as `"key:dir"` (what `<.table_toolbar sort>` takes), or `""` for
  the default order.
  """
  @spec sort_value(t()) :: String.t()
  def sort_value(%__MODULE__{sort: nil}), do: ""
  def sort_value(%__MODULE__{sort: sort, dir: dir}), do: "#{sort}:#{dir}"

  @doc """
  Applies a `"key:dir"` sort value (the toolbar's "Sort by" select). nil or a
  key outside `sorts` keeps the current sort; `""` goes back to the default
  order.
  """
  @spec parse_sort(String.t() | nil, t(), keyword() | map()) :: t()
  def parse_sort(nil, %__MODULE__{} = state, _opts), do: state
  def parse_sort("", %__MODULE__{} = state, _opts), do: %{state | sort: nil, dir: :asc}

  def parse_sort(value, %__MODULE__{} = state, opts) when is_binary(value) do
    {key, dir} =
      case String.split(value, ":", parts: 2) do
        [key, "desc"] -> {key, :desc}
        [key | _] -> {key, :asc}
      end

    case sort_key(key, opts) do
      nil -> state
      key -> %{state | sort: key, dir: dir}
    end
  end

  def parse_sort(_value, %__MODULE__{} = state, _opts), do: state

  @doc """
  A column header click: ascending, then descending, then back to the
  default order.
  """
  @spec toggle_sort(t(), String.t() | atom()) :: t()
  def toggle_sort(%__MODULE__{} = state, key) do
    key = to_string(key)

    case state do
      %{sort: ^key, dir: :asc} -> %{state | dir: :desc}
      %{sort: ^key} -> %{state | sort: nil, dir: :asc}
      _ -> %{state | sort: key, dir: :asc}
    end
  end

  # ---------------------------------------------------------------------------
  # In memory
  # ---------------------------------------------------------------------------

  @doc ~S"""
  Searches, filters and sorts rows in memory, for tables small enough to
  hold (a database-backed table does the same in its query). `spec` (a map
  or keyword list) gives:

    * `search: fn row -> text end` - every word typed must appear in the
      text, ignoring case.
    * `filters: %{key => fn row, value -> boolean end}` - called with the
      filter's value (one value or a comma list) when it isn't "none";
      `any_of?/2` is the usual body.
    * `sorts: %{key => fn row -> value end}` - empty values (nil, `""`, `[]`)
      always sort last, whichever the direction; dates and times compare by
      value, text ignoring case. Equal rows keep their order.

        defp spec do
          %{
            search: &"#{&1.number} #{&1.customer}",
            filters: %{"status" => &State.any_of?(&2, &1.status)},
            sorts: %{"number" => & &1.number, "placed" => & &1.placed_on}
          }
        end
  """
  @spec run([term()], t(), keyword() | map()) :: [term()]
  def run(rows, %__MODULE__{} = state, spec) do
    rows
    |> search(state.search, spec[:search])
    |> filter(state.filters, spec[:filters] || %{})
    |> sort(state, spec[:sorts] || %{})
  end

  defp search(rows, _text, nil), do: rows

  defp search(rows, text, fun) do
    case text |> String.downcase() |> String.split() do
      [] ->
        rows

      words ->
        Enum.filter(rows, fn row ->
          haystack = row |> fun.() |> to_string() |> String.downcase()
          Enum.all?(words, &String.contains?(haystack, &1))
        end)
    end
  end

  defp filter(rows, filters, funs) do
    Enum.reduce(funs, rows, fn {key, fun}, acc ->
      value = Map.get(filters, to_string(key))
      if values(value) == [], do: acc, else: Enum.filter(acc, &fun.(&1, value))
    end)
  end

  defp sort(rows, %{sort: nil}, _funs), do: rows

  defp sort(rows, %{sort: key, dir: dir}, funs) do
    case Enum.find_value(funs, fn {k, f} -> to_string(k) == key && f end) do
      nil ->
        rows

      fun ->
        {empty, present} =
          rows |> Enum.map(&{fun.(&1), &1}) |> Enum.split_with(fn {v, _} -> empty?(v) end)

        present
        |> Enum.sort(fn {a, _}, {b, _} ->
          if dir == :desc, do: compare(a, b) != :lt, else: compare(a, b) != :gt
        end)
        |> Kernel.++(empty)
        |> Enum.map(&elem(&1, 1))
    end
  end

  defp empty?(value), do: value in [nil, "", []]

  @calendar [Date, Time, DateTime, NaiveDateTime]

  defp compare(%mod{} = a, %mod{} = b) when mod in @calendar, do: mod.compare(a, b)

  defp compare(%{__struct__: mod} = a, %{__struct__: mod} = b) do
    if function_exported?(mod, :compare, 2), do: normalize(mod.compare(a, b)), else: raw(a, b)
  end

  defp compare(a, b) when is_binary(a) and is_binary(b) do
    case raw(String.downcase(a), String.downcase(b)) do
      :eq -> raw(a, b)
      order -> order
    end
  end

  defp compare(a, b), do: raw(a, b)

  # Decimal.compare/2 and friends return :lt / :eq / :gt
  defp normalize(order) when order in [:lt, :eq, :gt], do: order
  defp normalize(_), do: :eq

  defp raw(a, b) when a < b, do: :lt
  defp raw(a, b) when a > b, do: :gt
  defp raw(_, _), do: :eq

  # ---------------------------------------------------------------------------
  # Selection (only on the page, never in the URL)
  # ---------------------------------------------------------------------------

  @doc """
  True when the row with this id is ticked.
  """
  @spec selected?(t(), term()) :: boolean()
  def selected?(%__MODULE__{selected: selected}, id), do: MapSet.member?(selected, to_string(id))

  @doc """
  A row's checkbox (`dt:select`): toggles the row. With `shift?` it ticks
  every row from the anchor (the last row ticked) to this one, in the order
  shown (`visible_ids`). The row becomes the anchor.
  """
  @spec select(t(), term(), boolean(), [term()]) :: t()
  def select(%__MODULE__{} = state, id, shift? \\ false, visible_ids \\ []) do
    id = to_string(id)
    visible = Enum.map(visible_ids, &to_string/1)
    from = state.anchor && Enum.find_index(visible, &(&1 == state.anchor))
    to = Enum.find_index(visible, &(&1 == id))

    selected =
      if shift? && from && to && from != to do
        MapSet.union(
          state.selected,
          MapSet.new(Enum.slice(visible, min(from, to)..max(from, to)))
        )
      else
        if MapSet.member?(state.selected, id),
          do: MapSet.delete(state.selected, id),
          else: MapSet.put(state.selected, id)
      end

    %{state | selected: selected, anchor: id}
  end

  @doc """
  The header checkbox (`dt:select_all`): ticks every row shown, or clears
  them when they are all ticked already.
  """
  @spec select_all(t(), [term()]) :: t()
  def select_all(%__MODULE__{} = state, visible_ids) do
    visible = MapSet.new(visible_ids, &to_string/1)

    selected =
      if MapSet.size(visible) > 0 and MapSet.subset?(visible, state.selected),
        do: MapSet.difference(state.selected, visible),
        else: MapSet.union(state.selected, visible)

    %{state | selected: selected, anchor: nil}
  end

  @doc """
  Drops ticked rows that are no longer shown (after a filter or search).
  """
  @spec keep_visible(t(), [term()]) :: t()
  def keep_visible(%__MODULE__{} = state, visible_ids) do
    visible = MapSet.new(visible_ids, &to_string/1)
    anchor = if state.anchor in visible, do: state.anchor

    %{state | selected: MapSet.intersection(state.selected, visible), anchor: anchor}
  end

  @doc """
  Unticks every row (`dt:clear`).
  """
  @spec clear(t()) :: t()
  def clear(%__MODULE__{} = state), do: %{state | selected: MapSet.new(), anchor: nil}

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp defaults(opts) do
    case opts[:filters] do
      nil ->
        %{}

      filters ->
        Map.new(filters, fn {key, default} -> {to_string(key), default && join(default)} end)
    end
  end

  defp sort_key(key, opts) when is_binary(key) and key != "" do
    case opts[:sorts] do
      nil -> key
      sorts -> if key in Enum.map(sorts, &to_string/1), do: key
    end
  end

  defp sort_key(_key, _opts), do: nil

  # a param (a string or a multiple select's list) as one comma list
  defp join(nil), do: ""

  defp join(value) do
    value
    |> List.wrap()
    |> Enum.map(&(&1 |> to_string() |> String.trim()))
    |> Enum.reject(&(&1 == ""))
    |> Enum.join(",")
  end

  defp blank_to("", default), do: default
  defp blank_to(value, _default), do: value

  defp trim(nil), do: ""
  defp trim(text), do: text |> to_string() |> String.trim()

  defp put_unless(map, true, _key, _value), do: map
  defp put_unless(map, false, key, value), do: Map.put(map, key, value)

  defp label(choices, value) when is_map(choices) do
    case Enum.find(choices, fn {v, _} -> to_string(v) == value end) do
      {_, label} -> to_string(label)
      nil -> value
    end
  end

  defp label(choices, value) when is_list(choices) do
    Enum.find_value(choices, value, fn
      {label, v} -> to_string(v) == value && to_string(label)
      v -> to_string(v) == value && value
    end)
  end
end
