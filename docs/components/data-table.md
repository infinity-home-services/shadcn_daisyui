# Data Table

A table with filtering, faceted filters, sorting, and paging.

> Requires a JS hook: initialize with `initShadcnDaisyui()` (dead views) or the corresponding `Shadcn*` LiveView hook from `shadcn-daisyui.js`.

## Usage guidance

Use when:

- Working datasets: search, facet filters, sortable columns, paging
- Admin/index screens where the table is the page

Don't use for:

- A handful of static rows - plain table
- Compact-first experiences - design the card-list view first

Sizing: Toolbar controls are btn-sm/h-8; rows text-sm. Keep the table the only wide element on the page.

Responsive: Below medium: collapse to filterable card list or hide secondary columns - horizontal scrolling is a last resort.

iOS: A searchable List with filter chips/toolbar menus; sorting via a toolbar Menu.

## Specs

| Part | Description |
| --- | --- |
| Toolbar | Text filter, faceted status filter, and a reset button. |
| Header row | Sortable th cells (data-dt-sort) exposing aria-sort and a direction caret. |
| Body | Rows rendered from the demo dataset, paged client-side. |
| Pagination | Prev / Next buttons with a row + page count readout. |

| Property | Value |
| --- | --- |
| Page size | 5 rows |
| Sort caret | size-3.5 hero icon |
| Cell font | 0.875rem (table default) |
| Surface | var(--card) inside a rounded card |

Tokens used: `card`, `card-foreground`, `muted-foreground`, `accent`, `secondary`, `border-color`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Move between the filter, sortable headers, and pagination controls |
| Enter / Space | Toggle sort on the focused header (asc → desc) |
| Type | Filter rows by email in the toolbar input |

Role / ARIA: A semantic <table>. Sortable headers are tabbable (tabindex=0) and carry aria-sort=none|ascending|descending; the sort-direction icon is aria-hidden.

Focus: Headers receive a visible focus style; the filter and pagination buttons are native focusable controls.

Screen reader: aria-sort announces the current sort column and direction; the row/page count text reports result size.

Touch target: Header hit areas and pagination buttons are tappable; this is a desktop-oriented showcase, so size up controls for touch.

Reduced motion: Sorting and paging re-render rows instantly with no animation.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
Table(rows, sortOrder: $sortOrder) {
    TableColumn("Status", value: \.status) { Text($0.status) }
    TableColumn("Email", value: \.email)
    TableColumn("Amount") { Text($0.amount, format: .currency(code: "USD")) }
}
.searchable(text: $query)
```

SwiftUI Table covers sorting and columns on macOS/iPadOS; on compact iPhone fall back to a List of rows, since Table degrades to single-column.

## Default

```html
<div data-datatable class="w-full space-y-3">
  <div class="flex flex-wrap items-center gap-2">
    <input data-dt-filter class="input w-full sm:w-64" placeholder="Filter emails…" />
    <div data-dt-facet="status" class="relative">
      <button type="button" data-dt-facet-trigger class="btn btn-outline btn-sm border-dashed font-normal">
        <span class="hero-plus-circle size-4" aria-hidden="true"></span>
        Status
        <span data-dt-facet-badges class="hidden"></span>
      </button>
      <div data-dt-facet-panel class="popover-panel absolute z-30 mt-1 hidden w-52 p-1">
        <ul data-dt-facet-list></ul>
        <div data-dt-facet-clear class="hidden">
          <div class="my-1 border-t border-base-300"></div>
          <button type="button" data-dt-facet-clear-btn class="combo-item justify-center text-center">
            Clear filters
          </button>
        </div>
      </div>
    </div>
    <button type="button" data-dt-reset class="btn btn-ghost btn-sm hidden">
      Reset <span class="hero-x-mark size-4" aria-hidden="true"></span>
    </button>
  </div>
  <div class="card overflow-hidden">
    <table class="table w-full table-fixed">
      <thead>
        <tr>
          <th data-dt-sort="status" class="w-40">
            <span class="inline-flex items-center gap-1">Status <span data-dt-sort-icon class="hero-chevron-up-down size-3.5 opacity-50"></span></span>
          </th>
          <th data-dt-sort="email">
            <span class="inline-flex items-center gap-1">Email <span data-dt-sort-icon class="hero-chevron-up-down size-3.5 opacity-50"></span></span>
          </th>
          <th data-dt-sort="amount" class="w-32 text-right">
            <span class="inline-flex items-center justify-end gap-1">Amount <span data-dt-sort-icon class="hero-chevron-up-down size-3.5 opacity-50"></span></span>
          </th>
        </tr>
      </thead>
      <tbody data-dt-body></tbody>
    </table>
  </div>
  <div class="flex items-center justify-between">
    <span data-dt-info class="text-sm text-muted-foreground"></span>
    <div class="flex gap-2">
      <button type="button" data-dt-prev class="btn btn-outline btn-sm">Previous</button>
      <button type="button" data-dt-next class="btn btn-outline btn-sm">Next</button>
    </div>
  </div>
</div>
```
