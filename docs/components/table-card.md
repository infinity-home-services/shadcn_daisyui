# Table Card

A card of rows with a title and description: a record's activity, its line items, its contacts.

The rightmost column is right-aligned unless align="left" (on phones only with grid, since stacked cells read top to bottom). :empty renders as the only row when rows is empty ("Nothing has happened yet."). row_class styles a row (a muted cancelled line). The record page on the dev server (`/lab/data-table/:id`) uses it for Items and Activity.

## Usage guidance

Use when:

- Rows that belong to one record: activity, line items, contacts, payments
- A few columns that read as a list on phones (stacked) or stay side by side (grid)

Don't use for:

- A list page with sorting, selection and filters - use <.data_table>
- Rows people compare across many columns - use <.table>
- One object per row with media and actions - use <.item>

Sizing: Card header 24px padding (16px under it): card-title, a muted description, :actions on the right. Rows text-sm, 12px / 24px padding, 16px column gap, 1px lines edge to edge; the last row's padding is the space under it. Column labels are a muted 500 row.

Responsive: From sm the columns share the width equally (2-6 columns) under a label row. On phones each row stacks its cells, unless grid (a grid-cols class) keeps them side by side at every width - use it for short numeric columns such as Qty and Price.

iOS: A Section in an inset-grouped List (header and footer text), one row per item.

## Specs

| Part | Description |
| --- | --- |
| Header | card-title, muted description, :actions on the right. |
| Label row | Column labels, muted 500, from sm (role=columnheader). |
| Row | A grid row of cells, 1px line under it, edge to edge. |
| Empty row | :empty, centred muted text, when there are no rows. |

| Property | Value |
| --- | --- |
| Header padding | 1.5rem 1.5rem 1rem |
| Row padding | 0.75rem block, 1.5rem inline |
| Column gap | 1rem (0.25rem between stacked cells) |
| Label row | 0.5rem block padding, var(--muted-foreground), 500 |
| Columns | equal shares for 2-6 columns from 40rem, or the grid class |

Tokens used: `card`, `card-foreground`, `border-color`, `muted-foreground`, `foreground`

## Accessibility

Role / ARIA: A section holding role=table (named by the title) with rowgroups, rows, columnheaders and cells, so the stacked phone layout keeps table semantics.

Focus: Nothing focusable of its own; links and buttons in cells or :actions keep their rings.

Screen reader: Read as a table with column headers; stacked cells on phones still announce their column.

Touch target: Interactive content in cells (links, buttons) should reach 44px on touch.

Reduced motion: No motion.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
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
```

An inset-grouped List Section matches the card; LabeledContent puts the trailing value on the right like the rightmost column. Use Grid for true columns on iPad.

## Props

| Name | Type | Default |
| --- | --- | --- |
| id | string (required) | - |
| title / description | string | nil |
| rows | list (required) | - |
| row_id | fn row -> DOM id | nil |
| row_class | fn row -> classes | nil |
| grid | string (grid-cols class) | nil (stack on phones) |
| :col label class align | slot | - |
| :actions | slot (right of the title) | - |
| :empty | slot (the only row when there are none) | - |

## Activity

HEEx:

```heex
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
```

```html
<section id="activity" class="card table-card w-full max-w-2xl" data-layout="stack">
  <div class="table-card-header">
    <div class="table-card-heading">
      <h3 class="card-title">Activity</h3>
      <p class="text-sm text-muted-foreground">Everything that happened to #1042.</p>
    </div>
    <div class="table-card-actions"><button class="btn btn-outline btn-sm">
        Add note
      </button></div>
  </div>
  <div role="table" aria-label="Activity" class="table-card-table">
    <div role="rowgroup">
      <div role="row" class="table-card-row table-card-head" data-cols="3">
        <div role="columnheader" class="table-card-cell font-medium">
          Event
        </div>
        <div role="columnheader" class="table-card-cell text-muted-foreground">
          By
        </div>
        <div role="columnheader" class="table-card-cell" data-align="right">
          When
        </div>
      </div>
    </div>
    <div role="rowgroup">
      <div id="event-1" role="row" class="table-card-row" data-cols="3">
        <div role="cell" class="table-card-cell font-medium">
          Order placed
        </div>
        <div role="cell" class="table-card-cell text-muted-foreground">
          Pat Lee
        </div>
        <div role="cell" class="table-card-cell" data-align="right">
          Oct 21, 2026
        </div>
      </div>
      <div id="event-2" role="row" class="table-card-row" data-cols="3">
        <div role="cell" class="table-card-cell font-medium">
          Invoice sent
        </div>
        <div role="cell" class="table-card-cell text-muted-foreground">
          System
        </div>
        <div role="cell" class="table-card-cell" data-align="right">
          Oct 22, 2026
        </div>
      </div>
      <div id="event-3" role="row" class="table-card-row" data-cols="3">
        <div role="cell" class="table-card-cell font-medium">
          Payment reminder
        </div>
        <div role="cell" class="table-card-cell text-muted-foreground">
          Pat Lee
        </div>
        <div role="cell" class="table-card-cell" data-align="right">
          Nov 4, 2026
        </div>
      </div>
      <div id="event-4" role="row" class="table-card-row" data-cols="3">
        <div role="cell" class="table-card-cell font-medium">
          Status: Paid
        </div>
        <div role="cell" class="table-card-cell text-muted-foreground">
          System
        </div>
        <div role="cell" class="table-card-cell" data-align="right">
          Nov 5, 2026
        </div>
      </div>
    </div>
  </div>
</section>
```

## Line items

HEEx:

```heex
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
```

```html
<section id="items" class="card table-card w-full max-w-2xl" data-layout="grid">
  <div class="table-card-header">
    <div class="table-card-heading">
      <h3 class="card-title">Items</h3>
      <p class="text-sm text-muted-foreground">What&#39;s on the order.</p>
    </div>
  </div>
  <div role="table" aria-label="Items" class="table-card-table">
    <div role="rowgroup">
      <div role="row" class="table-card-row table-card-head grid-cols-[minmax(0,1fr)_2.5rem_6rem]">
        <div role="columnheader" class="table-card-cell">
          Item
        </div>
        <div role="columnheader" class="table-card-cell tabular-nums">
          Qty
        </div>
        <div role="columnheader" class="table-card-cell tabular-nums" data-align="right">
          Price
        </div>
      </div>
    </div>
    <div role="rowgroup">
      <div role="row" class="table-card-row grid-cols-[minmax(0,1fr)_2.5rem_6rem]">
        <div role="cell" class="table-card-cell">
          Annual service plan
        </div>
        <div role="cell" class="table-card-cell tabular-nums">
          1
        </div>
        <div role="cell" class="table-card-cell tabular-nums" data-align="right">
          $744.00
        </div>
      </div>
      <div role="row" class="table-card-row grid-cols-[minmax(0,1fr)_2.5rem_6rem]">
        <div role="cell" class="table-card-cell">
          Filters, set of 4
        </div>
        <div role="cell" class="table-card-cell tabular-nums">
          2
        </div>
        <div role="cell" class="table-card-cell tabular-nums" data-align="right">
          $186.00
        </div>
      </div>
      <div role="row" class="table-card-row grid-cols-[minmax(0,1fr)_2.5rem_6rem]">
        <div role="cell" class="table-card-cell">
          Delivery
        </div>
        <div role="cell" class="table-card-cell tabular-nums">
          1
        </div>
        <div role="cell" class="table-card-cell tabular-nums" data-align="right">
          $124.00
        </div>
      </div>
    </div>
  </div>
</section>
```
