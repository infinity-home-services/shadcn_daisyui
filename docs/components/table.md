# Table

A responsive table for displaying rows of data.

## Usage guidance

Use when:

- Scanning and comparing records across a few columns
- Static or lightly interactive row data (use <.table> with <:col> slots)

Don't use for:

- Filtering/sorting/paging needs - use data-table
- Compact screens with many columns - restructure as a card list

Sizing: text-sm rows; wrap in a card for the border (class recipe) - no extra cell padding.

Responsive: Tables don't shrink gracefully: below medium, show fewer columns or switch to stacked cards/list rows.

iOS: A List with custom row layout; columns become labeled lines within the row.

## Specs

| Part | Description |
| --- | --- |
| Table | Native table element at text-sm. |
| Header | th cells in muted-foreground with medium weight. |
| Row | tbody rows with hairline borders; hover tints with muted. |

| Property | Value |
| --- | --- |
| Font | 0.875rem (text-sm) |
| Header color | var(--muted-foreground), weight 500 |
| Cell border | var(--border-color) |
| Row hover | var(--muted) background |

Tokens used: `muted-foreground`, `border-color`, `muted`, `foreground`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Move through any interactive cell content (links, buttons) |

Role / ARIA: Native table / thead / tbody / th / td with their implicit table roles. Header cells should scope columns; the demo uses semantic th elements.

Focus: The table itself is not focusable; interactive cell content keeps its own focus order and rings.

Screen reader: Table semantics let users navigate by row and column. Provide a caption or surrounding heading for context.

Touch target: Interactive cell content (action buttons/links) should meet the 44pt minimum on touch.

Reduced motion: Row hover tint is instant under the theme.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
Table(people) {
    TableColumn("Name", value: \.name)
    TableColumn("Email", value: \.email)
}
```

Table is full-featured on macOS/iPadOS; on iPhone a List of rows is the practical equivalent, so behavior differs by size class.

## Default

HEEx:

```heex
<.table id="invoices" rows={@invoices}>
  <:col :let={invoice} label="Invoice">{invoice.id}</:col>
  <:col :let={invoice} label="Status">{invoice.status}</:col>
  <:col :let={invoice} label="Method">{invoice.method}</:col>
  <:col :let={invoice} label="Amount">{invoice.amount}</:col>
</.table>
```

```html
<div class="card w-full overflow-hidden">
  <table class="table">
    <thead>
      <tr>
        <th>Invoice</th>
        <th>Status</th>
        <th>Method</th>
        <th class="text-right">Amount</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td class="font-medium">INV001</td>
        <td><span class="badge badge-secondary">Paid</span></td>
        <td>Credit Card</td>
        <td class="text-right">$250.00</td>
      </tr>
      <tr>
        <td class="font-medium">INV002</td>
        <td><span class="badge badge-outline">Pending</span></td>
        <td>PayPal</td>
        <td class="text-right">$150.00</td>
      </tr>
      <tr>
        <td class="font-medium">INV003</td>
        <td><span class="badge badge-error">Unpaid</span></td>
        <td>Bank Transfer</td>
        <td class="text-right">$350.00</td>
      </tr>
    </tbody>
  </table>
</div>
```
