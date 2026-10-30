defmodule ShadcnDaisyui.Components.DataTableTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.Components.DataTable
  import ShadcnDaisyui.Components, only: [select: 1]

  alias ShadcnDaisyui.DataTable.State

  defp render(template), do: template |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()

  defp count(html, substring), do: html |> String.split(substring) |> length() |> Kernel.-(1)

  @rows [%{id: 1, name: "Pat", total: 10}, %{id: 2, name: "Sam", total: 20}]

  describe "data_table/1" do
    test "a card with a scrolling body, the hook and table-fixed" do
      assigns = %{rows: @rows}

      html =
        render(~H"""
        <.data_table id="people" rows={@rows}>
          <:col :let={p} label="Name">{p.name}</:col>
        </.data_table>
        """)

      assert html =~ ~s(id="people" phx-hook="ShadcnDataTable" data-data-table)
      assert html =~ ~s(class="card data-table )
      assert html =~ ~s(<div class="data-table-scroll" data-dt-scroll>)
      assert html =~ ~s(class="table data-table-table")
      refute html =~ "data-dt-select"
      refute html =~ "data-dt-bulk"
    end

    test "rows are focusable, keyed by id, with their href; row_id picks the id" do
      assigns = %{rows: [%{key: "a", name: "Pat"}]}

      html =
        render(~H"""
        <.data_table id="t" rows={@rows} row_id={& &1.key} row_href={&"/people/#{&1.key}"}>
          <:col :let={p} label="Name">{p.name}</:col>
        </.data_table>
        """)

      assert html =~
               ~s(<tr id="t-row-a" tabindex="0" data-dt-row data-id="a" data-href="/people/a">)

      assert html =~ ~r/<td id="t-row-a-c0"[ >]/
    end

    test "sortable columns: a button that pushes dt:sort, aria-sort, the arrow" do
      assigns = %{rows: @rows, state: %State{sort: "total", dir: :desc}}

      html =
        render(~H"""
        <.data_table id="t" rows={@rows} state={@state}>
          <:col :let={p} label="Name" sort="name">{p.name}</:col>
          <:col :let={p} label="Total" sort="total">{p.total}</:col>
          <:col label="Note">-</:col>
        </.data_table>
        """)

      assert count(html, ~s(aria-sort="none")) == 1
      assert count(html, ~s(aria-sort="descending")) == 1
      assert html =~ ~s(data-sorted="desc")
      assert html =~ "hero-arrow-down"
      assert html =~ "hero-chevron-up-down"
      assert html =~ "&quot;dt:sort&quot;"
      assert html =~ "&quot;key&quot;:&quot;total&quot;"
      assert html =~ "&quot;table&quot;:&quot;t&quot;"
      # an unsortable column gets a plain label, no aria-sort
      assert html =~ ~s(<span class="data-table-label">Note</span>)
      assert count(html, "aria-sort") == 2
    end

    test "ascending shows the up arrow" do
      assigns = %{rows: @rows, state: %State{sort: "name", dir: :asc}}

      html =
        render(~H"""
        <.data_table id="t" rows={@rows} state={@state}>
          <:col :let={p} label="Name" sort="name">{p.name}</:col>
        </.data_table>
        """)

      assert html =~ ~s(aria-sort="ascending")
      assert html =~ "hero-arrow-up"
    end

    test "the rightmost column shown is right-aligned at each width; the first never is" do
      assigns = %{rows: @rows}

      html =
        render(~H"""
        <.data_table id="t" rows={@rows}>
          <:col :let={p} label="Name">{p.name}</:col>
          <:col :let={p} label="Total">{p.total}</:col>
          <:col label="Owner" hide_below="md">-</:col>
          <:col label="Updated" hide_below="xl">-</:col>
        </.data_table>
        """)

      # Total is last until md, Owner from md to xl, Updated from xl
      assert html =~ ~r/<th scope="col"[^>]* data-end="base sm">/
      assert html =~ ~r/<th scope="col"[^>]* data-hide-below="md" data-end="md lg">/
      assert html =~ ~r/<th scope="col"[^>]* data-hide-below="xl" data-end="xl">/
      assert count(html, ~s(data-end="base sm")) == 3
    end

    test "align wins: left never right-aligns, right always does" do
      assigns = %{rows: @rows}

      html =
        render(~H"""
        <.data_table id="t" rows={@rows}>
          <:col :let={p} label="Total" align="right">{p.total}</:col>
          <:col :let={p} label="Name" align="left">{p.name}</:col>
        </.data_table>
        """)

      assert html =~ ~s(data-align="right")
      assert html =~ ~s(data-align="left")
      refute html =~ "data-end"
    end

    test "a single column is never right-aligned" do
      assigns = %{rows: @rows}

      html =
        render(~H"""
        <.data_table id="t" rows={@rows}><:col :let={p} label="Name">{p.name}</:col></.data_table>
        """)

      refute html =~ "data-end"
    end

    test "selectable: the header checkbox, one per row, ticked from the state" do
      assigns = %{rows: @rows, state: %State{selected: MapSet.new(["2"])}}

      html =
        render(~H"""
        <.data_table id="t" rows={@rows} state={@state} selectable noun={{"person", "people"}}>
          <:col :let={p} label="Name">{p.name}</:col>
        </.data_table>
        """)

      assert html =~ ~s(aria-label="Select all people")
      assert html =~ "data-dt-select-all"
      assert html =~ "&quot;dt:select_all&quot;"
      # half-ticked: one of two
      assert html =~ "data-indeterminate"
      assert count(html, "data-dt-select ") + count(html, "data-dt-select>") == 2
      assert html =~ ~s(aria-labelledby="t-row-1-check t-row-1-c0")
      assert html =~ ~r/<tr id="t-row-2"[^>]* data-selected/
      assert html =~ ~r/id="t-row-2-check"[^>]* checked/
      refute html =~ ~r/id="t-row-1-check"[^>]* checked/
    end

    test "every row ticked: the header is ticked, not half" do
      assigns = %{rows: @rows, state: %State{selected: MapSet.new(["1", "2"])}}

      html =
        render(~H"""
        <.data_table id="t" rows={@rows} state={@state} selectable>
          <:col :let={p} label="Name">{p.name}</:col>
        </.data_table>
        """)

      assert html =~ ~r/data-dt-select-all/
      assert html =~ ~r/aria-label="Select all rows" checked/
      refute html =~ "data-indeterminate"
    end

    test "the bulk bar: hidden with nothing ticked" do
      assigns = %{rows: @rows}

      html =
        render(~H"""
        <.data_table id="t" rows={@rows} selectable>
          <:col :let={p} label="Name">{p.name}</:col>
        </.data_table>
        """)

      assert html =~ ~s(<div class="data-table-bulk" data-dt-bulk hidden>)
      refute html =~ "data-ticked"
    end

    test "the bulk bar: N selected, the bulk actions, Clear" do
      assigns = %{rows: @rows, state: %State{selected: MapSet.new(["1"])}}

      html =
        render(~H"""
        <.data_table id="t" rows={@rows} state={@state} selectable matching={50}>
          <:col :let={p} label="Name">{p.name}</:col>
          <:bulk><button id="archive">Archive</button></:bulk>
        </.data_table>
        """)

      assert html =~ ~s(<div class="data-table-bulk" data-dt-bulk>)
      assert html =~ "data-ticked"
      assert html =~ ~r/1 selected\s*<\/span>/

      assert html =~
               ~s(<div class="data-table-bulk-actions"><button id="archive">Archive</button></div>)

      assert html =~ "&quot;dt:clear&quot;"
      # not every loaded row is ticked: no "Select all"
      refute html =~ "data-dt-select-matching"
    end

    test "every loaded row ticked and more match: Select all M; all matching: All M selected" do
      assigns = %{rows: @rows, state: %State{selected: MapSet.new(["1", "2"])}}

      html =
        render(~H"""
        <.data_table id="t" rows={@rows} state={@state} selectable matching={50} noun={{"order", "orders"}}>
          <:col :let={p} label="Name">{p.name}</:col>
        </.data_table>
        """)

      assert html =~ ~r/Select all 50 orders/
      assert html =~ "&quot;dt:select_matching&quot;"

      html =
        render(~H"""
        <.data_table id="t" rows={@rows} state={@state} selectable matching={50} all_matching>
          <:col :let={p} label="Name">{p.name}</:col>
        </.data_table>
        """)

      assert html =~ ~r/All 50 selected/
      refute html =~ "data-dt-select-matching"
    end

    test "matching no more than loaded offers nothing" do
      assigns = %{rows: @rows, state: %State{selected: MapSet.new(["1", "2"])}}

      html =
        render(~H"""
        <.data_table id="t" rows={@rows} state={@state} selectable matching={2}>
          <:col :let={p} label="Name">{p.name}</:col>
        </.data_table>
        """)

      refute html =~ "data-dt-select-matching"
    end

    test "active_id marks the row last opened; edge, more and scroll_key mark the root" do
      assigns = %{rows: @rows}

      html =
        render(~H"""
        <.data_table id="t" rows={@rows} active_id={2} edge more scroll_key="people">
          <:col :let={p} label="Name">{p.name}</:col>
        </.data_table>
        """)

      assert html =~ ~r/<tr id="t-row-2"[^>]* data-active/
      refute html =~ ~r/<tr id="t-row-1"[^>]* data-active/
      assert html =~ ~s(data-edge data-more data-scroll-key="people")
      assert html =~ ~s(class="data-table-more" data-dt-more)
      assert html =~ "data-dt-sentinel"
    end

    test "hide_below and class land on the header and every cell" do
      assigns = %{rows: @rows}

      html =
        render(~H"""
        <.data_table id="t" rows={@rows}>
          <:col :let={p} label="Name">{p.name}</:col>
          <:col :let={p} label="Total" hide_below="lg" class="w-32">{p.total}</:col>
        </.data_table>
        """)

      assert count(html, ~s(class="w-32" data-hide-below="lg")) == 3
    end

    test "no rows: the in-table empty state, from the :empty slot" do
      assigns = %{}

      html =
        render(~H"""
        <.data_table id="t" rows={[]} selectable noun={{"order", "orders"}}>
          <:col :let={p} label="Name">{p.name}</:col>
          <:empty title="No orders match" icon="hero-funnel">Try another filter.</:empty>
          <:empty_action><button id="reset">Clear filters</button></:empty_action>
        </.data_table>
        """)

      assert html =~ ~s(<div class="data-table-empty">)
      assert html =~ ~s(data-variant="plain")
      assert html =~ "hero-funnel"
      assert html =~ "No orders match"
      assert html =~ "Try another filter."
      assert html =~ ~s(<button id="reset">Clear filters</button>)
      # nothing to tick
      assert html =~ ~r/data-dt-select-all[^>]*/
      assert html =~ ~r/aria-label="Select all orders" disabled/
    end

    test "no rows and no :empty: No {plural}" do
      assigns = %{}

      html =
        render(~H"""
        <.data_table id="t" rows={[]} noun={{"invoice", "invoices"}}>
          <:col :let={p} label="Name">{p.name}</:col>
        </.data_table>
        """)

      assert html =~ "No invoices"
      refute html =~ "empty-state-description"
    end

    test "target sends every event to a LiveComponent" do
      assigns = %{rows: @rows, state: %State{selected: MapSet.new(["1"])}}

      html =
        render(~H"""
        <.data_table id="t" rows={@rows} state={@state} selectable target="#owner">
          <:col :let={p} label="Name" sort="name">{p.name}</:col>
        </.data_table>
        """)

      assert html =~ ~s(phx-target="#owner")
      # sort, select all, clear
      assert count(html, "&quot;target&quot;:&quot;#owner&quot;") == 3
    end

    test "no inline event handlers" do
      assigns = %{rows: @rows}

      html =
        render(~H"""
        <.data_table id="t" rows={@rows} selectable><:col :let={p} label="Name" sort="n">{p.name}</:col></.data_table>
        """)

      refute html =~ ~r/\son[a-z]+=/
    end
  end

  describe "table_toolbar/1" do
    defp toolbar(assigns) do
      ~H"""
      <.table_toolbar
        id="tb"
        search={@search}
        shown={@shown}
        total={40}
        noun={{"order", "orders"}}
        views={@views}
        chips={@chips}
        sort={@sort}
        sorts={[{"Newest first", "placed:desc"}, {"Customer", "customer:asc"}]}
      >
        <:filter key="status" label="Status">
          <.select id="filter-status" name="status" multiple full_width>
            <:option value="open">Open</:option>
          </.select>
        </:filter>
        <:more><button id="export">Export</button></:more>
        <:save><button id="save-view">Save view</button></:save>
      </.table_toolbar>
      """
    end

    # what a button's phx-click pushes (JS.push's JSON)
    defp stack_push(html, id) do
      [_, json] = Regex.run(~r/id="#{id}"[^>]*?phx-click="([^"]*)"/s, html)
      [["push", %{"value" => value}]] = json |> String.replace("&quot;", "\"") |> JSON.decode!()
      value
    end

    defp tb(overrides \\ %{}) do
      %{search: "", shown: 40, views: [], chips: [], sort: ""}
      |> Map.merge(overrides)
      |> toolbar()
      |> render()
    end

    test "a form that sends dt:filter on change and submit, with the table id" do
      html = tb()

      assert html =~
               ~s(<form id="tb-form" class="table-toolbar-form" phx-change="dt:filter" phx-submit="dt:filter">)

      assert html =~ ~s(<input type="hidden" name="table" value="tb">)
    end

    test "the search is q, debounced 200ms" do
      html = tb(%{search: "pat"})
      assert html =~ ~s(name="q" value="pat")
      assert html =~ ~s(phx-debounce="200")
    end

    test "without views: N orders, or N of M while filtered" do
      assert tb() =~ ~r/40 orders\s*<\/p>/
      assert tb(%{shown: 1}) =~ ~r/1 order\s*<\/p>/
      assert tb(%{search: "pat", shown: 3}) =~ ~r/3 of 40\s*<\/p>/
      assert tb(%{chips: [{"status", "Open"}], shown: 3}) =~ ~r/3 of 40\s*<\/p>/
      refute tb() =~ "data-views"
    end

    test "views: a tab nav of patch links with counts, an edited dot, a Views menu" do
      html =
        tb(%{
          views: [
            %{key: "all", label: "All", count: 40, path: "/o", active: true},
            %{key: "mine", label: "Mine", count: 3, path: "/o?view=mine", edited: true}
          ]
        })

      assert html =~ "data-views"
      assert html =~ ~s(id="tb-views")
      assert html =~ ~s(aria-label="Views")
      assert html =~ ~s(href="/o?view=mine")
      assert html =~ ~s(data-phx-link="patch")
      assert html =~ ~s(<span class="tab-count">40</span>)
      assert html =~ ~s(class="table-toolbar-edited")
      assert html =~ "(edited)"
      refute html =~ "table-toolbar-count"
    end

    test "the Filters button counts the removable filters and opens the sheet" do
      html =
        tb(%{chips: [{"status", "Open or Paid"}, {"owner", "Pat"}, {"view", "Mine", :fixed}]})

      assert html =~ ~s(aria-controls="tb-filters")
      assert html =~ ~r/table-toolbar-filters-count">\s*2<span class="sr-only"> on/
      assert html =~ "&quot;shadcn:show-modal&quot;"
    end

    test "chips: one per filter on, removable ones push dt:unfilter, fixed ones can't be removed" do
      html = tb(%{chips: [{"status", "Open or Paid"}, {"view", "Mine", :fixed}]})

      assert html =~ ~s(<div class="reveal" data-open>)
      assert html =~ ~s(id="tb-chips")
      assert html =~ ~s(aria-label="Active filters")
      assert html =~ ~s(aria-label="Remove filter: Open or Paid")
      assert html =~ "&quot;dt:unfilter&quot;"
      assert html =~ "&quot;key&quot;:&quot;status&quot;"
      # the fixed chip has no remove button
      refute html =~ "tb-chips-chip-v-view-remove"
      # save, then Clear all (dt:reset)
      assert html =~ ~r/<button id="save-view">Save view<\/button>\s*<button[^>]*dt:reset/
    end

    test "chips: several values are a stack; the × sends key, a value's × key and value" do
      html = tb(%{chips: [{"status", [{"open", "Open"}, {"paid", "Paid"}, {"late", "Late"}]}]})

      assert html =~ ~s(id="tb-chips-chip-v-status")
      assert html =~ "data-chip-stack"
      assert html =~ ~r/data-chip-stack-name[^>]*>Open</
      assert html =~ ~r/data-chip-stack-count[^>]*>\+2</
      assert html =~ ~s(aria-label="Remove filter: Status")
      assert html =~ "Status</span>: <span data-chip-stack-values>Open, Paid, Late"
      # the stack's ×: the key alone, as today
      assert stack_push(html, "tb-chips-chip-v-status-remove") == %{
               "key" => "status",
               "table" => "tb"
             }

      # a value's ×: key and value
      assert stack_push(html, "tb-chips-chip-v-status-value-v-paid-remove") ==
               %{"key" => "status", "value" => "paid", "table" => "tb"}

      # counts as one filter
      assert html =~ ~r/table-toolbar-filters-count">\s*1<span/
    end

    test "chips: a stack is named after its filter, else its key" do
      assigns = %{}

      html =
        render(~H"""
        <.table_toolbar id="n" chips={[{"brand_id", [{1, "A"}, {2, "B"}]}, {"plan", [{"x", "X"}, {"y", "Y"}]}]}>
          <:filter key="plan" label="Plans"><span>select</span></:filter>
        </.table_toolbar>
        """)

      assert html =~ ~s(aria-label="Remove filter: Brand")
      assert html =~ ~s(aria-label="Remove filter: Plans")
      assert html =~ "Plans</span>: <span data-chip-stack-values>X, Y"
      # values can be any term
      assert stack_push(html, "n-chips-chip-v-brand_id-value-v-2-remove")["value"] == "2"
    end

    test "chips: a one-item list is a normal chip, an empty one no chip" do
      html = tb(%{chips: [{"status", [{"open", "Open"}]}, {"owner", []}]})

      refute html =~ "data-chip-stack"
      assert html =~ ~s(aria-label="Remove filter: Open")
      refute html =~ "tb-chips-chip-v-owner"

      assert stack_push(html, "tb-chips-chip-v-status-remove") == %{
               "key" => "status",
               "table" => "tb"
             }

      assert html =~ ~r/table-toolbar-filters-count">\s*1<span/
    end

    test "chips: a fixed stack can't lose the filter or a value" do
      html =
        tb(%{chips: [{"view", [{"a", "A"}, {"b", "B"}], :fixed}, {"one", [{"c", "C"}], :fixed}]})

      assert html =~ "data-chip-stack"
      assert html =~ ~s(id="tb-chips-chip-v-view-value-v-a-label")
      refute html =~ "tb-chips-chip-v-view-remove"
      refute html =~ "tb-chips-chip-v-view-value-v-a-remove"
      refute html =~ "tb-chips-copy-v-view-v-a-remove"
      refute html =~ "tb-chips-chip-v-one-remove"
      refute html =~ "table-toolbar-filters-count"
    end

    test "no filters on: the chips row is closed but rendered, no Clear all in it" do
      html = tb()
      assert html =~ ~s(<div class="reveal">)
      assert html =~ ~s(id="tb-chips")
      refute html =~ ~r/<div id="tb-chips-actions"[^>]*>(?:(?!<\/div>).)*Clear all/s
      refute html =~ "table-toolbar-filters-count"
    end

    test "only fixed chips: no Clear all, no count" do
      html = tb(%{chips: [{"view", "Mine", :fixed}]})
      refute html =~ "table-toolbar-filters-count"

      refute html =~
               ~r/<div id="tb-chips-actions"[^>]*>\s*<button id="save-view">Save view<\/button>\s*<button/
    end

    test "the sheet: each filter under its label, Sort by, Clear all and Show N orders" do
      html = tb(%{shown: 12})

      assert html =~ ~s(<dialog id="tb-filters" class="sheet ")
      assert html =~ ~s(<label class="table-toolbar-field" data-filter="status">)
      assert html =~ ~s(<span class="table-toolbar-field-label">Status</span>)
      assert html =~ ~s(<label class="table-toolbar-field table-toolbar-sort">)
      assert html =~ ~s(name="sort")
      assert html =~ ~r/Show 12 orders/
      assert html =~ "&quot;shadcn:hide-modal&quot;"
    end

    test "Sort by: the default order is chosen and posts empty" do
      html = tb(%{sort: ""})
      assert html =~ ~s(<input type="hidden" name="sort" value="" data-select-input>)
      assert html =~ ~r/data-value="" data-selected/
      refute html =~ "As the table is sorted"

      # the default named explicitly is the default too
      html = tb(%{sort: "placed:desc"})
      assert html =~ ~r/data-value="" data-selected/
    end

    test "Sort by: a listed sort is chosen; another adds As the table is sorted" do
      html = tb(%{sort: "customer:asc"})
      assert html =~ ~r/data-value="customer:asc" data-selected/
      refute html =~ "As the table is sorted"

      html = tb(%{sort: "total:desc"})
      assert html =~ "As the table is sorted"
      assert html =~ ~r/data-value="total:desc" data-selected/
      assert html =~ ~s(<input type="hidden" name="sort" value="total:desc" data-select-input>)
    end

    test "more is in the row" do
      assert tb() =~ ~s(<div class="table-toolbar-more"><button id="export">Export</button></div>)
    end

    test "target goes on the form and every pushed event" do
      assigns = %{}

      html =
        render(~H"""
        <.table_toolbar id="tb" target="#owner" chips={[{"a", "A"}]}>
          <:filter key="a" label="A">x</:filter>
        </.table_toolbar>
        """)

      assert html =~ ~s(phx-target="#owner")
      assert html =~ "&quot;target&quot;:&quot;#owner&quot;"
    end

    test "no filters and no sorts: no Filters button and no sheet" do
      assigns = %{}
      html = render(~H|<.table_toolbar id="tb" shown={2} />|)

      refute html =~ "table-toolbar-filters"
      refute html =~ "<dialog"
    end
  end
end
