# Table Toolbar

The one row above a data table: saved views or the count, search, a Filters sheet, and the filters that are on as chips.

> Requires a JS hook: initialize with `initShadcnDaisyui()` (dead views) or the corresponding `Shadcn*` LiveView hook from `shadcn-daisyui.js`.

The toolbar is one form: it sends dt:filter (on change and submit) with q (the search, debounced 200ms), each :filter's value (a multiple select posts a list, cleared posts "") and sort. Removing a chip sends dt:unfilter %{"key"}; Clear all sends dt:reset. Every payload carries "table" => the toolbar's id.

Apply it with State.put_search/2, State.put_filters/4 and State.parse_sort/3 (value first: State.parse_sort(params["sort"], state, opts)), then push_patch to State.to_params/2. State.chips/3 turns the filters into chips ("Open or Paid"); a saved view's own filter is a {key, label, :fixed} chip that can't be removed.

The Filters sheet: each :filter under its label, applied as it changes (the sheet stays open); on phones a Sort by select (the first of sorts is the default order, posted as ""); a footer with Clear all and "Show N orders", which closes it. On this static page the sheet, pickers, views menu and chips run, but nothing is sent; the full list page runs on the dev server (`/lab/data-table`).

## Usage guidance

Use when:

- Above a <.data_table>: search, filters and saved views of one list
- Filters that belong in the URL, so a view can be bookmarked and Back restores it
- Saved views people switch between (All, Open, Mine), each a patch link with its count

Don't use for:

- A short list with nothing to filter - a heading and the table are enough
- Filters that change the whole page (date range for a dashboard) - put them in the page header
- Search that only the server can run across records - use <.command on_search>

Sizing: One row, 8px gaps: views (a tab nav) or a muted text-sm count, the h-9 search (16rem; 14rem beside views), an outline Filters button with a 20px primary count pill, then :more. Chips sit 8px under the row in a reveal.

Responsive: Phones: without views the search takes the row; beside views it shrinks to 7rem. Filters goes icon-only (the label stays for screen readers), :more hides, and the sheet adds a Sort by select (from sorts). The row never wraps: views fold into the Views menu, chips into +N.

iOS: .searchable for the search, .searchScopes or a segmented Picker for views, and a toolbar button that opens a filter sheet (a Form of pickers).

## Specs

| Part | Description |
| --- | --- |
| Views | A <.tab_nav> of patch links with counts; an edited view shows a dot; overflow and the menu entries go in the Views menu. |
| Count | Without views: "N orders", or "N of M" while filtered. |
| Search | An input with a magnifier, name q, debounced 200ms. |
| Filters button | Outline button that opens the sheet, with the number of filters on. |
| More | Trailing controls (Export, Columns), hidden on phones. |
| Chips row | A <.chip_row> in a <.reveal>: removable chips, fixed chips, a stack for a filter with several values (named after its :filter), then :save and Clear all. |
| Filters sheet | A <.sheet>: one field per filter, Sort by on phones, Clear all + Show N. |

| Property | Value |
| --- | --- |
| Row | flex, 0.5rem gaps, never wraps |
| Search | 16rem (14rem beside views from 40rem, 7rem on phones) |
| Filters count | 1.25rem pill, var(--primary), text-xs |
| Edited dot | 0.375rem, var(--primary) |
| Chips row | 0.5rem under the row, 180ms reveal |
| Sheet fields | 1rem apart, label text-sm 500, 0.5rem above its picker |

Tokens used: `muted`, `muted-foreground`, `primary`, `primary-foreground`, `secondary`, `input`, `border-color`, `popover`, `ring`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Views, search, Filters, :more, then the chips |
| Enter / Space | Open the Filters sheet |
| Esc | Close the sheet (or an open picker inside it first) |
| Enter in the search | Submit the form (dt:filter) at once |

Role / ARIA: The views are a nav named "Views" (aria-current on the active link). The search is type=search labelled by its placeholder. The Filters button has aria-haspopup=dialog and aria-controls the sheet; the count reads "2 on". Chips are a group named "Active filters"; each × is "Remove filter: Status: Open".

Focus: Opening the sheet moves focus into it; closing returns it to the Filters button. Removing a chip moves focus to its neighbour.

Screen reader: The count is plain text ("12 of 240"); the Filters button announces how many filters are on; the views menu names the active view.

Touch target: On phones Filters is a 44px icon button and the sheet's pickers use full_width (44px on touch).

Reduced motion: The chips row slides 180ms and chips fade; both drop to instant under prefers-reduced-motion.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
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
```

.searchable with .searchScopes covers search and views; filters go in a sheet holding a Form of Pickers (a multi-select is a List with selection). Show active filters as a horizontal row of removable capsules above the list if they matter at a glance.

## Props

| Name | Type | Default |
| --- | --- | --- |
| id | string (required) | - |
| search / placeholder | string | "" / "Search…" |
| shown / total | integer | nil ("N orders", "N of M" when filtered) |
| noun | {singular, plural} | {"row", "rows"} |
| views | [%{key, label, count, path, active, edited}] | [] |
| menu | [%{key, label, group, icon, active, path \| click}] | [] |
| chips | [{key, label} \| {key, label, :fixed} \| {key, [{value, label}]} \| {key, [{value, label}], :fixed}] | [] |
| sort / sorts | "key:dir" / [{label, "key:dir"}] | "" / [] |
| target | phx-target | nil |
| :filter key label | slot (one select or combobox named key) | - |
| :more | slot (hidden on phones) | - |
| :save | slot (end of the chips row) | - |

## With views

HEEx:

```heex
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
```

```html
<div id="orders-toolbar" class="table-toolbar" data-views>
  <form id="orders-toolbar-form" class="table-toolbar-form" phx-change="dt:filter" phx-submit="dt:filter">
    <input type="hidden" name="table" value="orders-toolbar">
    <div class="table-toolbar-row">
      <nav id="orders-toolbar-views" data-tab-nav aria-label="Views" class="tab-nav table-toolbar-views">
        <div class="tabs tabs-box tab-nav-list">
          <div class="tab-nav-tabs" data-tab-nav-tabs>
            <a href="#all" data-phx-link="patch" data-phx-link-state="push" class="tab" data-index="0" data-tab-nav-item>
              <span class="tab-nav-label">
                All orders
              </span>
              <span class="tab-count">240</span>
            </a>
            <a href="#open" data-phx-link="patch" data-phx-link-state="push" class="tab" data-index="1" data-tab-nav-item>
              <span class="tab-nav-label">
                Open
              </span>
              <span class="tab-count">48</span>
            </a>
            <a href="#overdue" data-phx-link="patch" data-phx-link-state="push" class="tab tab-active" aria-current="page" data-index="2" data-tab-nav-item>
              <span class="tab-nav-label">
                Overdue<span class="table-toolbar-edited"><span class="sr-only">(edited)</span></span>
              </span>
              <span class="tab-count">19</span>
            </a>
            <a href="#mine" data-phx-link="patch" data-phx-link-state="push" class="tab" data-index="3" data-tab-nav-item>
              <span class="tab-nav-label">
                Mine
              </span>
              <span class="tab-count">60</span>
            </a>
          </div>
          <div class="tab-nav-more" data-tab-nav-more>
            <button type="button" id="orders-toolbar-views-more" class="tab" aria-expanded="false" aria-controls="orders-toolbar-views-menu" data-tab-nav-trigger>
              <span class="tab-nav-label" data-tab-nav-default>Views</span>
              <span class="tab-nav-label" data-tab-nav-current>
                Overdue<span class="table-toolbar-edited"><span class="sr-only">(edited)</span></span>
              </span>
              <span class="tab-count" data-tab-nav-current>
                19
              </span>
              <span class="hero-chevron-down size-4 opacity-50" aria-hidden="true"></span>
            </button>
            <div id="orders-toolbar-views-menu" class="popover-panel tab-nav-menu" data-tab-nav-menu hidden>
              <div data-tab-nav-overflow hidden>
                <a href="#all" data-phx-link="patch" data-phx-link-state="push" hidden class="combo-item" tabindex="-1" data-index="0" data-tab-nav-copy>
                  <span class="truncate">
                    All orders
                  </span>
                  <span class="ml-auto font-mono text-xs text-muted-foreground">
                    240
                  </span>
                </a>
                <a href="#open" data-phx-link="patch" data-phx-link-state="push" hidden class="combo-item" tabindex="-1" data-index="1" data-tab-nav-copy>
                  <span class="truncate">
                    Open
                  </span>
                  <span class="ml-auto font-mono text-xs text-muted-foreground">
                    48
                  </span>
                </a>
                <a href="#overdue" data-phx-link="patch" data-phx-link-state="push" hidden class="combo-item" aria-current="page" tabindex="-1" data-index="2" data-tab-nav-copy>
                  <span class="truncate">
                    Overdue<span class="table-toolbar-edited"><span class="sr-only">(edited)</span></span>
                  </span>
                  <span class="ml-auto font-mono text-xs text-muted-foreground">
                    19
                  </span>
                  <span class="hero-check size-4" aria-hidden="true">
                  </span>
                </a>
                <a href="#mine" data-phx-link="patch" data-phx-link-state="push" hidden class="combo-item" tabindex="-1" data-index="3" data-tab-nav-copy>
                  <span class="truncate">
                    Mine
                  </span>
                  <span class="ml-auto font-mono text-xs text-muted-foreground">
                    60
                  </span>
                </a>
              </div>
              <div class="tab-nav-sep" data-tab-nav-sep hidden>
              </div>
              <div role="group">
                <a href="#manage-views" data-phx-link="patch" data-phx-link-state="push" class="combo-item" data-tab-nav-entry tabindex="-1">
                  <span class="hero-cog-6-tooth size-4" aria-hidden="true"></span>
                  <span class="truncate">
                    Manage views…
                  </span>
                </a>
              </div>
            </div>
          </div>
        </div>
      </nav>
      <label class="input table-toolbar-search">
        <span class="hero-magnifying-glass size-4 shrink-0 opacity-50" aria-hidden="true"></span>
        <input type="search" name="q" value="" placeholder="Search orders" aria-label="Search orders" autocomplete="off" phx-debounce="200">
      </label>
      <button type="button" class="btn btn-outline table-toolbar-filters" aria-haspopup="dialog" aria-controls="orders-toolbar-filters" phx-click="[[&quot;dispatch&quot;,{&quot;to&quot;:&quot;#orders-toolbar-filters&quot;,&quot;event&quot;:&quot;shadcn:show-modal&quot;}]]">
        <span class="hero-funnel size-4" aria-hidden="true"></span>
        <span class="table-toolbar-filters-label">Filters</span>
        <span class="table-toolbar-filters-count">
          1<span class="sr-only"> on</span>
        </span>
      </button>
    </div>
    <div class="reveal" data-open>
      <div class="reveal-track"><div class="table-toolbar-chips">
          <div id="orders-toolbar-chips" data-chip-row role="group" aria-label="Active filters" class="chip-row">
            <ul class="chip-row-chips" data-chip-row-chips>
              <li id="orders-toolbar-chips-chip-v-view" class="badge chip badge-secondary" data-index="0" data-value="view" phx-remove="[[&quot;dispatch&quot;,{&quot;event&quot;:&quot;chip-exit&quot;}],[&quot;transition&quot;,{&quot;time&quot;:180,&quot;transition&quot;:[[&quot;chip-exit&quot;],[],[]]}]]" data-chip>
                <span id="orders-toolbar-chips-chip-v-view-label" class="chip-label">
                  Status: Overdue
                </span>
              </li>
              <li id="orders-toolbar-chips-chip-v-owner" class="badge chip badge-secondary" data-index="1" data-value="owner" phx-remove="[[&quot;dispatch&quot;,{&quot;event&quot;:&quot;chip-exit&quot;}],[&quot;transition&quot;,{&quot;time&quot;:180,&quot;transition&quot;:[[&quot;chip-exit&quot;],[],[]]}]]" data-chip>
                <span id="orders-toolbar-chips-chip-v-owner-label" class="chip-label">
                  Owner: Pat Lee
                </span>
                <button type="button" id="orders-toolbar-chips-chip-v-owner-remove" class="chip-remove" aria-label="Remove filter: Owner: Pat Lee" phx-click="[[&quot;push&quot;,{&quot;value&quot;:{&quot;table&quot;:&quot;orders-toolbar&quot;,&quot;key&quot;:&quot;owner&quot;},&quot;event&quot;:&quot;dt:unfilter&quot;}]]" data-chip-remove>
                  <span class="hero-x-mark size-3" aria-hidden="true"></span>
                </button>
              </li>
            </ul>
            <div class="chip-row-more" data-chip-row-more hidden>
              <button type="button" class="badge badge-outline chip chip-more" aria-expanded="false" aria-controls="orders-toolbar-chips-overflow" data-chip-row-trigger data-more-label="Show {count} more">
              </button>
              <div id="orders-toolbar-chips-overflow" class="popover-panel chip-row-panel" data-chip-row-panel hidden>
                <ul class="flex flex-wrap gap-2" aria-label="Active filters">
                  <li id="orders-toolbar-chips-copy-v-view" class="badge chip badge-secondary" data-index="0" data-value="view" hidden phx-remove="[[&quot;dispatch&quot;,{&quot;event&quot;:&quot;chip-exit&quot;}],[&quot;transition&quot;,{&quot;time&quot;:180,&quot;transition&quot;:[[&quot;chip-exit&quot;],[],[]]}]]" data-chip-copy>
                    <span id="orders-toolbar-chips-copy-v-view-label" class="chip-label">
                      Status: Overdue
                    </span>
                  </li>
                  <li id="orders-toolbar-chips-copy-v-owner" class="badge chip badge-secondary" data-index="1" data-value="owner" hidden phx-remove="[[&quot;dispatch&quot;,{&quot;event&quot;:&quot;chip-exit&quot;}],[&quot;transition&quot;,{&quot;time&quot;:180,&quot;transition&quot;:[[&quot;chip-exit&quot;],[],[]]}]]" data-chip-copy>
                    <span id="orders-toolbar-chips-copy-v-owner-label" class="chip-label">
                      Owner: Pat Lee
                    </span>
                    <button type="button" id="orders-toolbar-chips-copy-v-owner-remove" class="chip-remove" aria-label="Remove filter: Owner: Pat Lee" phx-click="[[&quot;push&quot;,{&quot;value&quot;:{&quot;table&quot;:&quot;orders-toolbar&quot;,&quot;key&quot;:&quot;owner&quot;},&quot;event&quot;:&quot;dt:unfilter&quot;}]]" data-chip-remove>
                      <span class="hero-x-mark size-3" aria-hidden="true"></span>
                    </button>
                  </li>
                </ul>
              </div>
            </div>
            <div id="orders-toolbar-chips-actions" class="chip-row-actions" data-chip-row-actions phx-remove="[[&quot;dispatch&quot;,{&quot;event&quot;:&quot;chip-exit&quot;}],[&quot;transition&quot;,{&quot;time&quot;:180,&quot;transition&quot;:[[&quot;chip-exit&quot;],[],[]]}]]">
              <button class="btn btn-outline btn-sm">
                Save view
              </button>
              <button type="button" class="btn btn-ghost btn-sm" phx-click="[[&quot;push&quot;,{&quot;value&quot;:{&quot;table&quot;:&quot;orders-toolbar&quot;},&quot;event&quot;:&quot;dt:reset&quot;}]]">
                Clear all
              </button>
            </div>
          </div>
        </div></div>
    </div>
    <dialog id="orders-toolbar-filters" class="sheet">
      <div class="sheet-header">
        <button type="button" class="btn btn-ghost btn-square btn-sm absolute right-3 top-3" aria-label="Close" phx-click="[[&quot;dispatch&quot;,{&quot;to&quot;:&quot;#orders-toolbar-filters&quot;,&quot;event&quot;:&quot;shadcn:hide-modal&quot;}]]">
          <span class="hero-x-mark size-4" aria-hidden="true"></span>
        </button>
        <h3 class="sheet-title text-lg font-semibold">Filters</h3>
      </div>
      <div class="sheet-body">
        <div>
          <div class="table-toolbar-fields">
            <label class="table-toolbar-field" data-filter="status">
              <span class="table-toolbar-field-label">Status</span>
              <div id="filter-status" data-select data-multiple data-full-width data-placeholder="Any status" class="relative w-full">
                <input type="hidden" name="status" value="" data-select-sentinel>
                <button type="button" id="filter-status-trigger" role="combobox" aria-haspopup="listbox" aria-expanded="false" aria-controls="filter-status-list" class="btn btn-outline w-full justify-between font-normal" data-select-trigger>
                  <span class="flex min-w-0 items-center gap-1 text-muted-foreground" data-select-label>
                    <span class="truncate">Any status</span>
                  </span>
                  <span class="size-4 shrink-0 opacity-50 hero-chevron-down" aria-hidden="true">
                  </span>
                </button>
                <div class="popover-panel absolute z-50 mt-1 hidden w-full p-1" data-select-panel>
                  <div id="filter-status-list" role="listbox" aria-multiselectable="true" class="max-h-72 overflow-auto" data-select-list>
                    <button type="button" tabindex="-1" role="option" aria-selected="false" class="combo-item" data-select-item data-value="open">
                      <span class="facet-check" aria-hidden="true"><span class="hero-check size-3.5"></span></span>
                      <span data-label class="truncate">Open</span>
                    </button>
                    <button type="button" tabindex="-1" role="option" aria-selected="false" class="combo-item" data-select-item data-value="paid">
                      <span class="facet-check" aria-hidden="true"><span class="hero-check size-3.5"></span></span>
                      <span data-label class="truncate">Paid</span>
                    </button>
                    <button type="button" tabindex="-1" role="option" aria-selected="false" class="combo-item" data-select-item data-value="overdue">
                      <span class="facet-check" aria-hidden="true"><span class="hero-check size-3.5"></span></span>
                      <span data-label class="truncate">Overdue</span>
                    </button>
                    <button type="button" tabindex="-1" role="option" aria-selected="false" class="combo-item" data-select-item data-value="refunded">
                      <span class="facet-check" aria-hidden="true"><span class="hero-check size-3.5"></span></span>
                      <span data-label class="truncate">Refunded</span>
                    </button>
                  </div>
                  <div class="-mx-1 mt-1 border-t border-border px-1 pt-1 hidden" data-select-clear>
                    <button type="button" class="combo-item justify-center" data-select-clear-btn>Clear</button>
                  </div>
                </div>
              </div>
            </label>
            <label class="table-toolbar-field" data-filter="owner">
              <span class="table-toolbar-field-label">Owner</span>
              <div id="filter-owner" data-combobox data-multiple data-full-width data-placeholder="Anyone" class="relative w-full">
                <input type="hidden" name="owner" value="" data-combobox-sentinel>
                <input type="hidden" name="owner[]" value="Pat Lee" data-combobox-value>
                <button type="button" id="filter-owner-trigger" aria-haspopup="listbox" aria-expanded="false" aria-controls="filter-owner-list" class="btn btn-outline w-full justify-between font-normal" data-combobox-trigger>
                  <span class="flex min-w-0 items-center gap-1" data-combobox-label>
                    <span class="truncate">Pat Lee</span>
                  </span>
                  <span class="size-4 shrink-0 opacity-50 hero-chevron-up-down" aria-hidden="true">
                  </span>
                </button>
                <div class="popover-panel absolute z-50 mt-1 hidden w-full p-1" data-combobox-panel>
                  <input data-combobox-search class="input mb-1 w-full" placeholder="Anyone" autocomplete="off">
                  <ul id="filter-owner-list" role="listbox" aria-multiselectable="true" class="max-h-60 overflow-auto" data-combobox-list>
                    <li>
                      <button type="button" tabindex="-1" role="option" aria-selected="true" class="combo-item" data-value="Pat Lee" data-selected>
                        <span class="facet-check" aria-hidden="true"><span class="hero-check size-3.5"></span></span>
                        <span data-label class="truncate">Pat Lee</span>
                      </button>
                    </li>
                    <li>
                      <button type="button" tabindex="-1" role="option" aria-selected="false" class="combo-item" data-value="Sam Okafor">
                        <span class="facet-check" aria-hidden="true"><span class="hero-check size-3.5"></span></span>
                        <span data-label class="truncate">Sam Okafor</span>
                      </button>
                    </li>
                    <li>
                      <button type="button" tabindex="-1" role="option" aria-selected="false" class="combo-item" data-value="Jordan Diaz">
                        <span class="facet-check" aria-hidden="true"><span class="hero-check size-3.5"></span></span>
                        <span data-label class="truncate">Jordan Diaz</span>
                      </button>
                    </li>
                    <li>
                      <button type="button" tabindex="-1" role="option" aria-selected="false" class="combo-item" data-value="Riley Chen">
                        <span class="facet-check" aria-hidden="true"><span class="hero-check size-3.5"></span></span>
                        <span data-label class="truncate">Riley Chen</span>
                      </button>
                    </li>
                  </ul>
                  <p data-combobox-empty class="hidden p-2 text-center text-sm text-muted-foreground">No results.</p>
                  <div class="-mx-1 mt-1 border-t border-border px-1 pt-1" data-combobox-clear>
                    <button type="button" class="combo-item justify-center" data-combobox-clear-btn>Clear</button>
                  </div>
                </div>
              </div>
            </label>
            <label class="table-toolbar-field table-toolbar-sort">
              <span class="table-toolbar-field-label">Sort by</span>
              <div id="orders-toolbar-sort" data-select data-full-width data-placeholder="Select…" class="relative w-full">
                <input type="hidden" name="sort" value="" data-select-input>
                <button type="button" id="orders-toolbar-sort-trigger" role="combobox" aria-haspopup="listbox" aria-expanded="false" aria-controls="orders-toolbar-sort-list" class="btn btn-outline w-full justify-between font-normal" data-select-trigger>
                  <span class="flex min-w-0 items-center gap-1" data-select-label>
                    <span class="truncate">Newest first</span>
                  </span>
                  <span class="size-4 shrink-0 opacity-50 hero-chevron-down" aria-hidden="true">
                  </span>
                </button>
                <div class="popover-panel absolute z-50 mt-1 hidden w-full p-1" data-select-panel>
                  <div id="orders-toolbar-sort-list" role="listbox" class="max-h-72 overflow-auto" data-select-list>
                    <button type="button" tabindex="-1" role="option" aria-selected="true" class="combo-item" data-select-item data-value="" data-selected>
                      <span class="hero-check size-4 shrink-0" aria-hidden="true"></span>
                      <span data-label class="truncate">Newest first</span>
                    </button>
                    <button type="button" tabindex="-1" role="option" aria-selected="false" class="combo-item" data-select-item data-value="placed:asc">
                      <span class="hero-check size-4 shrink-0 opacity-0" aria-hidden="true"></span>
                      <span data-label class="truncate">Oldest first</span>
                    </button>
                    <button type="button" tabindex="-1" role="option" aria-selected="false" class="combo-item" data-select-item data-value="customer:asc">
                      <span class="hero-check size-4 shrink-0 opacity-0" aria-hidden="true"></span>
                      <span data-label class="truncate">Customer A–Z</span>
                    </button>
                    <button type="button" tabindex="-1" role="option" aria-selected="false" class="combo-item" data-select-item data-value="total:desc">
                      <span class="hero-check size-4 shrink-0 opacity-0" aria-hidden="true"></span>
                      <span data-label class="truncate">Largest total</span>
                    </button>
                  </div>
                </div>
              </div>
            </label>
          </div>
        </div>
      </div>
      <div class="sheet-footer">
        <button type="button" class="btn btn-ghost" phx-click="[[&quot;push&quot;,{&quot;value&quot;:{&quot;table&quot;:&quot;orders-toolbar&quot;},&quot;event&quot;:&quot;dt:reset&quot;}]]">
          Clear all
        </button>
        <button type="button" class="btn btn-primary ml-auto grow sm:grow-0" phx-click="[[&quot;dispatch&quot;,{&quot;to&quot;:&quot;#orders-toolbar-filters&quot;,&quot;event&quot;:&quot;shadcn:hide-modal&quot;}]]">
          Show 7 orders
        </button>
      </div>
      <div id="orders-toolbar-filters-toasts" data-toast-host phx-update="ignore"></div>
    </dialog>
  </form>
</div>
```

## Without views

HEEx:

```heex
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
```

```html
<div id="customers-toolbar" class="table-toolbar">
  <form id="customers-toolbar-form" class="table-toolbar-form" phx-change="dt:filter" phx-submit="dt:filter">
    <input type="hidden" name="table" value="customers-toolbar">
    <div class="table-toolbar-row">
      <p class="table-toolbar-count">
        3 of 128
      </p>
      <label class="input table-toolbar-search">
        <span class="hero-magnifying-glass size-4 shrink-0 opacity-50" aria-hidden="true"></span>
        <input type="search" name="q" value="harbor" placeholder="Search customers" aria-label="Search customers" autocomplete="off" phx-debounce="200">
      </label>
      <button type="button" class="btn btn-outline table-toolbar-filters" aria-haspopup="dialog" aria-controls="customers-toolbar-filters" phx-click="[[&quot;dispatch&quot;,{&quot;to&quot;:&quot;#customers-toolbar-filters&quot;,&quot;event&quot;:&quot;shadcn:show-modal&quot;}]]">
        <span class="hero-funnel size-4" aria-hidden="true"></span>
        <span class="table-toolbar-filters-label">Filters</span>
      </button>
      <div class="table-toolbar-more">
        <button class="btn btn-outline btn-sm">
          Export
        </button>
      </div>
    </div>
    <div class="reveal">
      <div class="reveal-track"><div class="table-toolbar-chips">
          <div id="customers-toolbar-chips" data-chip-row role="group" aria-label="Active filters" class="chip-row">
            <ul class="chip-row-chips" data-chip-row-chips>
            </ul>
            <div class="chip-row-more" data-chip-row-more hidden>
              <button type="button" class="badge badge-outline chip chip-more" aria-expanded="false" aria-controls="customers-toolbar-chips-overflow" data-chip-row-trigger data-more-label="Show {count} more">
              </button>
              <div id="customers-toolbar-chips-overflow" class="popover-panel chip-row-panel" data-chip-row-panel hidden>
                <ul class="flex flex-wrap gap-2" aria-label="Active filters">
                </ul>
              </div>
            </div>
            <div id="customers-toolbar-chips-actions" class="chip-row-actions" data-chip-row-actions phx-remove="[[&quot;dispatch&quot;,{&quot;event&quot;:&quot;chip-exit&quot;}],[&quot;transition&quot;,{&quot;time&quot;:180,&quot;transition&quot;:[[&quot;chip-exit&quot;],[],[]]}]]">
            </div>
          </div>
        </div></div>
    </div>
    <dialog id="customers-toolbar-filters" class="sheet">
      <div class="sheet-header">
        <button type="button" class="btn btn-ghost btn-square btn-sm absolute right-3 top-3" aria-label="Close" phx-click="[[&quot;dispatch&quot;,{&quot;to&quot;:&quot;#customers-toolbar-filters&quot;,&quot;event&quot;:&quot;shadcn:hide-modal&quot;}]]">
          <span class="hero-x-mark size-4" aria-hidden="true"></span>
        </button>
        <h3 class="sheet-title text-lg font-semibold">Filters</h3>
      </div>
      <div class="sheet-body">
        <div>
          <div class="table-toolbar-fields">
            <label class="table-toolbar-field" data-filter="plan">
              <span class="table-toolbar-field-label">Plan</span>
              <div id="filter-plan" data-select data-multiple data-full-width data-placeholder="Any plan" class="relative w-full">
                <input type="hidden" name="plan" value="" data-select-sentinel>
                <button type="button" id="filter-plan-trigger" role="combobox" aria-haspopup="listbox" aria-expanded="false" aria-controls="filter-plan-list" class="btn btn-outline w-full justify-between font-normal" data-select-trigger>
                  <span class="flex min-w-0 items-center gap-1 text-muted-foreground" data-select-label>
                    <span class="truncate">Any plan</span>
                  </span>
                  <span class="size-4 shrink-0 opacity-50 hero-chevron-down" aria-hidden="true">
                  </span>
                </button>
                <div class="popover-panel absolute z-50 mt-1 hidden w-full p-1" data-select-panel>
                  <div id="filter-plan-list" role="listbox" aria-multiselectable="true" class="max-h-72 overflow-auto" data-select-list>
                    <button type="button" tabindex="-1" role="option" aria-selected="false" class="combo-item" data-select-item data-value="free">
                      <span class="facet-check" aria-hidden="true"><span class="hero-check size-3.5"></span></span>
                      <span data-label class="truncate">Free</span>
                    </button>
                    <button type="button" tabindex="-1" role="option" aria-selected="false" class="combo-item" data-select-item data-value="team">
                      <span class="facet-check" aria-hidden="true"><span class="hero-check size-3.5"></span></span>
                      <span data-label class="truncate">Team</span>
                    </button>
                    <button type="button" tabindex="-1" role="option" aria-selected="false" class="combo-item" data-select-item data-value="business">
                      <span class="facet-check" aria-hidden="true"><span class="hero-check size-3.5"></span></span>
                      <span data-label class="truncate">Business</span>
                    </button>
                  </div>
                  <div class="-mx-1 mt-1 border-t border-border px-1 pt-1 hidden" data-select-clear>
                    <button type="button" class="combo-item justify-center" data-select-clear-btn>Clear</button>
                  </div>
                </div>
              </div>
            </label>
            <label class="table-toolbar-field table-toolbar-sort">
              <span class="table-toolbar-field-label">Sort by</span>
              <div id="customers-toolbar-sort" data-select data-full-width data-placeholder="Select…" class="relative w-full">
                <input type="hidden" name="sort" value="" data-select-input>
                <button type="button" id="customers-toolbar-sort-trigger" role="combobox" aria-haspopup="listbox" aria-expanded="false" aria-controls="customers-toolbar-sort-list" class="btn btn-outline w-full justify-between font-normal" data-select-trigger>
                  <span class="flex min-w-0 items-center gap-1" data-select-label>
                    <span class="truncate">Name A–Z</span>
                  </span>
                  <span class="size-4 shrink-0 opacity-50 hero-chevron-down" aria-hidden="true">
                  </span>
                </button>
                <div class="popover-panel absolute z-50 mt-1 hidden w-full p-1" data-select-panel>
                  <div id="customers-toolbar-sort-list" role="listbox" class="max-h-72 overflow-auto" data-select-list>
                    <button type="button" tabindex="-1" role="option" aria-selected="true" class="combo-item" data-select-item data-value="" data-selected>
                      <span class="hero-check size-4 shrink-0" aria-hidden="true"></span>
                      <span data-label class="truncate">Name A–Z</span>
                    </button>
                    <button type="button" tabindex="-1" role="option" aria-selected="false" class="combo-item" data-select-item data-value="orders:desc">
                      <span class="hero-check size-4 shrink-0 opacity-0" aria-hidden="true"></span>
                      <span data-label class="truncate">Most orders</span>
                    </button>
                    <button type="button" tabindex="-1" role="option" aria-selected="false" class="combo-item" data-select-item data-value="joined:desc">
                      <span class="hero-check size-4 shrink-0 opacity-0" aria-hidden="true"></span>
                      <span data-label class="truncate">Newest</span>
                    </button>
                  </div>
                </div>
              </div>
            </label>
          </div>
        </div>
      </div>
      <div class="sheet-footer">
        <button type="button" class="btn btn-ghost" phx-click="[[&quot;push&quot;,{&quot;value&quot;:{&quot;table&quot;:&quot;customers-toolbar&quot;},&quot;event&quot;:&quot;dt:reset&quot;}]]">
          Clear all
        </button>
        <button type="button" class="btn btn-primary ml-auto grow sm:grow-0" phx-click="[[&quot;dispatch&quot;,{&quot;to&quot;:&quot;#customers-toolbar-filters&quot;,&quot;event&quot;:&quot;shadcn:hide-modal&quot;}]]">
          Show 3 customers
        </button>
      </div>
      <div id="customers-toolbar-filters-toasts" data-toast-host phx-update="ignore"></div>
    </dialog>
  </form>
</div>
```
