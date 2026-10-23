# Data Table

A list page's table: the body scrolls under a header that stays put, columns sort, rows open the record, and ticked rows get a bulk bar.

> Requires a JS hook: initialize with `initShadcnDaisyui()` (dead views) or the corresponding `Shadcn*` LiveView hook from `shadcn-daisyui.js`.

Server-driven: each action sends an event and the LiveView answers with new assigns; the ShadcnDataTable hook only keeps checkboxes, scroll position and loading in step. On this static page only the client-side parts run (the sticky header, row focus and keys, ticking a checkbox); the full list page runs on the dev server (`/lab/data-table`).

Events (each payload also carries "table" => the component's id): dt:sort %{"key"} from a sortable header; dt:open %{"id"} from a row (click or Enter); dt:select %{"id", "shift"} from a row's checkbox; dt:select_all from the header checkbox; dt:select_matching from "Select all M rows"; dt:clear from Clear; dt:more when the end comes within ~200px (with more, once until the reply).

State: keep sort, search and filters in a ShadcnDaisyui.DataTable.State - State.from_params/2 in handle_params, State.toggle_sort/2 on dt:sort, State.select/4, select_all/2, keep_visible/2 and clear/1 for the ticks, State.run/3 to search, filter and sort in memory, State.to_params/2 for push_patch. Ticks live on the page, never in the URL.

Scrolling: a new sort, search or filter starts the body at the top; scroll_key keeps the body's scroll position in sessionStorage, so coming back to the list lands where the person left off; active_id highlights the row last opened and scrolls it into view. edge: on phones the table runs edge to edge (no side borders or rounding).

Alignment: the rightmost column shown at each width is right-aligned, header and cells, unless align="left"; the first column never is.

Layout: put the toolbar and table in an <.app_shell fill> page (or any flex column that fills the window) so the table takes the space left and only its body scrolls. These previews use a fixed-height flex column instead.

## Usage guidance

Use when:

- A list page where the table is the page: orders, customers, invoices
- Rows that open a record, with sorting, search and filters kept in the URL
- Bulk actions on ticked rows (mark paid, export, assign)

Don't use for:

- A handful of static rows - use <.table>, or <.table scroll> for a long one
- A record's own rows (activity, line items) - use <.table_card>
- Rows people edit in place - open the record instead

Sizing: A card that fills the space left: a 40px sticky header, text-sm rows with 10px vertical padding, a 44px checkbox column. table-fixed: give columns a width class (w-24, w-32) and let one column take the rest; cells truncate with …. The bulk bar is the header's height and covers the column labels, so rows never move.

Responsive: Hide columns with hide_below (sm 40rem, md 48rem, lg 64rem, xl 80rem); the rightmost column shown is right-aligned at every width. Ticking is a desktop job: the checkbox column and bulk bar show from md. edge puts the table edge to edge on phones. Never scroll sideways.

iOS: Table with selection and sortOrder on iPad / Mac; on iPhone a List of rows with NavigationLink, EditButton for selection and .searchable above it.

## Specs

| Part | Description |
| --- | --- |
| Card | .card.data-table: a flex column that takes the space left in its parent (flex-1, min-h-0). |
| Body | .data-table-scroll: the one scroll region, vertical only. |
| Header | Sticky th cells on the card fill with an inset 1px line. A sortable column is a button with an arrow (shown on hover/focus, solid when sorted) and aria-sort. |
| Checkbox column | With selectable, from md: the header box ticks every loaded row. |
| Row | Focusable, opens the record. Hover tint, ticked rows bg-muted, the row last opened bg-accent with a 2px primary mark at its start. |
| Bulk bar | While rows are ticked it covers the column labels: N selected, Select all M rows, :bulk, Clear. |
| Empty | No rows: <.empty variant="plain"> under the header, not as a row. |
| Loading | With more: a spinner row and the sentinel above it. |

| Property | Value |
| --- | --- |
| Header height | 2.5rem / 40px, sticky, z-10 |
| Cells | text-sm, 1rem inline / 0.625rem block padding, truncate |
| Checkbox column | 2.75rem / 44px (from 48rem) |
| Bulk bar | the header's height, from the checkbox column to the end |
| Sort arrow | 0.875rem, outside the label (before it on end-aligned columns) |
| Active row mark | 2px var(--primary) inset at the row's start |
| Load-more sentinel | 12.5rem / 200px above the spinner |

Tokens used: `card`, `card-foreground`, `border-color`, `muted`, `muted-foreground`, `accent`, `primary`, `foreground`, `ring`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Reach the header buttons, then each row |
| Up / Down | Move to the previous / next row (keeps it under the header) |
| Enter | Open the focused row (dt:open) |
| Cmd/Ctrl + Enter | Open row_href in a new tab |
| Space | Tick the focused row (from md); Shift+Space ticks a range |
| Enter / Space on a header | Sort by that column (dt:sort) |

Role / ARIA: A real <table> (thead / tbody / th scope=col). Sortable headers hold a button and carry aria-sort (ascending, descending, none). Row checkboxes are labelled "Select" plus the row's first cell; the header box is "Select all orders". The bulk count is aria-live=polite.

Focus: Rows take focus (tabindex=0) with a 2px ring inside the row; a click on a link, button, input or label inside a row (or anything with data-row-ignore) doesn't open it, nor does a click that ends with text selected.

Screen reader: aria-sort announces the sorted column and direction; the bulk bar announces "N selected" as it changes; the loading row reads "Loading more orders".

Touch target: Rows are full-width tap targets; on phones there is no checkbox column (ticking is a desktop job). Bulk buttons are size="sm" on a pointer-first surface.

Reduced motion: Only the 150ms row hover tint transitions; scrolling a row into view is instant.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
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
```

Table covers sortable columns, selection and opening a row on iPad and Mac. On iPhone it shows only its first column, so use a List of rows (NavigationLink to the record, EditButton for selection) and load more from the last row's onAppear.

## Props

| Name | Type | Default |
| --- | --- | --- |
| id | string (required) | - |
| rows | list (required) | - |
| row_id | fn row -> id | row.id |
| row_href | fn row -> path | nil (Cmd/Ctrl-click, middle click) |
| state | ShadcnDaisyui.DataTable.State | nil (sort + ticked rows) |
| selectable | boolean | false |
| more | boolean | false (sends dt:more near the end) |
| matching / all_matching | integer / boolean | nil / false |
| noun | {singular, plural} | {"row", "rows"} |
| active_id | any | nil (the row last opened) |
| scroll_key | string | nil |
| edge | boolean | false |
| target | phx-target | nil |
| :col label sort class align hide_below | slot | - |
| :bulk | slot (size="sm" buttons) | - |
| :empty title icon / :empty_action | slots | "No rows" |

## Default

HEEx:

```heex
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
```

```html
<div class="flex h-80 flex-col">
  <div id="orders" data-data-table data-selectable data-view="125791295" class="card data-table">
    <div class="data-table-scroll" data-dt-scroll>
      <table class="table data-table-table">
        <thead>
          <tr>
            <th scope="col" class="data-table-check">
              <input type="checkbox" class="checkbox" aria-label="Select all orders" data-dt-select-all phx-click="[[&quot;push&quot;,{&quot;value&quot;:{&quot;table&quot;:&quot;orders&quot;},&quot;event&quot;:&quot;dt:select_all&quot;}]]">
            </th>
            <th scope="col" class="w-24 font-medium" aria-sort="none">
              <button type="button" class="data-table-sort" phx-click="[[&quot;push&quot;,{&quot;value&quot;:{&quot;table&quot;:&quot;orders&quot;,&quot;key&quot;:&quot;number&quot;},&quot;event&quot;:&quot;dt:sort&quot;}]]">
                <span class="data-table-sort-label">Order</span>
                <span class="data-table-sort-icon hero-chevron-up-down" aria-hidden="true"></span>
              </button>
            </th>
            <th scope="col" aria-sort="none">
              <button type="button" class="data-table-sort" phx-click="[[&quot;push&quot;,{&quot;value&quot;:{&quot;table&quot;:&quot;orders&quot;,&quot;key&quot;:&quot;customer&quot;},&quot;event&quot;:&quot;dt:sort&quot;}]]">
                <span class="data-table-sort-label">Customer</span>
                <span class="data-table-sort-icon hero-chevron-up-down" aria-hidden="true"></span>
              </button>
            </th>
            <th scope="col" class="w-36" data-hide-below="lg">
              <span class="data-table-label">Owner</span>
            </th>
            <th scope="col" class="w-28" data-hide-below="sm">
              <span class="data-table-label">Status</span>
            </th>
            <th scope="col" class="w-32" data-hide-below="md" aria-sort="descending">
              <button type="button" class="data-table-sort" data-sorted="desc" phx-click="[[&quot;push&quot;,{&quot;value&quot;:{&quot;table&quot;:&quot;orders&quot;,&quot;key&quot;:&quot;placed&quot;},&quot;event&quot;:&quot;dt:sort&quot;}]]">
                <span class="data-table-sort-label">Placed</span>
                <span class="data-table-sort-icon hero-arrow-down" aria-hidden="true"></span>
              </button>
            </th>
            <th scope="col" class="w-28 tabular-nums" data-end="base sm md lg xl" aria-sort="none">
              <button type="button" class="data-table-sort" phx-click="[[&quot;push&quot;,{&quot;value&quot;:{&quot;table&quot;:&quot;orders&quot;,&quot;key&quot;:&quot;total&quot;},&quot;event&quot;:&quot;dt:sort&quot;}]]">
                <span class="data-table-sort-label">Total</span>
                <span class="data-table-sort-icon hero-chevron-up-down" aria-hidden="true"></span>
              </button>
            </th>
          </tr>
        </thead>
        <tbody>
          <tr id="orders-row-1042" tabindex="0" data-dt-row data-id="1042" data-href="/orders/1042">
            <td class="data-table-check">
              <input type="checkbox" id="orders-row-1042-check" class="checkbox" aria-label="Select" aria-labelledby="orders-row-1042-check orders-row-1042-c0" data-dt-select>
            </td>
            <td id="orders-row-1042-c0" class="w-24 font-medium">
              #1042
            </td>
            <td>
              Blue Harbor Inn
            </td>
            <td class="w-36" data-hide-below="lg">
              Pat Lee
            </td>
            <td class="w-28" data-hide-below="sm">
              <span class="badge badge-secondary">Paid</span>
            </td>
            <td class="w-32" data-hide-below="md">
              Oct 21, 2026
            </td>
            <td class="w-28 tabular-nums" data-end="base sm md lg xl">
              $1,240.00
            </td>
          </tr>
          <tr id="orders-row-1041" tabindex="0" data-dt-row data-id="1041" data-href="/orders/1041">
            <td class="data-table-check">
              <input type="checkbox" id="orders-row-1041-check" class="checkbox" aria-label="Select" aria-labelledby="orders-row-1041-check orders-row-1041-c0" data-dt-select>
            </td>
            <td id="orders-row-1041-c0" class="w-24 font-medium">
              #1041
            </td>
            <td>
              Maple &amp; Co.
            </td>
            <td class="w-36" data-hide-below="lg">
              Sam Okafor
            </td>
            <td class="w-28" data-hide-below="sm">
              <span class="badge badge-outline">Open</span>
            </td>
            <td class="w-32" data-hide-below="md">
              Oct 20, 2026
            </td>
            <td class="w-28 tabular-nums" data-end="base sm md lg xl">
              $318.50
            </td>
          </tr>
          <tr id="orders-row-1040" tabindex="0" data-dt-row data-id="1040" data-href="/orders/1040">
            <td class="data-table-check">
              <input type="checkbox" id="orders-row-1040-check" class="checkbox" aria-label="Select" aria-labelledby="orders-row-1040-check orders-row-1040-c0" data-dt-select>
            </td>
            <td id="orders-row-1040-c0" class="w-24 font-medium">
              #1040
            </td>
            <td>
              Summit Outfitters
            </td>
            <td class="w-36" data-hide-below="lg">
              Jordan Diaz
            </td>
            <td class="w-28" data-hide-below="sm">
              <span class="badge badge-error">Overdue</span>
            </td>
            <td class="w-32" data-hide-below="md">
              Oct 18, 2026
            </td>
            <td class="w-28 tabular-nums" data-end="base sm md lg xl">
              $2,075.00
            </td>
          </tr>
          <tr id="orders-row-1039" tabindex="0" data-dt-row data-id="1039" data-href="/orders/1039">
            <td class="data-table-check">
              <input type="checkbox" id="orders-row-1039-check" class="checkbox" aria-label="Select" aria-labelledby="orders-row-1039-check orders-row-1039-c0" data-dt-select>
            </td>
            <td id="orders-row-1039-c0" class="w-24 font-medium">
              #1039
            </td>
            <td>
              Lakeside Clinic
            </td>
            <td class="w-36" data-hide-below="lg">
              Riley Chen
            </td>
            <td class="w-28" data-hide-below="sm">
              <span class="badge badge-secondary">Paid</span>
            </td>
            <td class="w-32" data-hide-below="md">
              Oct 17, 2026
            </td>
            <td class="w-28 tabular-nums" data-end="base sm md lg xl">
              $96.40
            </td>
          </tr>
          <tr id="orders-row-1038" tabindex="0" data-dt-row data-id="1038" data-href="/orders/1038">
            <td class="data-table-check">
              <input type="checkbox" id="orders-row-1038-check" class="checkbox" aria-label="Select" aria-labelledby="orders-row-1038-check orders-row-1038-c0" data-dt-select>
            </td>
            <td id="orders-row-1038-c0" class="w-24 font-medium">
              #1038
            </td>
            <td>
              Copper Kettle
            </td>
            <td class="w-36" data-hide-below="lg">
              Pat Lee
            </td>
            <td class="w-28" data-hide-below="sm">
              <span class="badge badge-outline">Open</span>
            </td>
            <td class="w-32" data-hide-below="md">
              Oct 15, 2026
            </td>
            <td class="w-28 tabular-nums" data-end="base sm md lg xl">
              $742.10
            </td>
          </tr>
          <tr id="orders-row-1037" tabindex="0" data-dt-row data-id="1037" data-href="/orders/1037">
            <td class="data-table-check">
              <input type="checkbox" id="orders-row-1037-check" class="checkbox" aria-label="Select" aria-labelledby="orders-row-1037-check orders-row-1037-c0" data-dt-select>
            </td>
            <td id="orders-row-1037-c0" class="w-24 font-medium">
              #1037
            </td>
            <td>
              Granite Works
            </td>
            <td class="w-36" data-hide-below="lg">
              Sam Okafor
            </td>
            <td class="w-28" data-hide-below="sm">
              <span class="badge badge-outline">Refunded</span>
            </td>
            <td class="w-32" data-hide-below="md">
              Oct 14, 2026
            </td>
            <td class="w-28 tabular-nums" data-end="base sm md lg xl">
              $1,180.00
            </td>
          </tr>
          <tr id="orders-row-1036" tabindex="0" data-dt-row data-id="1036" data-href="/orders/1036">
            <td class="data-table-check">
              <input type="checkbox" id="orders-row-1036-check" class="checkbox" aria-label="Select" aria-labelledby="orders-row-1036-check orders-row-1036-c0" data-dt-select>
            </td>
            <td id="orders-row-1036-c0" class="w-24 font-medium">
              #1036
            </td>
            <td>
              Orchard Lane Grocers
            </td>
            <td class="w-36" data-hide-below="lg">
              Jordan Diaz
            </td>
            <td class="w-28" data-hide-below="sm">
              <span class="badge badge-secondary">Paid</span>
            </td>
            <td class="w-32" data-hide-below="md">
              Oct 12, 2026
            </td>
            <td class="w-28 tabular-nums" data-end="base sm md lg xl">
              $455.25
            </td>
          </tr>
          <tr id="orders-row-1035" tabindex="0" data-dt-row data-id="1035" data-href="/orders/1035">
            <td class="data-table-check">
              <input type="checkbox" id="orders-row-1035-check" class="checkbox" aria-label="Select" aria-labelledby="orders-row-1035-check orders-row-1035-c0" data-dt-select>
            </td>
            <td id="orders-row-1035-c0" class="w-24 font-medium">
              #1035
            </td>
            <td>
              Pine Street Bakery
            </td>
            <td class="w-36" data-hide-below="lg">
              Riley Chen
            </td>
            <td class="w-28" data-hide-below="sm">
              <span class="badge badge-secondary">Paid</span>
            </td>
            <td class="w-32" data-hide-below="md">
              Oct 11, 2026
            </td>
            <td class="w-28 tabular-nums" data-end="base sm md lg xl">
              $63.00
            </td>
          </tr>
          <tr id="orders-row-1034" tabindex="0" data-dt-row data-id="1034" data-href="/orders/1034">
            <td class="data-table-check">
              <input type="checkbox" id="orders-row-1034-check" class="checkbox" aria-label="Select" aria-labelledby="orders-row-1034-check orders-row-1034-c0" data-dt-select>
            </td>
            <td id="orders-row-1034-c0" class="w-24 font-medium">
              #1034
            </td>
            <td>
              Riverside Dental
            </td>
            <td class="w-36" data-hide-below="lg">
              Pat Lee
            </td>
            <td class="w-28" data-hide-below="sm">
              <span class="badge badge-error">Overdue</span>
            </td>
            <td class="w-32" data-hide-below="md">
              Oct 9, 2026
            </td>
            <td class="w-28 tabular-nums" data-end="base sm md lg xl">
              $1,512.80
            </td>
          </tr>
          <tr id="orders-row-1033" tabindex="0" data-dt-row data-id="1033" data-href="/orders/1033">
            <td class="data-table-check">
              <input type="checkbox" id="orders-row-1033-check" class="checkbox" aria-label="Select" aria-labelledby="orders-row-1033-check orders-row-1033-c0" data-dt-select>
            </td>
            <td id="orders-row-1033-c0" class="w-24 font-medium">
              #1033
            </td>
            <td>
              Hillcrest Motors
            </td>
            <td class="w-36" data-hide-below="lg">
              Sam Okafor
            </td>
            <td class="w-28" data-hide-below="sm">
              <span class="badge badge-outline">Open</span>
            </td>
            <td class="w-32" data-hide-below="md">
              Oct 8, 2026
            </td>
            <td class="w-28 tabular-nums" data-end="base sm md lg xl">
              $889.90
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    <div class="data-table-bulk" data-dt-bulk hidden>
      <span class="data-table-bulk-count" aria-live="polite">
        0 selected
      </span>
      <div class="data-table-bulk-actions">
        <button class="btn btn-outline btn-sm">
          Mark paid
        </button>
        <button class="btn btn-ghost btn-sm">
          Export
        </button>
      </div>
      <button type="button" class="btn btn-ghost btn-sm data-table-bulk-clear" data-dt-clear phx-click="[[&quot;push&quot;,{&quot;value&quot;:{&quot;table&quot;:&quot;orders&quot;},&quot;event&quot;:&quot;dt:clear&quot;}]]">
        Clear
      </button>
    </div>
  </div>
</div>
```

## Rows ticked

HEEx:

```heex
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
```

```html
<div class="flex h-80 flex-col">
  <div id="orders-ticked" data-data-table data-selectable data-ticked data-view="109651686" class="card data-table">
    <div class="data-table-scroll" data-dt-scroll>
      <table class="table data-table-table">
        <thead>
          <tr>
            <th scope="col" class="data-table-check">
              <input type="checkbox" class="checkbox" aria-label="Select all orders" checked data-dt-select-all phx-click="[[&quot;push&quot;,{&quot;value&quot;:{&quot;table&quot;:&quot;orders-ticked&quot;},&quot;event&quot;:&quot;dt:select_all&quot;}]]">
            </th>
            <th scope="col" class="w-24 font-medium" aria-sort="none">
              <button type="button" class="data-table-sort" phx-click="[[&quot;push&quot;,{&quot;value&quot;:{&quot;table&quot;:&quot;orders-ticked&quot;,&quot;key&quot;:&quot;number&quot;},&quot;event&quot;:&quot;dt:sort&quot;}]]">
                <span class="data-table-sort-label">Order</span>
                <span class="data-table-sort-icon hero-chevron-up-down" aria-hidden="true"></span>
              </button>
            </th>
            <th scope="col" aria-sort="none">
              <button type="button" class="data-table-sort" phx-click="[[&quot;push&quot;,{&quot;value&quot;:{&quot;table&quot;:&quot;orders-ticked&quot;,&quot;key&quot;:&quot;customer&quot;},&quot;event&quot;:&quot;dt:sort&quot;}]]">
                <span class="data-table-sort-label">Customer</span>
                <span class="data-table-sort-icon hero-chevron-up-down" aria-hidden="true"></span>
              </button>
            </th>
            <th scope="col" class="w-36" data-hide-below="lg">
              <span class="data-table-label">Owner</span>
            </th>
            <th scope="col" class="w-28" data-hide-below="sm">
              <span class="data-table-label">Status</span>
            </th>
            <th scope="col" class="w-32" data-hide-below="md" aria-sort="none">
              <button type="button" class="data-table-sort" phx-click="[[&quot;push&quot;,{&quot;value&quot;:{&quot;table&quot;:&quot;orders-ticked&quot;,&quot;key&quot;:&quot;placed&quot;},&quot;event&quot;:&quot;dt:sort&quot;}]]">
                <span class="data-table-sort-label">Placed</span>
                <span class="data-table-sort-icon hero-chevron-up-down" aria-hidden="true"></span>
              </button>
            </th>
            <th scope="col" class="w-28 tabular-nums" data-end="base sm md lg xl" aria-sort="none">
              <button type="button" class="data-table-sort" phx-click="[[&quot;push&quot;,{&quot;value&quot;:{&quot;table&quot;:&quot;orders-ticked&quot;,&quot;key&quot;:&quot;total&quot;},&quot;event&quot;:&quot;dt:sort&quot;}]]">
                <span class="data-table-sort-label">Total</span>
                <span class="data-table-sort-icon hero-chevron-up-down" aria-hidden="true"></span>
              </button>
            </th>
          </tr>
        </thead>
        <tbody>
          <tr id="orders-ticked-row-1042" tabindex="0" data-dt-row data-id="1042" data-href="/orders/1042" data-selected>
            <td class="data-table-check">
              <input type="checkbox" id="orders-ticked-row-1042-check" class="checkbox" aria-label="Select" aria-labelledby="orders-ticked-row-1042-check orders-ticked-row-1042-c0" checked data-dt-select>
            </td>
            <td id="orders-ticked-row-1042-c0" class="w-24 font-medium">
              #1042
            </td>
            <td>
              Blue Harbor Inn
            </td>
            <td class="w-36" data-hide-below="lg">
              Pat Lee
            </td>
            <td class="w-28" data-hide-below="sm">
              <span class="badge badge-secondary">Paid</span>
            </td>
            <td class="w-32" data-hide-below="md">
              Oct 21, 2026
            </td>
            <td class="w-28 tabular-nums" data-end="base sm md lg xl">
              $1,240.00
            </td>
          </tr>
          <tr id="orders-ticked-row-1041" tabindex="0" data-dt-row data-id="1041" data-href="/orders/1041" data-selected>
            <td class="data-table-check">
              <input type="checkbox" id="orders-ticked-row-1041-check" class="checkbox" aria-label="Select" aria-labelledby="orders-ticked-row-1041-check orders-ticked-row-1041-c0" checked data-dt-select>
            </td>
            <td id="orders-ticked-row-1041-c0" class="w-24 font-medium">
              #1041
            </td>
            <td>
              Maple &amp; Co.
            </td>
            <td class="w-36" data-hide-below="lg">
              Sam Okafor
            </td>
            <td class="w-28" data-hide-below="sm">
              <span class="badge badge-outline">Open</span>
            </td>
            <td class="w-32" data-hide-below="md">
              Oct 20, 2026
            </td>
            <td class="w-28 tabular-nums" data-end="base sm md lg xl">
              $318.50
            </td>
          </tr>
          <tr id="orders-ticked-row-1040" tabindex="0" data-dt-row data-id="1040" data-href="/orders/1040" data-selected>
            <td class="data-table-check">
              <input type="checkbox" id="orders-ticked-row-1040-check" class="checkbox" aria-label="Select" aria-labelledby="orders-ticked-row-1040-check orders-ticked-row-1040-c0" checked data-dt-select>
            </td>
            <td id="orders-ticked-row-1040-c0" class="w-24 font-medium">
              #1040
            </td>
            <td>
              Summit Outfitters
            </td>
            <td class="w-36" data-hide-below="lg">
              Jordan Diaz
            </td>
            <td class="w-28" data-hide-below="sm">
              <span class="badge badge-error">Overdue</span>
            </td>
            <td class="w-32" data-hide-below="md">
              Oct 18, 2026
            </td>
            <td class="w-28 tabular-nums" data-end="base sm md lg xl">
              $2,075.00
            </td>
          </tr>
          <tr id="orders-ticked-row-1039" tabindex="0" data-dt-row data-id="1039" data-href="/orders/1039" data-selected>
            <td class="data-table-check">
              <input type="checkbox" id="orders-ticked-row-1039-check" class="checkbox" aria-label="Select" aria-labelledby="orders-ticked-row-1039-check orders-ticked-row-1039-c0" checked data-dt-select>
            </td>
            <td id="orders-ticked-row-1039-c0" class="w-24 font-medium">
              #1039
            </td>
            <td>
              Lakeside Clinic
            </td>
            <td class="w-36" data-hide-below="lg">
              Riley Chen
            </td>
            <td class="w-28" data-hide-below="sm">
              <span class="badge badge-secondary">Paid</span>
            </td>
            <td class="w-32" data-hide-below="md">
              Oct 17, 2026
            </td>
            <td class="w-28 tabular-nums" data-end="base sm md lg xl">
              $96.40
            </td>
          </tr>
          <tr id="orders-ticked-row-1038" tabindex="0" data-dt-row data-id="1038" data-href="/orders/1038" data-selected>
            <td class="data-table-check">
              <input type="checkbox" id="orders-ticked-row-1038-check" class="checkbox" aria-label="Select" aria-labelledby="orders-ticked-row-1038-check orders-ticked-row-1038-c0" checked data-dt-select>
            </td>
            <td id="orders-ticked-row-1038-c0" class="w-24 font-medium">
              #1038
            </td>
            <td>
              Copper Kettle
            </td>
            <td class="w-36" data-hide-below="lg">
              Pat Lee
            </td>
            <td class="w-28" data-hide-below="sm">
              <span class="badge badge-outline">Open</span>
            </td>
            <td class="w-32" data-hide-below="md">
              Oct 15, 2026
            </td>
            <td class="w-28 tabular-nums" data-end="base sm md lg xl">
              $742.10
            </td>
          </tr>
          <tr id="orders-ticked-row-1037" tabindex="0" data-dt-row data-id="1037" data-href="/orders/1037" data-selected>
            <td class="data-table-check">
              <input type="checkbox" id="orders-ticked-row-1037-check" class="checkbox" aria-label="Select" aria-labelledby="orders-ticked-row-1037-check orders-ticked-row-1037-c0" checked data-dt-select>
            </td>
            <td id="orders-ticked-row-1037-c0" class="w-24 font-medium">
              #1037
            </td>
            <td>
              Granite Works
            </td>
            <td class="w-36" data-hide-below="lg">
              Sam Okafor
            </td>
            <td class="w-28" data-hide-below="sm">
              <span class="badge badge-outline">Refunded</span>
            </td>
            <td class="w-32" data-hide-below="md">
              Oct 14, 2026
            </td>
            <td class="w-28 tabular-nums" data-end="base sm md lg xl">
              $1,180.00
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    <div class="data-table-bulk" data-dt-bulk>
      <span class="data-table-bulk-count" aria-live="polite">
        6 selected
      </span>
      <button type="button" class="btn btn-ghost btn-sm" data-dt-select-matching phx-click="[[&quot;push&quot;,{&quot;value&quot;:{&quot;table&quot;:&quot;orders-ticked&quot;},&quot;event&quot;:&quot;dt:select_matching&quot;}]]">
        Select all 240 orders
      </button>
      <div class="data-table-bulk-actions">
        <button class="btn btn-outline btn-sm">
          Mark paid
        </button>
        <button class="btn btn-ghost btn-sm">
          Export
        </button>
      </div>
      <button type="button" class="btn btn-ghost btn-sm data-table-bulk-clear" data-dt-clear phx-click="[[&quot;push&quot;,{&quot;value&quot;:{&quot;table&quot;:&quot;orders-ticked&quot;},&quot;event&quot;:&quot;dt:clear&quot;}]]">
        Clear
      </button>
    </div>
  </div>
</div>
```

## Empty

HEEx:

```heex
<.data_table id="orders" rows={[]} state={@state} selectable noun={{"order", "orders"}}>
  <:col :let={o} label="Order" sort="number" class="w-24 font-medium">{o.number}</:col>
  <:col :let={o} label="Customer" sort="customer">{o.customer}</:col>
  <:col :let={o} label="Total" sort="total" class="w-28 tabular-nums">{o.total}</:col>
  <:empty title="No orders match" icon="hero-funnel">Try another search or filter.</:empty>
  <:empty_action>
    <.button size="sm" variant="outline" phx-click="dt:reset">Clear filters</.button>
  </:empty_action>
</.data_table>
```

```html
<div class="flex h-72 flex-col">
  <div id="orders-empty" data-data-table data-selectable data-view="25223434" class="card data-table">
    <div class="data-table-scroll" data-dt-scroll>
      <table class="table data-table-table">
        <thead>
          <tr>
            <th scope="col" class="data-table-check">
              <input type="checkbox" class="checkbox" aria-label="Select all orders" disabled data-dt-select-all phx-click="[[&quot;push&quot;,{&quot;value&quot;:{&quot;table&quot;:&quot;orders-empty&quot;},&quot;event&quot;:&quot;dt:select_all&quot;}]]">
            </th>
            <th scope="col" class="w-24 font-medium" aria-sort="none">
              <button type="button" class="data-table-sort" phx-click="[[&quot;push&quot;,{&quot;value&quot;:{&quot;table&quot;:&quot;orders-empty&quot;,&quot;key&quot;:&quot;number&quot;},&quot;event&quot;:&quot;dt:sort&quot;}]]">
                <span class="data-table-sort-label">Order</span>
                <span class="data-table-sort-icon hero-chevron-up-down" aria-hidden="true"></span>
              </button>
            </th>
            <th scope="col" aria-sort="none">
              <button type="button" class="data-table-sort" phx-click="[[&quot;push&quot;,{&quot;value&quot;:{&quot;table&quot;:&quot;orders-empty&quot;,&quot;key&quot;:&quot;customer&quot;},&quot;event&quot;:&quot;dt:sort&quot;}]]">
                <span class="data-table-sort-label">Customer</span>
                <span class="data-table-sort-icon hero-chevron-up-down" aria-hidden="true"></span>
              </button>
            </th>
            <th scope="col" class="w-28 tabular-nums" data-end="base sm md lg xl" aria-sort="none">
              <button type="button" class="data-table-sort" phx-click="[[&quot;push&quot;,{&quot;value&quot;:{&quot;table&quot;:&quot;orders-empty&quot;,&quot;key&quot;:&quot;total&quot;},&quot;event&quot;:&quot;dt:sort&quot;}]]">
                <span class="data-table-sort-label">Total</span>
                <span class="data-table-sort-icon hero-chevron-up-down" aria-hidden="true"></span>
              </button>
            </th>
          </tr>
        </thead>
        <tbody>
        </tbody>
      </table>
      <div class="data-table-empty">
        <div class="empty-state" data-variant="plain">
          <div class="empty-state-media" aria-hidden="true">
            <span class="hero-funnel size-5"></span>
          </div>
          <p class="empty-state-title">No orders match</p>
          <div class="empty-state-description">
            Try another search or filter.
          </div>
          <div class="empty-state-actions">
            <button class="btn btn-outline btn-sm">
              Clear filters
            </button>
          </div>
        </div>
      </div>
    </div>
    <div class="data-table-bulk" data-dt-bulk hidden>
      <span class="data-table-bulk-count" aria-live="polite">
        0 selected
      </span>
      <button type="button" class="btn btn-ghost btn-sm data-table-bulk-clear" data-dt-clear phx-click="[[&quot;push&quot;,{&quot;value&quot;:{&quot;table&quot;:&quot;orders-empty&quot;},&quot;event&quot;:&quot;dt:clear&quot;}]]">
        Clear
      </button>
    </div>
  </div>
</div>
```
