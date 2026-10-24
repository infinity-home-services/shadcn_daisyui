defmodule ShadcnDaisyuiDemoWeb.Catalog.DataPages do
  @moduledoc """
  Catalog pages for the list-page and record-page parts: `<.data_table>`,
  `<.table_toolbar>`, `<.empty>`, `<.record_tabs>`, `<.table_card>`,
  `<.section_nav>` and `<.time_field>`, plus `<.dropzone>` (a form's file
  upload). Their design metadata (specs, accessibility, SwiftUI) is inline
  here.

  Unlike the hand-written catalog entries, each example's `code` is rendered
  from the real component at runtime (`~H` + `Phoenix.HTML.Safe`), then the
  LiveView-only `phx-hook` / `phx-mounted` attributes (and dev-only HEEx
  debug annotations) are stripped and the markup re-indented. So the code tab
  is always the markup the component renders today, as a plain-HTML recipe
  that works with `initShadcnDaisyui()`. Everything renders from fixed,
  made-up data, so the static export is the same on every build.

  The rendered pages are built once per code version (see `all/0`): the
  sidebar asks for the whole catalog on every docs page.
  """
  use Phoenix.Component

  import ShadcnDaisyui.Components,
    only: [
      badge: 1,
      card: 1,
      card_body: 1,
      card_title: 1,
      card_description: 1,
      select: 1,
      combobox: 1
    ]

  import ShadcnDaisyui.Components.DataTable
  import ShadcnDaisyui.Components.Record
  import ShadcnDaisyui.Components.Display, only: [empty: 1]
  import ShadcnDaisyui.Components.Overlay, only: [dialog: 1, show_modal: 1, hide_modal: 1]
  import ShadcnDaisyui.CoreComponents, only: [button: 1, table: 1]
  import ShadcnDaisyui.FormComponents, only: [dropzone: 1]

  alias ShadcnDaisyui.DataTable.State

  # Modules whose markup the examples render: a change to any of them (or to
  # this module) rebuilds the pages.
  @sources [
    __MODULE__,
    ShadcnDaisyui.Components,
    ShadcnDaisyui.Components.DataTable,
    ShadcnDaisyui.Components.Record,
    ShadcnDaisyui.Components.Display,
    ShadcnDaisyui.Components.Overlay,
    ShadcnDaisyui.Components.Navigation,
    ShadcnDaisyui.CoreComponents,
    ShadcnDaisyui.FormComponents
  ]

  @doc """
  The eight pages. Rendering every example takes a few milliseconds and the
  docs sidebar builds the whole catalog on every request, so the result is
  kept in `:persistent_term`, keyed by the rendering modules' checksums (an
  edit to a component in dev shows on the next request).
  """
  def all do
    key = {__MODULE__, Enum.map(@sources, & &1.module_info(:md5))}

    case :persistent_term.get(key, nil) do
      nil ->
        pages = build()
        :persistent_term.put(key, pages)
        pages

      pages ->
        pages
    end
  end

  defp build do
    [
      data_table(),
      table_toolbar(),
      empty(),
      record_tabs(),
      table_card(),
      section_nav(),
      time_field(),
      dropzone()
    ]
  end

  # ---------------------------------------------------------------------------
  # Fixed, made-up data
  # ---------------------------------------------------------------------------

  @orders [
    %{
      id: 1042,
      number: "#1042",
      customer: "Blue Harbor Inn",
      owner: "Pat Lee",
      status: "paid",
      placed: "Oct 21, 2026",
      total: "$1,240.00"
    },
    %{
      id: 1041,
      number: "#1041",
      customer: "Maple & Co.",
      owner: "Sam Okafor",
      status: "open",
      placed: "Oct 20, 2026",
      total: "$318.50"
    },
    %{
      id: 1040,
      number: "#1040",
      customer: "Summit Outfitters",
      owner: "Jordan Diaz",
      status: "overdue",
      placed: "Oct 18, 2026",
      total: "$2,075.00"
    },
    %{
      id: 1039,
      number: "#1039",
      customer: "Lakeside Clinic",
      owner: "Riley Chen",
      status: "paid",
      placed: "Oct 17, 2026",
      total: "$96.40"
    },
    %{
      id: 1038,
      number: "#1038",
      customer: "Copper Kettle",
      owner: "Pat Lee",
      status: "open",
      placed: "Oct 15, 2026",
      total: "$742.10"
    },
    %{
      id: 1037,
      number: "#1037",
      customer: "Granite Works",
      owner: "Sam Okafor",
      status: "refunded",
      placed: "Oct 14, 2026",
      total: "$1,180.00"
    },
    %{
      id: 1036,
      number: "#1036",
      customer: "Orchard Lane Grocers",
      owner: "Jordan Diaz",
      status: "paid",
      placed: "Oct 12, 2026",
      total: "$455.25"
    },
    %{
      id: 1035,
      number: "#1035",
      customer: "Pine Street Bakery",
      owner: "Riley Chen",
      status: "paid",
      placed: "Oct 11, 2026",
      total: "$63.00"
    },
    %{
      id: 1034,
      number: "#1034",
      customer: "Riverside Dental",
      owner: "Pat Lee",
      status: "overdue",
      placed: "Oct 9, 2026",
      total: "$1,512.80"
    },
    %{
      id: 1033,
      number: "#1033",
      customer: "Hillcrest Motors",
      owner: "Sam Okafor",
      status: "open",
      placed: "Oct 8, 2026",
      total: "$889.90"
    }
  ]

  @statuses [{"Open", "open"}, {"Paid", "paid"}, {"Overdue", "overdue"}, {"Refunded", "refunded"}]
  @owners ["Pat Lee", "Sam Okafor", "Jordan Diaz", "Riley Chen"]

  @order_sorts [
    {"Newest first", "placed:desc"},
    {"Oldest first", "placed:asc"},
    {"Customer A–Z", "customer:asc"},
    {"Largest total", "total:desc"}
  ]

  # {id, label, group, what goes there}
  @sections [
    {"customer", "Name", "Customer", "Who the order is for."},
    {"contact", "Contact", "Customer", "Email and phone for questions about the order."},
    {"billing-address", "Billing address", "Addresses", "Where the invoice goes."},
    {"shipping-address", "Shipping address", "Addresses",
     "Leave empty to ship to the billing address."},
    {"items", "Items", "Order", "What's on the order."},
    {"discounts", "Discounts", "Order", "Codes and manual discounts."},
    {"taxes", "Taxes", "Order", "Tax rates and exemptions."},
    {"delivery-window", "Delivery window", "Delivery",
     "When someone is there to take the delivery."},
    {"instructions", "Instructions", "Delivery", "Gate codes, loading dock, who to ask for."},
    {"payment", "Payment", "Billing", "How the customer pays."},
    {"invoice", "Invoice", "Billing", "Payment terms and the invoice number."},
    {"notes", "Notes", "Other", "Anything the team should know."}
  ]

  defp status_label(status),
    do: Enum.find_value(@statuses, status, fn {l, v} -> v == status && l end)

  defp status_variant("paid"), do: "secondary"
  defp status_variant("overdue"), do: "destructive"
  defp status_variant(_), do: "outline"

  # the sections with their ids prefixed (two examples share a page)
  defp sections(prefix), do: Enum.map(@sections, fn {id, l, g, d} -> {prefix <> id, l, g, d} end)
  defp nav_sections(prefix), do: Enum.map(sections(prefix), fn {id, l, g, _} -> {id, l, g} end)

  # ---------------------------------------------------------------------------
  # Rendering: the component's markup as a plain-HTML recipe
  # ---------------------------------------------------------------------------

  @void ~w(area base br col embed hr img input link meta source track wbr)

  # (public for Catalog.ChatPages)
  @doc false
  def code(rendered) do
    html =
      rendered
      |> Phoenix.HTML.Safe.to_iodata()
      |> IO.iodata_to_binary()
      # dev-only HEEx debug annotations (`<!-- <Mod.fun> file:line -->`,
      # `<!-- @caller … -->`); our own comments stay
      |> String.replace(~r/<!-- (?:@caller |<\/?)[^\n]*? -->/, "")
      |> String.replace(~r/ (?:phx-hook|phx-mounted|data-phx-loc)="[^"]*"/, "")

    ~r/ class="([^"]*)"/
    |> Regex.replace(html, fn _, value ->
      case String.split(value) do
        [] -> ""
        parts -> ~s( class="#{Enum.join(parts, " ")}")
      end
    end)
    # sibling block tags rendered back to back by a `:for` get their own lines
    # (whitespace between table cells, list items and flex children doesn't render)
    |> String.replace(
      ~r/(<\/(?:tr|td|th|li|div|a|button|label|section|nav|p|ul)>)(<(?:tr|td|th|li|div|a|button|label|section|nav|p|ul|input|form|dialog)\b)/,
      "\\1\n\\2"
    )
    |> reindent()
  end

  # Re-indent by tag depth. Only whitespace next to a newline changes, which
  # renders the same (none of these components holds a <pre> or <textarea>).
  defp reindent(html) do
    html
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map_reduce(0, fn line, depth ->
      leading = if String.starts_with?(line, "</"), do: 1, else: 0
      indent = String.duplicate("  ", max(depth - leading, 0))
      closes = length(Regex.scan(~r/<\/[a-zA-Z][a-zA-Z0-9-]*\s*>/, line))
      {indent <> line, max(depth + opens(line) - closes, 0)}
    end)
    |> elem(0)
    |> Enum.join("\n")
    |> Kernel.<>("\n")
  end

  defp opens(line) do
    ~r/<([a-zA-Z][a-zA-Z0-9-]*)\b[^>]*>/
    |> Regex.scan(line)
    |> Enum.count(fn [tag, name] ->
      String.downcase(name) not in @void and not String.ends_with?(tag, "/>")
    end)
  end

  # ---------------------------------------------------------------------------
  # Data table
  # ---------------------------------------------------------------------------

  defp data_table do
    %{
      slug: "data-table",
      title: "Data Table",
      description:
        "A list page's table: the body scrolls under a header that stays put, columns sort, rows open the record, and ticked rows get a bulk bar.",
      hook: true,
      guidance: %{
        use_when: [
          "A list page where the table is the page: orders, customers, invoices",
          "Rows that open a record, with sorting, search and filters kept in the URL",
          "Bulk actions on ticked rows (mark paid, export, assign)"
        ],
        avoid_when: [
          "A handful of static rows - use <.table>, or <.table scroll> for a long one",
          "A record's own rows (activity, line items) - use <.table_card>",
          "Rows people edit in place - open the record instead"
        ],
        sizing:
          "A card that fills the space left: a 40px sticky header, text-sm rows with 10px vertical padding, a 44px checkbox column. table-fixed: give columns a width class (w-24, w-32) and let one column take the rest; cells truncate with …. The bulk bar is the header's height and covers the column labels, so rows never move.",
        responsive:
          "Hide columns with hide_below (sm 40rem, md 48rem, lg 64rem, xl 80rem); the rightmost column shown is right-aligned at every width. Ticking is a desktop job: the checkbox column and bulk bar show from md. edge puts the table edge to edge on phones. Never scroll sideways.",
        ios:
          "Table with selection and sortOrder on iPad / Mac; on iPhone a List of rows with NavigationLink, EditButton for selection and .searchable above it."
      },
      props: [
        %{name: "id", type: "string (required)", default: "-"},
        %{name: "rows", type: "list (required)", default: "-"},
        %{name: "row_id", type: "fn row -> id", default: "row.id"},
        %{
          name: "row_href",
          type: "fn row -> path",
          default: "nil (Cmd/Ctrl-click, middle click)"
        },
        %{
          name: "state",
          type: "ShadcnDaisyui.DataTable.State",
          default: "nil (sort + ticked rows)"
        },
        %{name: "selectable", type: "boolean", default: "false"},
        %{name: "more", type: "boolean", default: "false (sends dt:more near the end)"},
        %{name: "matching / all_matching", type: "integer / boolean", default: "nil / false"},
        %{name: "noun", type: "{singular, plural}", default: ~s({"row", "rows"})},
        %{name: "active_id", type: "any", default: "nil (the row last opened)"},
        %{name: "scroll_key", type: "string", default: "nil"},
        %{name: "edge", type: "boolean", default: "false"},
        %{name: "target", type: "phx-target", default: "nil"},
        %{name: ":col label sort class align hide_below", type: "slot", default: "-"},
        %{name: ":bulk", type: "slot (size=\"sm\" buttons)", default: "-"},
        %{name: ":empty title icon / :empty_action", type: "slots", default: ~s("No rows")}
      ],
      notes: ~S"""
      Server-driven: each action sends an event and the LiveView answers with new assigns; the ShadcnDataTable hook only keeps checkboxes, scroll position and loading in step. On this static page only the client-side parts run (the sticky header, row focus and keys, ticking a checkbox); the full list page runs on the dev server (`/lab/data-table`).

      Events (each payload also carries "table" => the component's id): dt:sort %{"key"} from a sortable header; dt:open %{"id"} from a row (click or Enter); dt:select %{"id", "shift"} from a row's checkbox; dt:select_all from the header checkbox; dt:select_matching from "Select all M rows"; dt:clear from Clear; dt:more when the end comes within ~200px (with more, once until the reply).

      State: keep sort, search and filters in a ShadcnDaisyui.DataTable.State - State.from_params/2 in handle_params, State.toggle_sort/2 on dt:sort, State.select/4, select_all/2, keep_visible/2 and clear/1 for the ticks, State.run/3 to search, filter and sort in memory, State.to_params/2 for push_patch. Ticks live on the page, never in the URL.

      Scrolling: a new sort, search or filter starts the body at the top; scroll_key keeps the body's scroll position in sessionStorage, so coming back to the list lands where the person left off; active_id highlights the row last opened and scrolls it into view. edge: on phones the table runs edge to edge (no side borders or rounding).

      Alignment: the rightmost column shown at each width is right-aligned, header and cells, unless align="left"; the first column never is.

      Layout: put the toolbar and table in an <.app_shell fill> page (or any flex column that fills the window) so the table takes the space left and only its body scrolls. These previews use a fixed-height flex column instead.
      """,
      specs: %{
        anatomy: [
          %{
            part: "Card",
            description:
              ".card.data-table: a flex column that takes the space left in its parent (flex-1, min-h-0)."
          },
          %{
            part: "Body",
            description: ".data-table-scroll: the one scroll region, vertical only."
          },
          %{
            part: "Header",
            description:
              "Sticky th cells on the card fill with an inset 1px line. A sortable column is a button with an arrow (shown on hover/focus, solid when sorted) and aria-sort."
          },
          %{
            part: "Checkbox column",
            description: "With selectable, from md: the header box ticks every loaded row."
          },
          %{
            part: "Row",
            description:
              "Focusable, opens the record. Hover tint, ticked rows bg-muted, the row last opened bg-accent with a 2px primary mark at its start."
          },
          %{
            part: "Bulk bar",
            description:
              "While rows are ticked it covers the column labels: N selected, Select all M rows, :bulk, Clear."
          },
          %{
            part: "Empty",
            description: "No rows: <.empty variant=\"plain\"> under the header, not as a row."
          },
          %{part: "Loading", description: "With more: a spinner row and the sentinel above it."}
        ],
        measurements: [
          %{property: "Header height", value: "2.5rem / 40px, sticky, z-10"},
          %{property: "Cells", value: "text-sm, 1rem inline / 0.625rem block padding, truncate"},
          %{property: "Checkbox column", value: "2.75rem / 44px (from 48rem)"},
          %{
            property: "Bulk bar",
            value: "the header's height, from the checkbox column to the end"
          },
          %{
            property: "Sort arrow",
            value: "0.875rem, outside the label (before it on end-aligned columns)"
          },
          %{property: "Active row mark", value: "2px var(--primary) inset at the row's start"},
          %{property: "Load-more sentinel", value: "12.5rem / 200px above the spinner"}
        ],
        tokens: [
          "card",
          "card-foreground",
          "border-color",
          "muted",
          "muted-foreground",
          "accent",
          "primary",
          "foreground",
          "ring"
        ]
      },
      accessibility: %{
        roles:
          "A real <table> (thead / tbody / th scope=col). Sortable headers hold a button and carry aria-sort (ascending, descending, none). Row checkboxes are labelled \"Select\" plus the row's first cell; the header box is \"Select all orders\". The bulk count is aria-live=polite.",
        keyboard: [
          %{keys: "Tab", action: "Reach the header buttons, then each row"},
          %{
            keys: "Up / Down",
            action: "Move to the previous / next row (keeps it under the header)"
          },
          %{keys: "Enter", action: "Open the focused row (dt:open)"},
          %{keys: "Cmd/Ctrl + Enter", action: "Open row_href in a new tab"},
          %{keys: "Space", action: "Tick the focused row (from md); Shift+Space ticks a range"},
          %{keys: "Enter / Space on a header", action: "Sort by that column (dt:sort)"}
        ],
        focus:
          "Rows take focus (tabindex=0) with a 2px ring inside the row; a click on a link, button, input or label inside a row (or anything with data-row-ignore) doesn't open it, nor does a click that ends with text selected.",
        screen_reader:
          "aria-sort announces the sorted column and direction; the bulk bar announces \"N selected\" as it changes; the loading row reads \"Loading more orders\".",
        touch_target:
          "Rows are full-width tap targets; on phones there is no checkbox column (ticking is a desktop job). Bulk buttons are size=\"sm\" on a pointer-first surface.",
        reduced_motion:
          "Only the 150ms row hover tint transitions; scrolling a row into view is instant."
      },
      swiftui: %{
        code: ~S"""
        @State private var sortOrder = [KeyPathComparator(\Order.placed, order: .reverse)]
        @State private var selection = Set<Order.ID>()

        Table(orders, selection: $selection, sortOrder: $sortOrder) {
            TableColumn("Order", value: \.number)
            TableColumn("Customer", value: \.customer)
            TableColumn("Total", value: \.total) { Text($0.total, format: .currency(code: "USD")) }
        }
        .onChange(of: sortOrder) { _, order in orders.sort(using: order) }
        .contextMenu(forSelectionType: Order.ID.self) { ids in
            Button("Export \(ids.count)") { export(ids) }
        } primaryAction: { ids in open(ids) }
        """,
        notes:
          "Table covers sortable columns, selection and opening a row on iPad and Mac. On iPhone it shows only its first column, so use a List of rows (NavigationLink to the record, EditButton for selection) and load more from the last row's onAppear."
      },
      ios_status: :partial,
      examples: [
        %{
          title: "Default",
          center: false,
          heex: ~S"""
          <%!-- state = State.from_params(params, @opts), here sorted by "placed" newest first --%>
          <div class="flex h-80 flex-col">
            <.data_table
              id="orders"
              rows={@rows}
              row_href={&~p"/orders/#{&1.id}"}
              state={@state}
              selectable
              noun={{"order", "orders"}}
              scroll_key="orders"
            >
              <:col :let={o} label="Order" sort="number" class="w-24 font-medium">{o.number}</:col>
              <:col :let={o} label="Customer" sort="customer">{o.customer}</:col>
              <:col :let={o} label="Owner" hide_below="lg" class="w-36">{o.owner}</:col>
              <:col :let={o} label="Status" hide_below="sm" class="w-28">
                <.badge variant={status_variant(o.status)}>{status_label(o.status)}</.badge>
              </:col>
              <:col :let={o} label="Placed" sort="placed" hide_below="md" class="w-32">{o.placed}</:col>
              <:col :let={o} label="Total" sort="total" class="w-28 tabular-nums">{o.total}</:col>
              <:bulk>
                <.button size="sm" variant="outline" phx-click="mark_paid">Mark paid</.button>
                <.button size="sm" variant="ghost" phx-click="export">Export</.button>
              </:bulk>
            </.data_table>
          </div>
          """,
          code: data_table_code("orders", @orders, %State{sort: "placed", dir: :desc}, nil)
        },
        %{
          title: "Rows ticked",
          center: false,
          heex: ~S"""
          <%!-- every loaded row ticked, 240 match: the bulk bar offers them all --%>
          <.data_table
            id="orders"
            rows={@rows}
            state={@state}
            selectable
            matching={@matching}
            all_matching={@all_matching}
            noun={{"order", "orders"}}
          >
            …
            <:bulk>
              <.button size="sm" variant="outline" phx-click="mark_paid">Mark paid</.button>
              <.button size="sm" variant="ghost" phx-click="export">Export</.button>
            </:bulk>
          </.data_table>

          def handle_event("dt:select_all", _params, socket) do
            ids = Enum.map(socket.assigns.rows, & &1.id)
            {:noreply, update(socket, :state, &State.select_all(&1, ids))}
          end

          def handle_event("dt:select_matching", _params, socket),
            do: {:noreply, assign(socket, all_matching: true)}
          """,
          code:
            data_table_code(
              "orders-ticked",
              Enum.take(@orders, 6),
              %State{selected: MapSet.new(Enum.take(@orders, 6), &to_string(&1.id))},
              240
            )
        },
        %{
          title: "Empty",
          center: false,
          heex: ~S"""
          <.data_table id="orders" rows={[]} state={@state} selectable noun={{"order", "orders"}}>
            <:col :let={o} label="Order" sort="number" class="w-24 font-medium">{o.number}</:col>
            <:col :let={o} label="Customer" sort="customer">{o.customer}</:col>
            <:col :let={o} label="Total" sort="total" class="w-28 tabular-nums">{o.total}</:col>
            <:empty title="No orders match" icon="hero-funnel">Try another search or filter.</:empty>
            <:empty_action>
              <.button size="sm" variant="outline" phx-click="dt:reset">Clear filters</.button>
            </:empty_action>
          </.data_table>
          """,
          code: data_table_empty_code()
        }
      ]
    }
  end

  defp data_table_code(id, rows, state, matching) do
    assigns = %{id: id, rows: rows, state: state, matching: matching}

    code(~H"""
    <div class="flex h-80 flex-col">
      <.data_table
        id={@id}
        rows={@rows}
        row_href={&"/orders/#{&1.id}"}
        state={@state}
        selectable
        matching={@matching}
        noun={{"order", "orders"}}
      >
        <:col :let={o} label="Order" sort="number" class="w-24 font-medium">{o.number}</:col>
        <:col :let={o} label="Customer" sort="customer">{o.customer}</:col>
        <:col :let={o} label="Owner" hide_below="lg" class="w-36">{o.owner}</:col>
        <:col :let={o} label="Status" hide_below="sm" class="w-28">
          <.badge variant={status_variant(o.status)}>{status_label(o.status)}</.badge>
        </:col>
        <:col :let={o} label="Placed" sort="placed" hide_below="md" class="w-32">{o.placed}</:col>
        <:col :let={o} label="Total" sort="total" class="w-28 tabular-nums">{o.total}</:col>
        <:bulk>
          <.button size="sm" variant="outline">Mark paid</.button>
          <.button size="sm" variant="ghost">Export</.button>
        </:bulk>
      </.data_table>
    </div>
    """)
  end

  defp data_table_empty_code do
    assigns = %{state: %State{search: "zzz"}}

    code(~H"""
    <div class="flex h-72 flex-col">
      <.data_table id="orders-empty" rows={[]} state={@state} selectable noun={{"order", "orders"}}>
        <:col :let={o} label="Order" sort="number" class="w-24 font-medium">{o.number}</:col>
        <:col :let={o} label="Customer" sort="customer">{o.customer}</:col>
        <:col :let={o} label="Total" sort="total" class="w-28 tabular-nums">{o.total}</:col>
        <:empty title="No orders match" icon="hero-funnel">Try another search or filter.</:empty>
        <:empty_action>
          <.button size="sm" variant="outline">Clear filters</.button>
        </:empty_action>
      </.data_table>
    </div>
    """)
  end

  # ---------------------------------------------------------------------------
  # Table toolbar
  # ---------------------------------------------------------------------------

  defp table_toolbar do
    %{
      slug: "table-toolbar",
      title: "Table Toolbar",
      description:
        "The one row above a data table: saved views or the count, search, a Filters sheet, and the filters that are on as chips.",
      hook: true,
      guidance: %{
        use_when: [
          "Above a <.data_table>: search, filters and saved views of one list",
          "Filters that belong in the URL, so a view can be bookmarked and Back restores it",
          "Saved views people switch between (All, Open, Mine), each a patch link with its count"
        ],
        avoid_when: [
          "A short list with nothing to filter - a heading and the table are enough",
          "Filters that change the whole page (date range for a dashboard) - put them in the page header",
          "Search that only the server can run across records - use <.command on_search>"
        ],
        sizing:
          "One row, 8px gaps: views (a tab nav) or a muted text-sm count, the h-9 search (16rem; 14rem beside views), an outline Filters button with a 20px primary count pill, then :more. Chips sit 8px under the row in a reveal.",
        responsive:
          "Phones: without views the search takes the row; beside views it shrinks to 7rem. Filters goes icon-only (the label stays for screen readers), :more hides, and the sheet adds a Sort by select (from sorts). The row never wraps: views fold into the Views menu, chips into +N.",
        ios:
          ".searchable for the search, .searchScopes or a segmented Picker for views, and a toolbar button that opens a filter sheet (a Form of pickers)."
      },
      props: [
        %{name: "id", type: "string (required)", default: "-"},
        %{name: "search / placeholder", type: "string", default: ~s("" / "Search…")},
        %{
          name: "shown / total",
          type: "integer",
          default: "nil (\"N orders\", \"N of M\" when filtered)"
        },
        %{name: "noun", type: "{singular, plural}", default: ~s({"row", "rows"})},
        %{name: "views", type: "[%{key, label, count, path, active, edited}]", default: "[]"},
        %{
          name: "menu",
          type: "[%{key, label, group, icon, active, path | click}]",
          default: "[]"
        },
        %{name: "chips", type: "[{key, label} | {key, label, :fixed}]", default: "[]"},
        %{
          name: "sort / sorts",
          type: "\"key:dir\" / [{label, \"key:dir\"}]",
          default: ~s("" / [])
        },
        %{name: "target", type: "phx-target", default: "nil"},
        %{
          name: ":filter key label",
          type: "slot (one select or combobox named key)",
          default: "-"
        },
        %{name: ":more", type: "slot (hidden on phones)", default: "-"},
        %{name: ":save", type: "slot (end of the chips row)", default: "-"}
      ],
      notes: ~S"""
      The toolbar is one form: it sends dt:filter (on change and submit) with q (the search, debounced 200ms), each :filter's value (a multiple select posts a list, cleared posts "") and sort. Removing a chip sends dt:unfilter %{"key"}; Clear all sends dt:reset. Every payload carries "table" => the toolbar's id.

      Apply it with State.put_search/2, State.put_filters/4 and State.parse_sort/3 (value first: State.parse_sort(params["sort"], state, opts)), then push_patch to State.to_params/2. State.chips/3 turns the filters into chips ("Open or Paid"); a saved view's own filter is a {key, label, :fixed} chip that can't be removed.

      The Filters sheet: each :filter under its label, applied as it changes (the sheet stays open); on phones a Sort by select (the first of sorts is the default order, posted as ""); a footer with Clear all and "Show N orders", which closes it. On this static page the sheet, pickers, views menu and chips run, but nothing is sent; the full list page runs on the dev server (`/lab/data-table`).
      """,
      specs: %{
        anatomy: [
          %{
            part: "Views",
            description:
              "A <.tab_nav> of patch links with counts; an edited view shows a dot; overflow and the menu entries go in the Views menu."
          },
          %{
            part: "Count",
            description: "Without views: \"N orders\", or \"N of M\" while filtered."
          },
          %{
            part: "Search",
            description: "An input with a magnifier, name q, debounced 200ms."
          },
          %{
            part: "Filters button",
            description: "Outline button that opens the sheet, with the number of filters on."
          },
          %{part: "More", description: "Trailing controls (Export, Columns), hidden on phones."},
          %{
            part: "Chips row",
            description:
              "A <.chip_row> in a <.reveal>: removable chips, fixed chips, then :save and Clear all."
          },
          %{
            part: "Filters sheet",
            description:
              "A <.sheet>: one field per filter, Sort by on phones, Clear all + Show N."
          }
        ],
        measurements: [
          %{property: "Row", value: "flex, 0.5rem gaps, never wraps"},
          %{property: "Search", value: "16rem (14rem beside views from 40rem, 7rem on phones)"},
          %{property: "Filters count", value: "1.25rem pill, var(--primary), text-xs"},
          %{property: "Edited dot", value: "0.375rem, var(--primary)"},
          %{property: "Chips row", value: "0.5rem under the row, 180ms reveal"},
          %{
            property: "Sheet fields",
            value: "1rem apart, label text-sm 500, 0.5rem above its picker"
          }
        ],
        tokens: [
          "muted",
          "muted-foreground",
          "primary",
          "primary-foreground",
          "secondary",
          "input",
          "border-color",
          "popover",
          "ring"
        ]
      },
      accessibility: %{
        roles:
          "The views are a nav named \"Views\" (aria-current on the active link). The search is type=search labelled by its placeholder. The Filters button has aria-haspopup=dialog and aria-controls the sheet; the count reads \"2 on\". Chips are a group named \"Active filters\"; each × is \"Remove filter: Status: Open\".",
        keyboard: [
          %{keys: "Tab", action: "Views, search, Filters, :more, then the chips"},
          %{keys: "Enter / Space", action: "Open the Filters sheet"},
          %{keys: "Esc", action: "Close the sheet (or an open picker inside it first)"},
          %{keys: "Enter in the search", action: "Submit the form (dt:filter) at once"}
        ],
        focus:
          "Opening the sheet moves focus into it; closing returns it to the Filters button. Removing a chip moves focus to its neighbour.",
        screen_reader:
          "The count is plain text (\"12 of 240\"); the Filters button announces how many filters are on; the views menu names the active view.",
        touch_target:
          "On phones Filters is a 44px icon button and the sheet's pickers use full_width (44px on touch).",
        reduced_motion:
          "The chips row slides 180ms and chips fade; both drop to instant under prefers-reduced-motion."
      },
      swiftui: %{
        code: ~S"""
        @State private var query = ""
        @State private var view: OrderView = .all
        @State private var showFilters = false

        OrdersList(query: query, view: view, filters: filters)
            .searchable(text: $query, prompt: "Search orders")
            .searchScopes($view) {
                ForEach(OrderView.allCases) { Text($0.label).tag($0) }
            }
            .toolbar {
                Button("Filters", systemImage: "line.3.horizontal.decrease.circle") { showFilters = true }
            }
            .sheet(isPresented: $showFilters) { FiltersForm(filters: $filters) }
        """,
        notes:
          ".searchable with .searchScopes covers search and views; filters go in a sheet holding a Form of Pickers (a multi-select is a List with selection). Show active filters as a horizontal row of removable capsules above the list if they matter at a glance."
      },
      ios_status: :partial,
      examples: [
        %{
          title: "With views",
          center: false,
          heex: ~S"""
          <.table_toolbar
            id="orders-toolbar"
            search={@state.search}
            placeholder="Search orders"
            shown={@matching}
            total={@total}
            noun={{"order", "orders"}}
            views={
              for v <- @views do
                %{key: v.key, label: v.label, count: v.count, path: ~p"/orders?view=#{v.key}",
                  active: v.key == @view.key, edited: v.key == @view.key and State.filtered?(@state, @opts)}
              end
            }
            menu={[%{key: "manage", label: "Manage views…", icon: "hero-cog-6-tooth", path: ~p"/views"}]}
            chips={[{"view", "Status: Overdue", :fixed} | @chips]}
            sort={State.sort_value(@state)}
            sorts={[
              {"Newest first", "placed:desc"},
              {"Oldest first", "placed:asc"},
              {"Customer A–Z", "customer:asc"},
              {"Largest total", "total:desc"}
            ]}
          >
            <:filter key="status" label="Status">
              <.select id="filter-status" name="status" multiple full_width
                value={State.values(@state.filters["status"])} placeholder="Any status">
                <:option :for={{label, value} <- @statuses} value={value}>{label}</:option>
              </.select>
            </:filter>
            <:filter key="owner" label="Owner">
              <.combobox id="filter-owner" name="owner" multiple full_width
                value={State.values(@state.filters["owner"])} placeholder="Anyone">
                <:option :for={{label, value} <- @owners} value={value}>{label}</:option>
              </.combobox>
            </:filter>
            <:save>
              <.button size="sm" variant="outline" phx-click="save_view">Save view</.button>
            </:save>
          </.table_toolbar>
          """,
          code: toolbar_views_code()
        },
        %{
          title: "Without views",
          center: false,
          heex: ~S"""
          <.table_toolbar
            id="customers-toolbar"
            search={@state.search}
            placeholder="Search customers"
            shown={length(@rows)}
            total={@total}
            noun={{"customer", "customers"}}
            chips={State.chips(@state, ["plan"], %{"plan" => @plans})}
            sort={State.sort_value(@state)}
            sorts={[{"Name A–Z", "name:asc"}, {"Most orders", "orders:desc"}, {"Newest", "joined:desc"}]}
          >
            <:filter key="plan" label="Plan">
              <.select id="filter-plan" name="plan" multiple full_width
                value={State.values(@state.filters["plan"])} placeholder="Any plan">
                <:option :for={{label, value} <- @plans} value={value}>{label}</:option>
              </.select>
            </:filter>
            <:more><.button size="sm" variant="outline" phx-click="export">Export</.button></:more>
          </.table_toolbar>
          """,
          code: toolbar_plain_code()
        }
      ]
    }
  end

  defp toolbar_views_code do
    views =
      for {key, label, count} <- [
            {"all", "All orders", 240},
            {"open", "Open", 48},
            {"overdue", "Overdue", 19},
            {"mine", "Mine", 60}
          ] do
        %{
          key: key,
          label: label,
          count: count,
          path: "#" <> key,
          active: key == "overdue",
          edited: key == "overdue"
        }
      end

    assigns = %{
      views: views,
      statuses: @statuses,
      owners: Enum.map(@owners, &{&1, &1}),
      sorts: @order_sorts
    }

    code(~H"""
    <.table_toolbar
      id="orders-toolbar"
      placeholder="Search orders"
      shown={7}
      total={19}
      noun={{"order", "orders"}}
      views={@views}
      menu={[
        %{key: "manage", label: "Manage views…", icon: "hero-cog-6-tooth", path: "#manage-views"}
      ]}
      chips={[{"view", "Status: Overdue", :fixed}, {"owner", "Owner: Pat Lee"}]}
      sorts={@sorts}
    >
      <:filter key="status" label="Status">
        <.select
          id="filter-status"
          name="status"
          multiple
          full_width
          value={[]}
          placeholder="Any status"
        >
          <:option :for={{label, value} <- @statuses} value={value}>{label}</:option>
        </.select>
      </:filter>
      <:filter key="owner" label="Owner">
        <.combobox
          id="filter-owner"
          name="owner"
          multiple
          full_width
          value={["Pat Lee"]}
          placeholder="Anyone"
        >
          <:option :for={{label, value} <- @owners} value={value}>{label}</:option>
        </.combobox>
      </:filter>
      <:save>
        <.button size="sm" variant="outline">Save view</.button>
      </:save>
    </.table_toolbar>
    """)
  end

  defp toolbar_plain_code do
    assigns = %{plans: [{"Free", "free"}, {"Team", "team"}, {"Business", "business"}]}

    code(~H"""
    <.table_toolbar
      id="customers-toolbar"
      search="harbor"
      placeholder="Search customers"
      shown={3}
      total={128}
      noun={{"customer", "customers"}}
      sorts={[{"Name A–Z", "name:asc"}, {"Most orders", "orders:desc"}, {"Newest", "joined:desc"}]}
    >
      <:filter key="plan" label="Plan">
        <.select id="filter-plan" name="plan" multiple full_width value={[]} placeholder="Any plan">
          <:option :for={{label, value} <- @plans} value={value}>{label}</:option>
        </.select>
      </:filter>
      <:more>
        <.button size="sm" variant="outline">Export</.button>
      </:more>
    </.table_toolbar>
    """)
  end

  # ---------------------------------------------------------------------------
  # Empty
  # ---------------------------------------------------------------------------

  defp empty do
    %{
      slug: "empty",
      title: "Empty",
      description:
        "An empty state: an icon in a muted circle, a short title, one line saying what belongs here, and an optional action.",
      guidance: %{
        use_when: [
          "A page or list with nothing in it yet (\"No invoices yet\")",
          "A search or filter that matched nothing - say so and offer to clear it",
          "An empty table or card - variant=\"plain\" inside it"
        ],
        avoid_when: [
          "Errors - use an alert that says what went wrong and how to fix it",
          "Loading - use skeletons or a spinner, never an empty state that flips to content",
          "A field with no value - show \"Not set\" in muted text"
        ],
        sizing:
          "A 40px muted circle with a 20px icon, an 8px gap, a text-sm medium title, one text-sm muted line (max 24rem), and size=\"sm\" actions 8px below. Card: 48px / 24px padding, rounded-xl, 1px border. Plain: 40px vertical padding, no border.",
        responsive:
          "Centred and balanced at every width; the text wraps within 24rem. Keep it to one action on phones.",
        ios:
          "ContentUnavailableView with a label, a description and actions - the same three parts."
      },
      props: [
        %{name: "icon", type: "string (heroicon class)", default: "nil"},
        %{name: "title", type: "string", default: "nil"},
        %{name: "variant", type: "card | plain", default: "card"},
        %{name: "class", type: "any", default: "nil"},
        %{name: "inner_block", type: "slot (one muted line)", default: "-"},
        %{name: ":media", type: "slot (replaces the icon in the circle)", default: "-"},
        %{name: ":actions", type: "slot (size=\"sm\" buttons)", default: "-"}
      ],
      notes:
        "On its own it is a bordered card (variant=\"card\"). Inside a table or card use variant=\"plain\": a centred block with no border of its own. <.data_table>'s :empty slot renders it that way, below the header and not as a row. Say what belongs here and how to add it; a filter that matched nothing offers to clear the filters. Links inside the description are underlined.",
      specs: %{
        anatomy: [
          %{part: "Media", description: "A 40px muted circle holding the icon or :media."},
          %{part: "Title", description: "Short, text-sm medium: \"No invoices yet\"."},
          %{
            part: "Description",
            description: "One muted line: what belongs here, how it gets here."
          },
          %{part: "Actions", description: "Optional size=\"sm\" buttons, centred."}
        ],
        measurements: [
          %{property: "Media", value: "2.5rem / 40px circle, var(--muted), 1.25rem icon"},
          %{property: "Gap", value: "0.5rem between parts; actions 0.5rem further"},
          %{
            property: "Card padding",
            value: "3rem block, 1.5rem inline; 1px border, var(--radius-xl)"
          },
          %{property: "Plain padding", value: "2.5rem block, no border"},
          %{property: "Description", value: "text-sm, var(--muted-foreground), max 24rem"}
        ],
        tokens: [
          "card",
          "card-foreground",
          "border-color",
          "muted",
          "muted-foreground",
          "foreground"
        ]
      },
      accessibility: %{
        roles:
          "Plain text in a div; the circle is aria-hidden, so the title and description carry the meaning.",
        focus: "Not focusable itself; its action buttons keep their own focus rings.",
        screen_reader:
          "Read as text. When it replaces results after a search or filter, the change should be announced (a live region on the result count, or move focus to it).",
        touch_target: "Actions reach 44px on touch through the button sizes.",
        reduced_motion: "No motion."
      },
      swiftui: %{
        code: ~S"""
        ContentUnavailableView {
            Label("No invoices yet", systemImage: "doc.text")
        } description: {
            Text("Invoices you send show up here.")
        } actions: {
            Button("New invoice") { newInvoice() }
        }
        """,
        notes:
          "ContentUnavailableView is the native empty state (and .search for a search that matched nothing); use it as a List's overlay when the list is empty."
      },
      ios_status: :parity,
      examples: [
        %{
          title: "Card",
          heex: ~S"""
          <.empty icon="hero-document-text" title="No invoices yet">
            Invoices you send show up here.
            <:actions><.button size="sm" navigate={~p"/invoices/new"}>New invoice</.button></:actions>
          </.empty>
          """,
          code: empty_card_code()
        },
        %{
          title: "In a table or card",
          heex: ~S"""
          <.card>
            <.card_body>
              <.card_title>Team</.card_title>
              <.card_description>People who can work on this project.</.card_description>
            </.card_body>
            <.empty variant="plain" icon="hero-user-group" title="No members yet">
              Invite people to work on this project with you.
              <:actions><.button size="sm" variant="outline">Invite people</.button></:actions>
            </.empty>
          </.card>
          """,
          code: empty_plain_code()
        },
        %{
          title: "Custom media",
          heex: ~S"""
          <.empty title="No messages from Pat Lee">
            <:media><span class="text-sm font-medium">PL</span></:media>
            When Pat writes to you, it shows up here.
            <:actions><.button size="sm" variant="outline">Send a message</.button></:actions>
          </.empty>
          """,
          code: empty_media_code()
        }
      ]
    }
  end

  defp empty_card_code do
    assigns = %{}

    code(~H"""
    <.empty icon="hero-document-text" title="No invoices yet" class="w-full max-w-md">
      Invoices you send show up here.
      <:actions><.button size="sm">New invoice</.button></:actions>
    </.empty>
    """)
  end

  defp empty_plain_code do
    assigns = %{}

    code(~H"""
    <.card class="w-full max-w-md">
      <.card_body>
        <.card_title>Team</.card_title>
        <.card_description>People who can work on this project.</.card_description>
      </.card_body>
      <.empty variant="plain" icon="hero-user-group" title="No members yet">
        Invite people to work on this project with you.
        <:actions><.button size="sm" variant="outline">Invite people</.button></:actions>
      </.empty>
    </.card>
    """)
  end

  defp empty_media_code do
    assigns = %{}

    code(~H"""
    <.empty title="No messages from Pat Lee" class="w-full max-w-md">
      <:media><span class="text-sm font-medium">PL</span></:media>
      When Pat writes to you, it shows up here.
      <:actions><.button size="sm" variant="outline">Send a message</.button></:actions>
    </.empty>
    """)
  end

  # ---------------------------------------------------------------------------
  # Record tabs
  # ---------------------------------------------------------------------------

  defp record_tabs do
    %{
      slug: "record-tabs",
      title: "Record Tabs",
      description:
        "A tab row inside a record (Details, Activity, Files): the active tab is underlined and the server owns which one shows.",
      guidance: %{
        use_when: [
          "Parts of one record that don't fit on one page: Details, Activity, Files",
          "Under the record's page header (its :below slot), so it pins with the title"
        ],
        avoid_when: [
          "Saved views of a list, each a URL - use <.tab_nav>",
          "Panels switched in the browser with no server state - use <.tabs>",
          "Sections of one long form - use <.section_nav>"
        ],
        sizing:
          "shadcn's line tabs: 40px tabs (44px on touch), text-sm medium, 16px apart on a 1px line; the active tab is foreground with a 2px underline, the rest muted. A count is a muted pill after the label.",
        responsive:
          "Two to four short labels fit every width; labels truncate rather than wrap, and the row never scrolls. More than four belong in a <.tab_nav> or a different structure.",
        ios: "A segmented Picker under the navigation title, or a TabView for top-level parts."
      },
      props: [
        %{name: "id", type: "string (required)", default: "-"},
        %{name: "tabs", type: "[{key, label}] or [{key, label, count}]", default: "-"},
        %{name: "active", type: "any (a tab's key)", default: "nil (the first tab)"},
        %{name: "event", type: "string", default: ~s("tab")},
        %{name: "target", type: "phx-target", default: "nil"},
        %{name: "aria_label", type: "string", default: "nil"},
        %{name: "class", type: "any", default: "nil"}
      ],
      notes:
        "Each tab sends the event (\"tab\" by default) with %{\"tab\" => key}; assign it and render that tab's content (keep it in the URL with push_patch/2 if people link to it). The arrow keys come from shadcn-daisyui.js (one delegated listener, no hook needed). On this static page the keys work but nothing is sent; the record page on the dev server (`/lab/data-table/:id`) switches Details and Activity.",
      specs: %{
        anatomy: [
          %{part: "Tablist", description: "A flex row on a 1px border line."},
          %{
            part: "Tab",
            description:
              "A button: label (truncates) and an optional count; muted until hover or active."
          },
          %{part: "Underline", description: "The active tab's 2px foreground bar over the line."}
        ],
        measurements: [
          %{property: "Tab height", value: "2.5rem / 40px (2.75rem / 44px on coarse pointers)"},
          %{property: "Gap", value: "1rem between tabs; 0.25rem inline padding"},
          %{property: "Label", value: "0.875rem, weight 500"},
          %{property: "Underline", value: "2px, var(--foreground), rounded, over the 1px line"}
        ],
        tokens: ["foreground", "muted-foreground", "border-color", "muted", "ring"]
      },
      accessibility: %{
        roles:
          "role=tablist (named with aria_label); each tab is a role=tab button with aria-selected. One tab stop: the active tab has tabindex=0, the rest -1.",
        keyboard: [
          %{keys: "Tab", action: "Focus the active tab; Tab again leaves the row"},
          %{
            keys: "Left / Right",
            action: "Move to the previous / next tab (wraps; mirrored in RTL)"
          },
          %{keys: "Home / End", action: "First / last tab"},
          %{keys: "Enter / Space", action: "Pick the focused tab (sends the event)"}
        ],
        focus: "A ring on the focused tab; picking keeps focus on it.",
        screen_reader:
          "Announced as a tab, n of m, selected or not; a count reads after the label.",
        touch_target: "44px tall on touch; tabs are at least label-wide with 4px padding.",
        reduced_motion: "Only the 150ms colour change; the underline moves instantly."
      },
      swiftui: %{
        code: ~S"""
        @State private var tab: OrderTab = .details

        Picker("Order", selection: $tab) {
            Text("Details").tag(OrderTab.details)
            Text("Activity (4)").tag(OrderTab.activity)
            Text("Files (2)").tag(OrderTab.files)
        }
        .pickerStyle(.segmented)
        """,
        notes:
          "A segmented Picker is the closest native control; it is boxed rather than underlined. Keep the selection in the view model so a deep link can choose it."
      },
      ios_status: :partial,
      examples: [
        %{
          title: "Default",
          center: false,
          heex: ~S"""
          <.record_tabs
            id="order-tabs"
            tabs={[{"details", "Details"}, {"activity", "Activity", 4}, {"files", "Files", 2}]}
            active={@tab}
            aria_label="Order"
          />

          def handle_event("tab", %{"tab" => tab}, socket), do: {:noreply, assign(socket, tab: tab)}
          """,
          code: record_tabs_code()
        }
      ]
    }
  end

  defp record_tabs_code do
    assigns = %{}

    code(~H"""
    <.record_tabs
      id="order-tabs"
      tabs={[{"details", "Details"}, {"activity", "Activity", 4}, {"files", "Files", 2}]}
      active="details"
      aria_label="Order"
    />
    """)
  end

  # ---------------------------------------------------------------------------
  # Table card
  # ---------------------------------------------------------------------------

  @activity [
    %{id: 1, what: "Order placed", by: "Pat Lee", at: "Oct 21, 2026"},
    %{id: 2, what: "Invoice sent", by: "System", at: "Oct 22, 2026"},
    %{id: 3, what: "Payment reminder", by: "Pat Lee", at: "Nov 4, 2026"},
    %{id: 4, what: "Status: Paid", by: "System", at: "Nov 5, 2026"}
  ]

  @items [
    %{name: "Annual service plan", qty: 1, price: "$744.00"},
    %{name: "Filters, set of 4", qty: 2, price: "$186.00"},
    %{name: "Delivery", qty: 1, price: "$124.00"}
  ]

  defp table_card do
    %{
      slug: "table-card",
      title: "Table Card",
      description:
        "A card of rows with a title and description: a record's activity, its line items, its contacts.",
      guidance: %{
        use_when: [
          "Rows that belong to one record: activity, line items, contacts, payments",
          "A few columns that read as a list on phones (stacked) or stay side by side (grid)"
        ],
        avoid_when: [
          "A list page with sorting, selection and filters - use <.data_table>",
          "Rows people compare across many columns - use <.table>",
          "One object per row with media and actions - use <.item>"
        ],
        sizing:
          "Card header 24px padding (16px under it): card-title, a muted description, :actions on the right. Rows text-sm, 12px / 24px padding, 16px column gap, 1px lines edge to edge; the last row's padding is the space under it. Column labels are a muted 500 row.",
        responsive:
          "From sm the columns share the width equally (2-6 columns) under a label row. On phones each row stacks its cells, unless grid (a grid-cols class) keeps them side by side at every width - use it for short numeric columns such as Qty and Price.",
        ios: "A Section in an inset-grouped List (header and footer text), one row per item."
      },
      props: [
        %{name: "id", type: "string (required)", default: "-"},
        %{name: "title / description", type: "string", default: "nil"},
        %{name: "rows", type: "list (required)", default: "-"},
        %{name: "row_id", type: "fn row -> DOM id", default: "nil"},
        %{name: "row_class", type: "fn row -> classes", default: "nil"},
        %{name: "grid", type: "string (grid-cols class)", default: "nil (stack on phones)"},
        %{name: ":col label class align", type: "slot", default: "-"},
        %{name: ":actions", type: "slot (right of the title)", default: "-"},
        %{name: ":empty", type: "slot (the only row when there are none)", default: "-"}
      ],
      notes:
        "The rightmost column is right-aligned unless align=\"left\" (on phones only with grid, since stacked cells read top to bottom). :empty renders as the only row when rows is empty (\"Nothing has happened yet.\"). row_class styles a row (a muted cancelled line). The record page on the dev server (`/lab/data-table/:id`) uses it for Items and Activity.",
      specs: %{
        anatomy: [
          %{part: "Header", description: "card-title, muted description, :actions on the right."},
          %{
            part: "Label row",
            description: "Column labels, muted 500, from sm (role=columnheader)."
          },
          %{part: "Row", description: "A grid row of cells, 1px line under it, edge to edge."},
          %{part: "Empty row", description: ":empty, centred muted text, when there are no rows."}
        ],
        measurements: [
          %{property: "Header padding", value: "1.5rem 1.5rem 1rem"},
          %{property: "Row padding", value: "0.75rem block, 1.5rem inline"},
          %{property: "Column gap", value: "1rem (0.25rem between stacked cells)"},
          %{property: "Label row", value: "0.5rem block padding, var(--muted-foreground), 500"},
          %{
            property: "Columns",
            value: "equal shares for 2-6 columns from 40rem, or the grid class"
          }
        ],
        tokens: ["card", "card-foreground", "border-color", "muted-foreground", "foreground"]
      },
      accessibility: %{
        roles:
          "A section holding role=table (named by the title) with rowgroups, rows, columnheaders and cells, so the stacked phone layout keeps table semantics.",
        focus:
          "Nothing focusable of its own; links and buttons in cells or :actions keep their rings.",
        screen_reader:
          "Read as a table with column headers; stacked cells on phones still announce their column.",
        touch_target: "Interactive content in cells (links, buttons) should reach 44px on touch.",
        reduced_motion: "No motion."
      },
      swiftui: %{
        code: ~S"""
        Section {
            ForEach(events) { event in
                LabeledContent {
                    Text(event.at, format: .dateTime.month().day())
                } label: {
                    Text(event.what)
                    Text(event.by).foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Activity")
        } footer: {
            Text("Everything that happened to #1042.")
        }
        """,
        notes:
          "An inset-grouped List Section matches the card; LabeledContent puts the trailing value on the right like the rightmost column. Use Grid for true columns on iPad."
      },
      ios_status: :partial,
      examples: [
        %{
          title: "Activity",
          heex: ~S"""
          <.table_card
            id="activity"
            title="Activity"
            description="Everything that happened to #1042."
            rows={@events}
            row_id={&"event-#{&1.id}"}
          >
            <:actions><.button size="sm" variant="outline" phx-click="add_note">Add note</.button></:actions>
            <:col :let={e} label="Event" class="font-medium">{e.what}</:col>
            <:col :let={e} label="By" class="text-muted-foreground">{e.by}</:col>
            <:col :let={e} label="When">{e.at}</:col>
            <:empty>Nothing has happened yet.</:empty>
          </.table_card>
          """,
          code: table_card_activity_code()
        },
        %{
          title: "Line items",
          heex: ~S"""
          <.table_card
            id="items"
            title="Items"
            description="What's on the order."
            rows={@items}
            grid="grid-cols-[minmax(0,1fr)_2.5rem_6rem]"
          >
            <:col :let={i} label="Item">{i.name}</:col>
            <:col :let={i} label="Qty" class="tabular-nums">{i.qty}</:col>
            <:col :let={i} label="Price" class="tabular-nums">{i.price}</:col>
          </.table_card>
          """,
          code: table_card_items_code()
        }
      ]
    }
  end

  defp table_card_activity_code do
    assigns = %{events: @activity}

    code(~H"""
    <.table_card
      id="activity"
      title="Activity"
      description="Everything that happened to #1042."
      rows={@events}
      row_id={&"event-#{&1.id}"}
      class="w-full max-w-2xl"
    >
      <:actions><.button size="sm" variant="outline">Add note</.button></:actions>
      <:col :let={e} label="Event" class="font-medium">{e.what}</:col>
      <:col :let={e} label="By" class="text-muted-foreground">{e.by}</:col>
      <:col :let={e} label="When">{e.at}</:col>
      <:empty>Nothing has happened yet.</:empty>
    </.table_card>
    """)
  end

  defp table_card_items_code do
    assigns = %{items: @items}

    code(~H"""
    <.table_card
      id="items"
      title="Items"
      description="What's on the order."
      rows={@items}
      grid="grid-cols-[minmax(0,1fr)_2.5rem_6rem]"
      class="w-full max-w-2xl"
    >
      <:col :let={i} label="Item">{i.name}</:col>
      <:col :let={i} label="Qty" class="tabular-nums">{i.qty}</:col>
      <:col :let={i} label="Price" class="tabular-nums">{i.price}</:col>
    </.table_card>
    """)
  end

  # ---------------------------------------------------------------------------
  # Section nav
  # ---------------------------------------------------------------------------

  defp section_nav do
    %{
      slug: "section-nav",
      title: "Section Nav",
      description:
        "Where an edit form's sections are: a list beside the cards on wide screens, a dropdown in the page header on narrow ones, marking the section in view.",
      hook: true,
      guidance: %{
        use_when: [
          "A long edit form split into cards (Customer, Addresses, Items, Billing…)",
          "Records people come back to for one detail: the list finds it the same way every time",
          "Over 10 sections: the side list adds a filter"
        ],
        avoid_when: [
          "Three or four short sections - one scrolling page is enough",
          "Separate parts of a record with their own data - use <.record_tabs>",
          "A step-by-step flow - use steps and one page per step"
        ],
        sizing:
          "Side: a 12rem column beside the cards (24px gap), text-sm items with 6px / 8px padding, rounded-md, accent on the section in view, text-xs muted group labels. Select: a full-width outline trigger, a floating list with options at least 44px tall and a tick on the current one.",
        responsive:
          "From lg (64rem) the side list shows, pinned just under the page's pinned header and level with the first card, scrolling on its own when taller than the window. Below lg it hides and variant=\"select\" (in the page header's :below slot) shows instead - render both.",
        ios:
          "A Form with a Section per card in a ScrollViewReader, and a toolbar Menu of sections that scrolls to one."
      },
      props: [
        %{name: "id", type: "string (required)", default: "-"},
        %{name: "sections", type: "[{id, label}] or [{id, label, group}]", default: "-"},
        %{name: "variant", type: "side | select", default: "side"},
        %{name: "aria_label", type: "string", default: ~s("Sections")},
        %{name: "class", type: "any", default: "nil"},
        %{
          name: "inner_block",
          type: "slot (side: the cards, laid out beside the list)",
          default: "-"
        }
      ],
      notes:
        "Each section is an element (a card) with that id. Both variants mark the section in view (aria-current / aria-selected), measured against the bottom of the pinned page header (data-sticky-top); at the bottom of the page it is the last one. Choosing one scrolls there (smoothly, or at once under reduced motion), keeps it marked until the scroll settles, moves focus to it and closes the select. The side list's filter matches section and group names. Consecutive sections with the same group share a heading; the select names the current one \"Group, Section\". Needs the ShadcnSectionNav hook. In these previews a bordered box stands in for the window (the side list is capped to the box's height); the record page on the dev server (`/lab/data-table/:id`) shows both variants in a real page.",
      specs: %{
        anatomy: [
          %{
            part: "Layout",
            description: "Side, with cards: a grid of the list and the cards (24px apart)."
          },
          %{part: "Filter", description: "Over 10 sections: a \"Filter sections\" search input."},
          %{
            part: "Group label",
            description: "text-xs muted, over consecutive sections of a group."
          },
          %{part: "Item", description: "A link to #id; accent and 500 on the section in view."},
          %{
            part: "Select trigger",
            description: "Full-width outline button naming the current section."
          },
          %{
            part: "Select list",
            description: "A listbox of 44px options grouped by heading, with a tick."
          }
        ],
        measurements: [
          %{property: "Side column", value: "12rem, from 64rem; sticky under the header + 16px"},
          %{property: "Item", value: "0.375rem 0.5rem padding, text-sm, var(--radius-md)"},
          %{property: "Group label", value: "0.75rem, weight 500, var(--muted-foreground)"},
          %{property: "Select options", value: "min 2.75rem / 44px, 16px tick"},
          %{property: "Select list", value: "max min(24rem, 60dvh), scrolls"}
        ],
        tokens: [
          "accent",
          "accent-foreground",
          "muted-foreground",
          "foreground",
          "input",
          "popover",
          "border-color",
          "ring"
        ]
      },
      accessibility: %{
        roles:
          "Side: a nav named \"Sections\" of links (href=#id) with aria-current=true on the section in view. Select: a button (aria-haspopup=listbox, aria-expanded, aria-controls) and a listbox of role=option buttons with aria-selected, grouped by role=group headings.",
        keyboard: [
          %{keys: "Tab", action: "Side: the filter, then each link"},
          %{keys: "Enter", action: "Go to the section; focus moves to it"},
          %{keys: "Down / Up on the trigger", action: "Open the list on the first / last option"},
          %{keys: "Up / Down, Home / End", action: "Move between options"},
          %{keys: "Esc", action: "Close the list; focus back on the trigger"}
        ],
        focus:
          "Choosing a section moves focus to its card (tabindex=-1, no ring around the whole card) so keyboard and screen reader users continue from there.",
        screen_reader:
          "The current link reads as current; the trigger reads \"Sections\" and the section in view; options announce selected.",
        touch_target:
          "Select options are at least 44px tall; side items are a desktop control (from lg).",
        reduced_motion: "Choosing a section jumps there instead of scrolling smoothly."
      },
      swiftui: %{
        code: ~S"""
        ScrollViewReader { proxy in
            Form {
                ForEach(sections) { section in
                    Section(section.label) { fields(for: section) }.id(section.id)
                }
            }
            .toolbar {
                Menu("Sections", systemImage: "list.bullet") {
                    ForEach(sections) { section in
                        Button(section.label) { withAnimation { proxy.scrollTo(section.id, anchor: .top) } }
                    }
                }
            }
        }
        """,
        notes:
          "iOS has no scroll-spy list; a toolbar Menu of sections that scrolls with ScrollViewReader covers finding a section. On iPad a NavigationSplitView sidebar of sections is the wide-screen equivalent."
      },
      ios_status: :guidance_only,
      examples: [
        %{
          title: "Side list",
          center: false,
          heex: ~S"""
          <.section_nav
            id="order-sections"
            sections={[
              {"customer", "Name", "Customer"},
              {"contact", "Contact", "Customer"},
              {"billing-address", "Billing address", "Addresses"},
              {"shipping-address", "Shipping address", "Addresses"},
              {"items", "Items", "Order"},
              …
              {"notes", "Notes", "Other"}
            ]}
          >
            <.card id="customer">…</.card>
            <.card id="contact">…</.card>
            …
            <.card id="notes">…</.card>
          </.section_nav>
          """,
          code: section_side_code()
        },
        %{
          title: "Select (narrow screens)",
          center: false,
          heex: ~S"""
          <.page_header>
            Edit order
            <:below>
              <.section_nav id="order-sections-select" sections={@sections} variant="select" />
            </:below>
          </.page_header>
          """,
          code: section_select_code()
        }
      ]
    }
  end

  defp section_side_code do
    assigns = %{sections: sections("side-"), nav: nav_sections("side-")}

    code(~H"""
    <div class="h-96 w-full overflow-y-auto rounded-xl border border-border p-4">
      <!-- The box stands in for the window: the list is capped to its height. -->
      <p class="mb-4 text-sm text-muted-foreground lg:hidden">
        The list shows from 1024px wide: widen the window to see it.
      </p>
      <.section_nav id="side-sections" sections={@nav} style="max-height: 20rem">
        <.card :for={{id, label, _group, what} <- @sections} id={id}>
          <.card_body>
            <.card_title>{label}</.card_title>
            <.card_description>{what}</.card_description>
          </.card_body>
        </.card>
      </.section_nav>
    </div>
    """)
  end

  defp section_select_code do
    assigns = %{sections: sections("pick-"), nav: nav_sections("pick-")}

    code(~H"""
    <div class="h-[32rem] w-full overflow-y-auto rounded-xl border border-border p-4">
      <!-- The box stands in for the window; the pinned div stands in for the page header. -->
      <div
        data-sticky-top
        class="sticky -top-4 z-10 -mx-4 -mt-4 mb-4 space-y-3 border-b border-border bg-base-100 p-4"
      >
        <p class="text-base font-semibold">Edit order</p>
        <p class="hidden text-sm text-muted-foreground lg:block">
          The select shows below 1024px wide: narrow the window to see it.
        </p>
        <.section_nav id="pick-sections" sections={@nav} variant="select" />
      </div>
      <div class="flex flex-col gap-6">
        <.card :for={{id, label, _group, what} <- @sections} id={id}>
          <.card_body>
            <.card_title>{label}</.card_title>
            <.card_description>{what}</.card_description>
          </.card_body>
        </.card>
      </div>
    </div>
    """)
  end

  # ---------------------------------------------------------------------------
  # Time field
  # ---------------------------------------------------------------------------

  defp time_field do
    %{
      slug: "time-field",
      title: "Time Field",
      description:
        "A labelled time picker bound to a form field: the label above, the picker full width, the field's errors under it.",
      hook: true,
      guidance: %{
        use_when: [
          "A time of day in a form backed by a changeset (opening hours, a delivery window)",
          "Pairs such as Opens / Closes, side by side from sm"
        ],
        avoid_when: [
          "A time outside a form (a filter, a toolbar) - use <.time_picker> with aria-label",
          "Durations - use a number input or a select of lengths",
          "Date and time together - a date picker and a time field side by side"
        ],
        sizing:
          "A column: text-sm medium label, 8px, the full-width h-9 picker (44px on touch), then any error. Fields 16px apart, like the rest of the form.",
        responsive:
          "Full width of its column; pairs go in a grid that stacks on phones (grid gap-4 sm:grid-cols-2).",
        ios:
          "DatePicker(\"Opens\", selection:, displayedComponents: .hourAndMinute) in a Form row."
      },
      props: [
        %{name: "id", type: "string (required)", default: "-"},
        %{name: "field", type: "Phoenix.HTML.FormField (required)", default: "-"},
        %{name: "label", type: "string (required)", default: "-"},
        %{name: "minute_step", type: "integer", default: "15"},
        %{name: "hour_cycle", type: "12 | 24", default: "12"},
        %{name: "placeholder", type: "string", default: ~s("Not set")},
        %{name: "disabled", type: "boolean", default: "false"},
        %{name: "class", type: "any", default: "nil"}
      ],
      notes:
        "Posts a 24-hour HH:MM, which an Ecto :time field casts. Errors show under the picker once the field was used or the form submitted (Phoenix's used_input?/1), translated like <.input>'s. The label points at the picker's trigger (the field's id), so clicking it opens the picker and screen readers name it. Needs the ShadcnTimePicker hook. The record page on the dev server (`/lab/data-table/:id`) validates a delivery window with two of them.",
      specs: %{
        anatomy: [
          %{part: "Label", description: "label for the trigger: text-sm, 500."},
          %{
            part: "Picker",
            description: "<.time_picker full_width>: trigger, popover of columns, hidden input."
          },
          %{part: "Error", description: "<.error> per message, under the picker."}
        ],
        measurements: [
          %{property: "Gap", value: "0.5rem between label, picker and error"},
          %{
            property: "Trigger",
            value: "full width, 2.25rem (2.75rem on touch), var(--radius-md)"
          },
          %{property: "Minute step", value: "15 by default"}
        ],
        tokens: [
          "foreground",
          "input",
          "border-color",
          "popover",
          "primary",
          "destructive",
          "ring"
        ]
      },
      accessibility: %{
        roles:
          "A label for the trigger button (aria-haspopup=dialog); the popover holds a role=listbox per column (Hours, Minutes, AM/PM). An invalid field marks the trigger aria-invalid.",
        keyboard: [
          %{keys: "Enter / Space", action: "Open the picker; focus moves to the hours"},
          %{keys: "Up / Down", action: "Previous / next value in the column"},
          %{keys: "Left / Right / Tab", action: "Move between columns"},
          %{keys: "Enter / Esc", action: "Close and return focus to the trigger"}
        ],
        focus: "The 3px ring on the trigger; the field's error doesn't take focus.",
        screen_reader:
          "The trigger reads the label and the time (\"Opens, 9:00 AM\"), or \"Not set\"; the error text follows it.",
        touch_target: "The trigger and options are 44px tall on touch.",
        reduced_motion: "The popover toggles without movement."
      },
      swiftui: %{
        code: ~S"""
        Form {
            DatePicker("Opens", selection: $opens, displayedComponents: .hourAndMinute)
            DatePicker("Closes", selection: $closes, displayedComponents: .hourAndMinute)
            if closes <= opens {
                Text("Closes must be after it opens").font(.footnote).foregroundStyle(.red)
            }
        }
        """,
        notes:
          "A DatePicker row in a Form is the native labelled time field; show validation as footnote text under it. SwiftUI has no minute step; wrap UIDatePicker (minuteInterval = 15) when you need one."
      },
      ios_status: :partial,
      examples: [
        %{
          title: "Bound to a form field",
          heex: ~S"""
          <%!-- @form = to_form(%{"opens" => "09:00"}, as: :store) --%>
          <.form for={@form} id="store-form" phx-change="validate">
            <.time_field id="opens" field={@form[:opens]} label="Opens" />
          </.form>
          """,
          code: time_field_code()
        },
        %{
          title: "With an error",
          heex: ~S"""
          <.form for={@form} id="window-form" phx-change="validate">
            <div class="grid gap-4 sm:grid-cols-2">
              <.time_field id="window-opens" field={@form[:opens]} label="Opens" />
              <.time_field id="window-closes" field={@form[:closes]} label="Closes" />
            </div>
          </.form>

          def handle_event("validate", %{"window" => params}, socket) do
            {:noreply, assign(socket, form: to_form(params, as: :window, errors: errors(params), action: :validate))}
          end
          """,
          code: time_field_error_code()
        }
      ]
    }
  end

  defp time_field_code do
    assigns = %{form: to_form(%{"opens" => "09:00"}, as: :store)}

    code(~H"""
    <div class="w-full max-w-xs">
      <.time_field id="opens" field={@form[:opens]} label="Opens" />
    </div>
    """)
  end

  defp time_field_error_code do
    form =
      to_form(%{"opens" => "09:00", "closes" => "08:30"},
        as: :window,
        errors: [closes: {"must be after it opens", []}],
        action: :validate
      )

    assigns = %{form: form}

    code(~H"""
    <div class="grid w-full max-w-md gap-4 sm:grid-cols-2">
      <.time_field id="window-opens" field={@form[:opens]} label="Opens" />
      <.time_field id="window-closes" field={@form[:closes]} label="Closes" />
    </div>
    """)
  end

  # ---------------------------------------------------------------------------
  # Examples for existing catalog pages (dialog, table)
  # ---------------------------------------------------------------------------

  @doc "The dialog page's \"Open from the server\" example."
  def dialog_from_server_example do
    assigns = %{}

    %{
      title: "Open from the server",
      heex: ~S"""
      <%!-- a decision the server makes: unsaved changes ask first --%>
      def handle_event("cancel", _params, socket) do
        if socket.assigns.dirty?,
          do: {:noreply, push_show_modal(socket, "discard")},
          else: {:noreply, push_navigate(socket, to: ~p"/orders")}
      end

      <.dialog id="discard">
        <:title>Discard your changes?</:title>
        <:description>Your edits to #1042 haven't been saved.</:description>
        <:actions>
          <.button variant="outline" phx-click={hide_modal("discard")}>Keep editing</.button>
          <.button variant="destructive" phx-click="discard">Discard</.button>
        </:actions>
      </.dialog>

      <%!-- or open while an assign is true; on_close turns it back off --%>
      <.dialog id="delete-order" show={@confirm?} on_close="keep_editing">…</.dialog>

      def handle_event("keep_editing", _params, socket), do: {:noreply, assign(socket, confirm?: false)}
      """,
      code:
        code(~H"""
        <.button variant="outline" phx-click={show_modal("discard")}>Cancel</.button>
        <.dialog id="discard" on_close="keep_editing">
          <:title>Discard your changes?</:title>
          <:description>Your edits to #1042 haven't been saved.</:description>
          <:actions>
            <.button variant="outline" phx-click={hide_modal("discard")}>Keep editing</.button>
            <.button variant="destructive" phx-click="discard">Discard</.button>
          </:actions>
        </.dialog>
        """)
    }
  end

  @doc "The table page's \"Scrolling body\" example (`<.table scroll>`)."
  def table_scroll_example do
    invoices =
      for {n, status, method, amount} <- [
            {1, "Paid", "Credit Card", "$250.00"},
            {2, "Pending", "Bank Transfer", "$150.00"},
            {3, "Unpaid", "Bank Transfer", "$350.00"},
            {4, "Paid", "Credit Card", "$450.00"},
            {5, "Paid", "Credit Card", "$550.00"},
            {6, "Pending", "Bank Transfer", "$200.00"},
            {7, "Unpaid", "Credit Card", "$300.00"},
            {8, "Paid", "Bank Transfer", "$125.00"},
            {9, "Paid", "Credit Card", "$725.00"},
            {10, "Pending", "Credit Card", "$90.00"}
          ] do
        %{
          id: "INV#{String.pad_leading(Integer.to_string(n), 3, "0")}",
          status: status,
          method: method,
          amount: amount
        }
      end

    assigns = %{invoices: invoices}

    %{
      title: "Scrolling body",
      center: false,
      heex: ~S"""
      <%!-- in an <.app_shell fill> page the card grows to fill the window --%>
      <div class="card flex min-h-0 flex-1 flex-col overflow-hidden">
        <.table id="invoices" rows={@invoices} scroll>
          <:col :let={invoice} label="Invoice">{invoice.id}</:col>
          <:col :let={invoice} label="Status">{invoice.status}</:col>
          <:col :let={invoice} label="Method">{invoice.method}</:col>
          <:col :let={invoice} label="Amount">{invoice.amount}</:col>
        </.table>
      </div>
      """,
      code:
        code(~H"""
        <div class="card flex h-72 min-h-0 flex-col overflow-hidden">
          <.table id="invoices-scroll" rows={@invoices} scroll>
            <:col :let={invoice} label="Invoice">{invoice.id}</:col>
            <:col :let={invoice} label="Status">{invoice.status}</:col>
            <:col :let={invoice} label="Method">{invoice.method}</:col>
            <:col :let={invoice} label="Amount">{invoice.amount}</:col>
          </.table>
        </div>
        """)
    }
  end

  # ---------------------------------------------------------------------------
  # Dropzone
  # ---------------------------------------------------------------------------

  defp dropzone do
    %{
      slug: "dropzone",
      title: "Dropzone",
      description:
        "A file picker people can also drop files on: a dashed area that opens the picker on a click or tap, with picked files as attachment tiles under it.",
      hook: true,
      guidance: %{
        use_when: [
          "Every file upload in a form: an import, attachments, a logo or avatar",
          "Tight forms: size=\"compact\", one input-height row"
        ],
        avoid_when: [
          "Showing files already attached - render them as <.attachment> tiles, without a picker",
          "A bare live_file_input or a hand-rolled drop area - this is the one file picker",
          "Pasting images into a message composer - handle paste on the composer itself"
        ],
        sizing:
          "Default: at least 8rem tall, 24px padding, rounded-lg, a 32px muted icon box, a text-sm medium title and one text-xs muted line. Compact: h-9 like an input (44px on touch), the description under it in text-sm muted. Tiles are full width, 8px apart.",
        responsive:
          "Full width of the form column at every width. Touch screens can't drag, so the title reads \"Choose a file\" there and the compact row grows to 44px.",
        ios:
          ".fileImporter(isPresented:allowedContentTypes:allowsMultipleSelection:) behind a bordered button (or PhotosPicker for photos), plus .dropDestination(for: URL.self) for drag and drop on iPad; picked files are attachment rows below it."
      },
      props: [
        %{name: "id", type: "string (required)", default: "-"},
        %{name: "upload", type: "Phoenix.LiveView.UploadConfig", default: "nil"},
        %{
          name: "name / accept / multiple",
          type: "plain form (instead of upload)",
          default: "nil"
        },
        %{name: "size", type: "default | compact", default: "default"},
        %{name: "disabled", type: "boolean", default: "false"},
        %{name: "on_cancel", type: "event | JS (pushes %{\"ref\" => ref})", default: "nil"},
        %{name: "target", type: "phx-target for on_cancel", default: "nil"},
        %{name: "error_text", type: "fn error -> text | nil end", default: "nil"},
        %{name: ":title touch", type: "slot + touch-screen wording", default: "from the upload"},
        %{name: ":description", type: "slot", default: "types, size limit, count"},
        %{name: ":entry", type: "slot (:let={entry})", default: "attachment tile"}
      ],
      notes:
        "The zone is the upload's phx-drop-target: a <label> around the visually hidden live_file_input, so a click, a tap, Enter or Space opens the picker - no inline JS. Without slots the title and the description come from the upload (\"One .csv file, up to 1 MB.\"). Each entry is an <.attachment>: uploading with its progress, done, or an error with the reason; on_cancel adds a remove button. Errors for the whole upload (too many files) show under the zone. The ShadcnDropzone hook highlights the zone while files are over it on every LiveView version, and takes a plain form's drops (name instead of upload).",
      specs: %{
        anatomy: [
          %{
            part: "Zone",
            description: "Dashed rounded-lg label; the drop target and the picker."
          },
          %{part: "Icon", description: "hero-arrow-up-tray in a 32px muted box."},
          %{part: "Title", description: "text-sm medium: what to drop or choose."},
          %{part: "Description", description: "text-xs muted: types, size limit, how many."},
          %{part: "Errors", description: "text-sm destructive lines under the zone."},
          %{part: "Entries", description: "One full-width attachment tile per file."}
        ],
        measurements: [
          %{property: "Zone", value: "min-height 8rem, 1.5rem padding, var(--radius-lg)"},
          %{
            property: "Border",
            value: "1px dashed var(--border-color); var(--primary) while dragging"
          },
          %{property: "Drag fill", value: "var(--accent), 150ms (none with reduced motion)"},
          %{property: "Icon box", value: "2rem, var(--muted), var(--radius-md), 1rem glyph"},
          %{property: "Compact", value: "2.25rem row (2.75rem on touch), var(--radius-md)"},
          %{
            property: "Focus ring",
            value: "0 0 0 3px var(--ring) @ 50% while the input has :focus-visible"
          }
        ],
        tokens: [
          "border-color",
          "primary",
          "accent",
          "muted",
          "muted-foreground",
          "input",
          "ring",
          "destructive"
        ]
      },
      accessibility: %{
        roles:
          "A native file input, visually hidden inside the zone's <label>: the label's title names it, aria-describedby reads the description and the errors, aria-invalid marks a rejected file. Picked files are a list.",
        keyboard: [
          %{keys: "Tab", action: "Focus the zone (its input); the ring shows"},
          %{keys: "Enter / Space", action: "Open the file picker"},
          %{keys: "Tab", action: "Move on to each file's remove button"}
        ],
        focus:
          "The 3px ring is drawn on the zone while its input has :focus-visible (:has), so a mouse click doesn't leave it lit.",
        screen_reader:
          "The input announces its title, then the description and any errors. Upload errors are in a polite live region; each file's tile names it and its state.",
        touch_target:
          "The whole zone is the target; compact grows to 44px on touch. Touch screens can't drag, so the title says \"Choose a file\".",
        reduced_motion: "The 150ms border and fill change is dropped."
      },
      swiftui: %{
        code: ~S"""
        @State private var importing = false
        @State private var files: [URL] = []

        Button("Choose a CSV file", systemImage: "square.and.arrow.up") { importing = true }
            .buttonStyle(.bordered)
            .fileImporter(isPresented: $importing, allowedContentTypes: [.commaSeparatedText]) { result in
                if case .success(let url) = result { files = [url] }
            }
            .dropDestination(for: URL.self) { urls, _ in
                files = Array(urls.prefix(1))
                return !urls.isEmpty
            }

        ForEach(files, id: \.self) { url in
            AttachmentRow(name: url.lastPathComponent, size: url.fileSize, progress: upload.progress[url])
        }
        """,
        notes:
          "iPhone has no drag between apps: the picker button is the control and .dropDestination only adds iPad drag and drop. Show each picked file as a row (icon, name, size, a ProgressView while it uploads, a remove button), as <.attachment> does."
      },
      ios_status: :partial,
      examples: [
        %{
          title: "Default",
          heex: ~S"""
          <.dropzone id="import-file" upload={@uploads.people_csv} on_cancel="import:cancel">
            <:title touch="Choose a CSV file">Drop a CSV file here, or choose one</:title>
            <:description>One .csv file, up to 1 MB.</:description>
          </.dropzone>
          """,
          code: dropzone_default_code()
        },
        %{
          title: "Compact",
          heex: ~S"""
          <label for={@uploads.logo.ref} class="text-sm font-medium">Logo</label>
          <.dropzone id="logo" upload={@uploads.logo} size="compact" on_cancel="cancel-upload" />
          """,
          code: dropzone_compact_code()
        },
        %{
          title: "Multiple, uploading",
          heex: ~S"""
          <%!-- allow_upload(:files, accept: ~w(image/* .pdf), max_entries: 5, auto_upload: true) --%>
          <.dropzone id="attachments" upload={@uploads.files} on_cancel="cancel-upload" />

          def handle_event("cancel-upload", %{"ref" => ref}, socket),
            do: {:noreply, cancel_upload(socket, :files, ref)}
          """,
          code: dropzone_entries_code()
        },
        %{
          title: "Errors",
          heex: ~S"""
          <.dropzone
            id="import-file"
            upload={@uploads.people_csv}
            on_cancel="import:cancel"
            error_text={fn
              :not_accepted -> "That isn't a CSV file. Export the sheet as .csv first."
              _ -> nil
            end}
          />
          """,
          code: dropzone_errors_code()
        },
        %{
          title: "Disabled",
          heex: ~S"""
          <.dropzone id="import-file" upload={@uploads.people_csv} disabled />
          """,
          code: dropzone_disabled_code()
        },
        %{
          title: "Plain form",
          heex: ~S"""
          <form action={~p"/documents"} method="post" enctype="multipart/form-data">
            <.dropzone id="documents" name="documents" accept=".pdf,.txt" multiple />
          </form>
          """,
          code: dropzone_plain_code()
        }
      ]
    }
  end

  defp dropzone_default_code do
    assigns = %{}

    dropzone_code(~H"""
    <.dropzone id="import-file-demo" name="people_csv" accept=".csv" class="w-full max-w-md">
      <:title touch="Choose a CSV file">Drop a CSV file here, or choose one</:title>
      <:description>One .csv file, up to 1 MB.</:description>
    </.dropzone>
    """)
  end

  defp dropzone_compact_code do
    assigns = %{}

    dropzone_code(~H"""
    <div class="grid w-full max-w-sm gap-2">
      <label for="logo-demo-input" class="text-sm font-medium">Logo</label>
      <.dropzone id="logo-demo" name="logo" accept=".png,.svg" size="compact">
        <:description>One .png or .svg file, up to 500 KB.</:description>
      </.dropzone>
    </div>
    """)
  end

  defp dropzone_entries_code do
    entries = [
      demo_entry("0", "inspection-report.pdf", 2_400_000, done?: true, progress: 100),
      demo_entry("1", "roof-measurements.pdf", 5_100_000, progress: 64, preflighted?: true),
      demo_entry("2", "permit-scan.pdf", 820_000, progress: 12, preflighted?: true)
    ]

    assigns = %{
      upload: demo_upload(:files, ~w(image/* .pdf), 5, 8_000_000, entries, [], true)
    }

    dropzone_code(~H"""
    <.dropzone
      id="attachments-demo"
      upload={@upload}
      on_cancel="cancel-upload"
      class="w-full max-w-md"
    />
    """)
  end

  defp dropzone_errors_code do
    entries = [
      demo_entry("0", "people.xlsx", 48_000, client_type: "application/vnd.ms-excel"),
      demo_entry("1", "people-2019-2026.csv", 3_400_000)
    ]

    errors = [{"0", :not_accepted}, {"1", :too_large}, {"phx-demo-people_csv", :too_many_files}]

    assigns = %{upload: demo_upload(:people_csv, ~w(.csv), 1, 1_000_000, entries, errors, false)}

    dropzone_code(~H"""
    <.dropzone
      id="import-errors-demo"
      upload={@upload}
      on_cancel="import:cancel"
      class="w-full max-w-md"
      error_text={
        fn
          :not_accepted -> "That isn't a CSV file. Export the sheet as .csv first."
          _ -> nil
        end
      }
    />
    """)
  end

  defp dropzone_disabled_code do
    assigns = %{}

    dropzone_code(~H"""
    <.dropzone
      id="import-disabled-demo"
      name="people_csv"
      accept=".csv"
      disabled
      class="w-full max-w-md"
    >
      <:description>One .csv file, up to 1 MB.</:description>
    </.dropzone>
    """)
  end

  defp dropzone_plain_code do
    assigns = %{}

    dropzone_code(~H"""
    <form action="#" class="w-full max-w-md">
      <.dropzone id="documents-demo" name="documents" accept=".pdf,.txt" multiple />
    </form>
    """)
  end

  defp demo_upload(name, accept, max_entries, max_file_size, entries, errors, auto_upload?) do
    %Phoenix.LiveView.UploadConfig{
      name: name,
      ref: "phx-demo-#{name}",
      accept: Enum.join(accept, ","),
      max_entries: max_entries,
      max_file_size: max_file_size,
      entries: entries,
      errors: errors,
      auto_upload?: auto_upload?
    }
  end

  defp demo_entry(ref, name, size, opts \\ []) do
    struct!(
      Phoenix.LiveView.UploadEntry,
      [
        ref: ref,
        upload_ref: "phx-demo",
        client_name: name,
        client_size: size,
        client_type: if(String.ends_with?(name, ".pdf"), do: "application/pdf", else: "text/csv"),
        valid?: true
      ] ++ opts
    )
  end

  # A LiveView upload's markup, as a snapshot: the live_file_input's LiveView
  # wiring (its hook, refs and the drop target) is dropped from the HTML tab.
  defp dropzone_code(rendered) do
    rendered
    |> code()
    |> String.replace(~r/ (?:data-phx-[a-z-]+|phx-drop-target)="[^"]*"/, "")
  end
end
