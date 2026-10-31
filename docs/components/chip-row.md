# Chip Row

One line of removable chips: the ones that don't fit collapse into a +N chip that opens a popover listing them.

> Requires a JS hook: initialize with `initShadcnDaisyui()` (dead views) or the corresponding `Shadcn*` LiveView hook from `shadcn-daisyui.js`.

Needs the ShadcnChipRow hook (or initShadcnDaisyui()). In LiveView pass on_remove (e.g. JS.push("remove_filter", value: %{id: f.id})); the server drops the chip and the patch re-fits the row. Without it the hook removes the chip itself after a cancelable chip-remove event ({ value, index }) bubbles from the root; a data-chip-row-clear button does the same for every chip (chip-clear). After a removal focus moves to the chip that took its place, then +N, then the last chip. Motion: a chip added after mount scales and fades in (0.9 to 1, 150ms ease-out) and the chips after it slide over; a removed chip leaves the flow and scales and fades out where it stood while its neighbours slide into its place, and +N recounts once it is gone. Give every chip a value: the DOM id follows it, so a patch removes that chip and not the last one. In LiveView each chip (and the actions) carries a phx-remove that keeps it 180ms, the length of a reveal collapse, so a reveal closing in the same patch shrinks around the fading chip: keep the row rendered inside <.reveal open={@filters != []}> (no :if) and let open drive it. A chip with two or more items is a stack: the first value's name and +N, with card edges behind it (one for two values, two for more), and the inner block is the filter's name for screen readers. Its values open inline in the row, sliding out of the stack while the chips after it slide over: on hover (under @media (hover: hover), after a short pause, back about 150ms after the pointer leaves), keyboard focus (back when focus leaves, or on Esc) or a tap (a tap outside closes it). One is open at a time and the stack's face and × never move. The row stays on one line: chips after the stack fold into +N when there is no room, then the last values do, and +N opens by itself when no value fits (a phone). The stack's × clears the whole filter; a value's × removes that value, and focus moves to the next ×, or to the chip's × once one value is left.

## Usage guidance

Use when:

- Active filters above a list or table, each removable on its own
- Recipients, tags or selected values shown compactly in a toolbar or form
- Rows whose chip count varies and must stay one line high

Don't use for:

- Picking values - use <.select multiple> or <.combobox multiple>; the chip row shows the result
- Status labels that aren't removable - plain badges
- Every chip must always be visible - let them wrap (flex-wrap gap-2) instead

Sizing: Badge metrics (text-xs, rounded-full, py-0.5 px-2) with a 16px remove button; 32px chips on touch. The +N chip is an outline badge; the popover is floating content with p-3 and wrapping chips. 8px between chips.

Responsive: Always one line: compact screens show fewer chips and a larger +N. Trailing actions (Clear all) keep their space; the chips give way first.

iOS: A horizontal row of capsule buttons that ends in a "+N" button opening a sheet (or a List with swipe-to-delete) of the rest.

## Specs

| Part | Description |
| --- | --- |
| Row | role=group (aria-label) flex row, one line, fills its container. |
| Chip | A badge list item: label (truncates when it alone is too wide) + remove button. |
| Remove | 16px round icon button, 60% opacity, named "Remove <label>". |
| +N chip | Outline badge button (aria-expanded) whose name is "Show N more". |
| Popover | Floating panel of the collapsed chips (wrapping), each removable. |
| Stack | One chip for several values: opener (first name, +N) + remove button, card edges behind it. Counts as one chip when the row fits (closed); its values show flat in the popover. |
| Unstacked values | Each value as its own chip with a remove button, inline after the stack's face; slides out of the stack on open, and the next chips slide over. |
| Actions | Optional trailing content that always stays visible. |

| Property | Value |
| --- | --- |
| Chip | text-xs, py-0.5 px-2 (pe-1 with remove), rounded-full; 2rem min on touch |
| Remove button | 1rem (1.5rem on touch, 44px hit area) |
| Gap | 0.5rem between chips, +N and actions |
| Popover | p-3, max 18rem wide, max-h 16rem, 4px below +N |
| Stack edges | 4px each, 1px line, inside the chip's width |
| Unstacked values | 0.5rem gaps, in line with the row |

Tokens used: `chip-background`, `secondary-foreground`, `border-color`, `foreground`, `popover`, `accent`, `accent-foreground`, `ring`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab / Shift+Tab | Move through the remove buttons, +N and the actions |
| Enter / Space / Down | On +N: open the popover and focus its first remove button |
| Arrow keys, Home / End | Move between the remove buttons in the popover |
| Enter / Space | Remove the focused chip |
| Esc | Close the popover, focus +N |
| Tab onto a stack | Unstacks its values; Tab goes on: opener, its ×, then each value's × |
| Enter / Space on a stack | Stack or unstack it |
| Esc on a stack | Stack it again, focus its opener |

Role / ARIA: The row is role=group with a name; chips are a list, so a screen reader announces how many are visible. Each remove button is named "Remove" plus the chip text (aria-labelledby), or remove_label. +N is a disclosure button (aria-expanded, aria-controls) labelled "Show N more".

Focus: Removing a chip never drops focus to the page: it lands on the chip that took its place, the previous one, +N, or the first action.

Screen reader: Hidden copies are display:none, so each chip is announced once, in the row or in the popover. The list length tells how many chips are visible; +N says how many more there are.

Touch target: On coarse pointers chips are 32px and the remove button and +N reach a 44px hit area through an invisible pseudo-element inside the 8px gap.

Reduced motion: Chips scale and fade in and out and their neighbours slide (transform and opacity only); under reduced motion all of it is instant. Wrap the row in <.reveal> to slide it in and out (also instant under reduced motion).

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
ViewThatFits(in: .horizontal) {
    ForEach(0...filters.count, id: \.self) { hidden in   // fewest hidden first
        HStack(spacing: 8) {
            ForEach(filters.dropLast(hidden)) { f in
                Button { remove(f) } label: {
                    Label(f.title, systemImage: "xmark").labelStyle(.titleAndIcon)
                }
                .buttonStyle(.bordered).buttonBorderShape(.capsule).controlSize(.small)
                .accessibilityLabel("Remove \(f.title)")
            }
            if hidden > 0 {
                Button("+\(hidden)") { showAll = true }
                    .buttonStyle(.bordered).buttonBorderShape(.capsule).controlSize(.small)
                    .accessibilityLabel("Show \(hidden) more")
            }
        }
        .fixedSize()
    }
}
```

ViewThatFits picks the first candidate that fits, which reproduces the fitting rule. Show the rest in a sheet with a List and swipe-to-delete (or EditButton).

## Props

| Name | Type | Default |
| --- | --- | --- |
| id | string (required) | - |
| aria_label | string | "Chips" |
| variant | secondary \| outline | secondary |
| more_label | string ({count}) | "Show {count} more" |
| :chip value | any | nil |
| :chip on_remove | event name \| JS | nil |
| :chip remove_label | string | "Remove" + chip text |
| :chip removable | boolean | true |
| :chip items | [%{value, label, on_remove}] (optional removable, remove_label) | nil |
| :action | slot | - |

## Active filters

HEEx:

```heex
<.chip_row id="active-filters" aria-label="Active filters">
  <:chip :for={f <- @filters} value={f.id} on_remove={JS.push("remove_filter", value: %{id: f.id})}>
    {f.field}: {f.label}
  </:chip>
  <:action>
    <button type="button" class="btn btn-ghost btn-sm" phx-click="clear_filters">Clear all</button>
  </:action>
</.chip_row>
```

```html
<div id="active-filters" data-chip-row role="group" aria-label="Active filters" class="chip-row">
  <ul class="chip-row-chips" data-chip-row-chips>
    <li class="badge chip badge-secondary" data-index="0" data-value="status:todo" data-chip><span id="active-filters-chip-0-label" class="chip-label">Status: Todo</span><button type="button" id="active-filters-chip-0-remove" class="chip-remove" aria-label="Remove" aria-labelledby="active-filters-chip-0-remove active-filters-chip-0-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
    <li class="badge chip badge-secondary" data-index="1" data-value="status:in-progress" data-chip><span id="active-filters-chip-1-label" class="chip-label">Status: In progress</span><button type="button" id="active-filters-chip-1-remove" class="chip-remove" aria-label="Remove" aria-labelledby="active-filters-chip-1-remove active-filters-chip-1-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
    <li class="badge chip badge-secondary" data-index="2" data-value="priority:high" data-chip><span id="active-filters-chip-2-label" class="chip-label">Priority: High</span><button type="button" id="active-filters-chip-2-remove" class="chip-remove" aria-label="Remove" aria-labelledby="active-filters-chip-2-remove active-filters-chip-2-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
    <li class="badge chip badge-secondary" data-index="3" data-value="label:bug" data-chip><span id="active-filters-chip-3-label" class="chip-label">Label: Bug</span><button type="button" id="active-filters-chip-3-remove" class="chip-remove" aria-label="Remove" aria-labelledby="active-filters-chip-3-remove active-filters-chip-3-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
    <li class="badge chip badge-secondary" data-index="4" data-value="label:frontend" data-chip><span id="active-filters-chip-4-label" class="chip-label">Label: Frontend</span><button type="button" id="active-filters-chip-4-remove" class="chip-remove" aria-label="Remove" aria-labelledby="active-filters-chip-4-remove active-filters-chip-4-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
    <li class="badge chip badge-secondary" data-index="5" data-value="assignee:me" data-chip><span id="active-filters-chip-5-label" class="chip-label">Assignee: Me</span><button type="button" id="active-filters-chip-5-remove" class="chip-remove" aria-label="Remove" aria-labelledby="active-filters-chip-5-remove active-filters-chip-5-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
    <li class="badge chip badge-secondary" data-index="6" data-value="created:7d" data-chip><span id="active-filters-chip-6-label" class="chip-label">Created: Last 7 days</span><button type="button" id="active-filters-chip-6-remove" class="chip-remove" aria-label="Remove" aria-labelledby="active-filters-chip-6-remove active-filters-chip-6-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
  </ul>
  <div class="chip-row-more" data-chip-row-more hidden>
    <button type="button" class="badge badge-outline chip chip-more" aria-expanded="false" aria-controls="active-filters-overflow" data-chip-row-trigger data-more-label="Show {count} more"></button>
    <div id="active-filters-overflow" class="popover-panel chip-row-panel" data-chip-row-panel hidden>
      <ul class="flex flex-wrap gap-2" aria-label="Active filters">
        <li class="badge chip badge-secondary" data-index="0" data-value="status:todo" hidden data-chip-copy><span id="active-filters-copy-0-label" class="chip-label">Status: Todo</span><button type="button" id="active-filters-copy-0-remove" class="chip-remove" aria-label="Remove" aria-labelledby="active-filters-copy-0-remove active-filters-copy-0-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
        <li class="badge chip badge-secondary" data-index="1" data-value="status:in-progress" hidden data-chip-copy><span id="active-filters-copy-1-label" class="chip-label">Status: In progress</span><button type="button" id="active-filters-copy-1-remove" class="chip-remove" aria-label="Remove" aria-labelledby="active-filters-copy-1-remove active-filters-copy-1-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
        <li class="badge chip badge-secondary" data-index="2" data-value="priority:high" hidden data-chip-copy><span id="active-filters-copy-2-label" class="chip-label">Priority: High</span><button type="button" id="active-filters-copy-2-remove" class="chip-remove" aria-label="Remove" aria-labelledby="active-filters-copy-2-remove active-filters-copy-2-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
        <li class="badge chip badge-secondary" data-index="3" data-value="label:bug" hidden data-chip-copy><span id="active-filters-copy-3-label" class="chip-label">Label: Bug</span><button type="button" id="active-filters-copy-3-remove" class="chip-remove" aria-label="Remove" aria-labelledby="active-filters-copy-3-remove active-filters-copy-3-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
        <li class="badge chip badge-secondary" data-index="4" data-value="label:frontend" hidden data-chip-copy><span id="active-filters-copy-4-label" class="chip-label">Label: Frontend</span><button type="button" id="active-filters-copy-4-remove" class="chip-remove" aria-label="Remove" aria-labelledby="active-filters-copy-4-remove active-filters-copy-4-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
        <li class="badge chip badge-secondary" data-index="5" data-value="assignee:me" hidden data-chip-copy><span id="active-filters-copy-5-label" class="chip-label">Assignee: Me</span><button type="button" id="active-filters-copy-5-remove" class="chip-remove" aria-label="Remove" aria-labelledby="active-filters-copy-5-remove active-filters-copy-5-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
        <li class="badge chip badge-secondary" data-index="6" data-value="created:7d" hidden data-chip-copy><span id="active-filters-copy-6-label" class="chip-label">Created: Last 7 days</span><button type="button" id="active-filters-copy-6-remove" class="chip-remove" aria-label="Remove" aria-labelledby="active-filters-copy-6-remove active-filters-copy-6-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
      </ul>
    </div>
  </div>
  <div class="chip-row-actions" data-chip-row-actions>
    <button type="button" class="btn btn-ghost btn-sm" data-chip-row-clear>Clear all</button>
  </div>
</div>
```

## Stacked filters

HEEx:

```heex
<.chip_row id="stacked-filters" aria_label="Active filters">
  <%!-- one value: a normal chip --%>
  <:chip value="owner" on_remove="clear_owner">Pat Lee</:chip>
  <%!-- two or more: a stack; the inner block names the filter for screen readers --%>
  <:chip
    value="status"
    on_remove="clear_status"
    items={for s <- @statuses, do: %{value: s.id, label: s.label, on_remove: JS.push("remove_status", value: %{id: s.id})}}
  >
    Status
  </:chip>
  <:chip
    value="brands"
    on_remove="clear_brands"
    items={for b <- @brands, do: %{value: b.id, label: b.name, on_remove: JS.push("remove_brand", value: %{id: b.id})}}
  >
    Brands
  </:chip>
</.chip_row>
```

```html
<div class="w-full">
  <div id="stacked-filters" data-chip-row role="group" aria-label="Active filters" class="chip-row">
    <ul class="chip-row-chips" data-chip-row-chips>
      <li id="stacked-filters-chip-v-owner" class="badge chip badge-secondary" data-index="0" data-value="owner" phx-remove="[[&quot;dispatch&quot;,{&quot;event&quot;:&quot;chip-exit&quot;}],[&quot;transition&quot;,{&quot;time&quot;:180,&quot;transition&quot;:[[&quot;chip-exit&quot;],[],[]]}]]" data-chip>
        <span id="stacked-filters-chip-v-owner-label" class="chip-label">Pat Lee</span>
        <button type="button" id="stacked-filters-chip-v-owner-remove" class="chip-remove" aria-label="Remove" aria-labelledby="stacked-filters-chip-v-owner-remove stacked-filters-chip-v-owner-label" data-chip-remove>
          <span class="hero-x-mark size-3" aria-hidden="true"></span>
        </button>
      </li>
      <li id="stacked-filters-chip-v-status" class="chip-stack" data-index="1" data-value="status" data-edges="1" phx-remove="[[&quot;dispatch&quot;,{&quot;event&quot;:&quot;chip-exit&quot;}],[&quot;transition&quot;,{&quot;time&quot;:180,&quot;transition&quot;:[[&quot;chip-exit&quot;],[],[]]}]]" data-chip data-chip-stack>
        <div class="badge chip chip-stack-front badge-secondary" data-chip-stack-front>
          <button type="button" id="stacked-filters-chip-v-status-open" class="chip-stack-open" aria-expanded="false" aria-controls="stacked-filters-chip-v-status-values" data-chip-stack-open>
            <span class="chip-label chip-stack-name" aria-hidden="true" data-chip-stack-name>Open</span>
            <span class="chip-stack-count" aria-hidden="true" data-chip-stack-count>+1</span>
            <span class="sr-only"><span id="stacked-filters-chip-v-status-name">Status</span>: <span data-chip-stack-values>Open, Paid</span></span>
          </button>
          <button type="button" id="stacked-filters-chip-v-status-remove" class="chip-remove" aria-label="Remove" aria-labelledby="stacked-filters-chip-v-status-remove stacked-filters-chip-v-status-name" data-chip-remove>
            <span class="hero-x-mark size-3" aria-hidden="true"></span>
          </button>
        </div>
        <ul id="stacked-filters-chip-v-status-values" class="chip-stack-values" aria-labelledby="stacked-filters-chip-v-status-name" hidden data-chip-stack-list>
          <li id="stacked-filters-chip-v-status-value-v-open" class="badge chip badge-secondary" data-index="1" data-value="open" data-chip-of="status" phx-remove="[[&quot;dispatch&quot;,{&quot;event&quot;:&quot;chip-exit&quot;}],[&quot;transition&quot;,{&quot;time&quot;:180,&quot;transition&quot;:[[&quot;chip-exit&quot;],[],[]]}]]" data-chip-value>
            <span id="stacked-filters-chip-v-status-value-v-open-label" class="chip-label">Open</span>
            <button type="button" id="stacked-filters-chip-v-status-value-v-open-remove" class="chip-remove" aria-label="Remove" aria-labelledby="stacked-filters-chip-v-status-value-v-open-remove stacked-filters-chip-v-status-value-v-open-label" data-chip-remove>
              <span class="hero-x-mark size-3" aria-hidden="true"></span>
            </button>
          </li>
          <li id="stacked-filters-chip-v-status-value-v-paid" class="badge chip badge-secondary" data-index="1" data-value="paid" data-chip-of="status" phx-remove="[[&quot;dispatch&quot;,{&quot;event&quot;:&quot;chip-exit&quot;}],[&quot;transition&quot;,{&quot;time&quot;:180,&quot;transition&quot;:[[&quot;chip-exit&quot;],[],[]]}]]" data-chip-value>
            <span id="stacked-filters-chip-v-status-value-v-paid-label" class="chip-label">Paid</span>
            <button type="button" id="stacked-filters-chip-v-status-value-v-paid-remove" class="chip-remove" aria-label="Remove" aria-labelledby="stacked-filters-chip-v-status-value-v-paid-remove stacked-filters-chip-v-status-value-v-paid-label" data-chip-remove>
              <span class="hero-x-mark size-3" aria-hidden="true"></span>
            </button>
          </li>
        </ul>
      </li>
      <li id="stacked-filters-chip-v-brands" class="chip-stack" data-index="2" data-value="brands" data-edges="2" phx-remove="[[&quot;dispatch&quot;,{&quot;event&quot;:&quot;chip-exit&quot;}],[&quot;transition&quot;,{&quot;time&quot;:180,&quot;transition&quot;:[[&quot;chip-exit&quot;],[],[]]}]]" data-chip data-chip-stack>
        <div class="badge chip chip-stack-front badge-secondary" data-chip-stack-front>
          <button type="button" id="stacked-filters-chip-v-brands-open" class="chip-stack-open" aria-expanded="false" aria-controls="stacked-filters-chip-v-brands-values" data-chip-stack-open>
            <span class="chip-label chip-stack-name" aria-hidden="true" data-chip-stack-name>Acme sandbox</span>
            <span class="chip-stack-count" aria-hidden="true" data-chip-stack-count>+3</span>
            <span class="sr-only"><span id="stacked-filters-chip-v-brands-name">Brands</span>: <span data-chip-stack-values>Acme sandbox, Northwind, Northwind sandbox, Northgate</span></span>
          </button>
          <button type="button" id="stacked-filters-chip-v-brands-remove" class="chip-remove" aria-label="Remove" aria-labelledby="stacked-filters-chip-v-brands-remove stacked-filters-chip-v-brands-name" data-chip-remove>
            <span class="hero-x-mark size-3" aria-hidden="true"></span>
          </button>
        </div>
        <ul id="stacked-filters-chip-v-brands-values" class="chip-stack-values" aria-labelledby="stacked-filters-chip-v-brands-name" hidden data-chip-stack-list>
          <li id="stacked-filters-chip-v-brands-value-v-acme" class="badge chip badge-secondary" data-index="2" data-value="acme" data-chip-of="brands" phx-remove="[[&quot;dispatch&quot;,{&quot;event&quot;:&quot;chip-exit&quot;}],[&quot;transition&quot;,{&quot;time&quot;:180,&quot;transition&quot;:[[&quot;chip-exit&quot;],[],[]]}]]" data-chip-value>
            <span id="stacked-filters-chip-v-brands-value-v-acme-label" class="chip-label">Acme sandbox</span>
            <button type="button" id="stacked-filters-chip-v-brands-value-v-acme-remove" class="chip-remove" aria-label="Remove" aria-labelledby="stacked-filters-chip-v-brands-value-v-acme-remove stacked-filters-chip-v-brands-value-v-acme-label" data-chip-remove>
              <span class="hero-x-mark size-3" aria-hidden="true"></span>
            </button>
          </li>
          <li id="stacked-filters-chip-v-brands-value-v-northwind" class="badge chip badge-secondary" data-index="2" data-value="northwind" data-chip-of="brands" phx-remove="[[&quot;dispatch&quot;,{&quot;event&quot;:&quot;chip-exit&quot;}],[&quot;transition&quot;,{&quot;time&quot;:180,&quot;transition&quot;:[[&quot;chip-exit&quot;],[],[]]}]]" data-chip-value>
            <span id="stacked-filters-chip-v-brands-value-v-northwind-label" class="chip-label">Northwind</span>
            <button type="button" id="stacked-filters-chip-v-brands-value-v-northwind-remove" class="chip-remove" aria-label="Remove" aria-labelledby="stacked-filters-chip-v-brands-value-v-northwind-remove stacked-filters-chip-v-brands-value-v-northwind-label" data-chip-remove>
              <span class="hero-x-mark size-3" aria-hidden="true"></span>
            </button>
          </li>
          <li id="stacked-filters-chip-v-brands-value-v-northwind-sandbox" class="badge chip badge-secondary" data-index="2" data-value="northwind-sandbox" data-chip-of="brands" phx-remove="[[&quot;dispatch&quot;,{&quot;event&quot;:&quot;chip-exit&quot;}],[&quot;transition&quot;,{&quot;time&quot;:180,&quot;transition&quot;:[[&quot;chip-exit&quot;],[],[]]}]]" data-chip-value>
            <span id="stacked-filters-chip-v-brands-value-v-northwind-sandbox-label" class="chip-label">Northwind sandbox</span>
            <button type="button" id="stacked-filters-chip-v-brands-value-v-northwind-sandbox-remove" class="chip-remove" aria-label="Remove" aria-labelledby="stacked-filters-chip-v-brands-value-v-northwind-sandbox-remove stacked-filters-chip-v-brands-value-v-northwind-sandbox-label" data-chip-remove>
              <span class="hero-x-mark size-3" aria-hidden="true"></span>
            </button>
          </li>
          <li id="stacked-filters-chip-v-brands-value-v-northgate" class="badge chip badge-secondary" data-index="2" data-value="northgate" data-chip-of="brands" phx-remove="[[&quot;dispatch&quot;,{&quot;event&quot;:&quot;chip-exit&quot;}],[&quot;transition&quot;,{&quot;time&quot;:180,&quot;transition&quot;:[[&quot;chip-exit&quot;],[],[]]}]]" data-chip-value>
            <span id="stacked-filters-chip-v-brands-value-v-northgate-label" class="chip-label">Northgate</span>
            <button type="button" id="stacked-filters-chip-v-brands-value-v-northgate-remove" class="chip-remove" aria-label="Remove" aria-labelledby="stacked-filters-chip-v-brands-value-v-northgate-remove stacked-filters-chip-v-brands-value-v-northgate-label" data-chip-remove>
              <span class="hero-x-mark size-3" aria-hidden="true"></span>
            </button>
          </li>
        </ul>
      </li>
    </ul>
    <div class="chip-row-more" data-chip-row-more hidden>
      <button type="button" class="badge badge-outline chip chip-more" aria-expanded="false" aria-controls="stacked-filters-overflow" data-chip-row-trigger data-more-label="Show {count} more">
      </button>
      <div id="stacked-filters-overflow" class="popover-panel chip-row-panel" data-chip-row-panel hidden>
        <ul class="flex flex-wrap gap-2" aria-label="Active filters">
          <li id="stacked-filters-copy-v-owner" class="badge chip badge-secondary" data-index="0" data-value="owner" hidden phx-remove="[[&quot;dispatch&quot;,{&quot;event&quot;:&quot;chip-exit&quot;}],[&quot;transition&quot;,{&quot;time&quot;:180,&quot;transition&quot;:[[&quot;chip-exit&quot;],[],[]]}]]" data-chip-copy>
            <span id="stacked-filters-copy-v-owner-label" class="chip-label">Pat Lee</span>
            <button type="button" id="stacked-filters-copy-v-owner-remove" class="chip-remove" aria-label="Remove" aria-labelledby="stacked-filters-copy-v-owner-remove stacked-filters-copy-v-owner-label" data-chip-remove>
              <span class="hero-x-mark size-3" aria-hidden="true"></span>
            </button>
          </li>
          <li id="stacked-filters-copy-v-status-v-open" class="badge chip badge-secondary" data-index="1" data-value="open" data-chip-of="status" hidden phx-remove="[[&quot;dispatch&quot;,{&quot;event&quot;:&quot;chip-exit&quot;}],[&quot;transition&quot;,{&quot;time&quot;:180,&quot;transition&quot;:[[&quot;chip-exit&quot;],[],[]]}]]" data-chip-value data-chip-copy>
            <span id="stacked-filters-copy-v-status-v-open-label" class="chip-label">Open</span>
            <button type="button" id="stacked-filters-copy-v-status-v-open-remove" class="chip-remove" aria-label="Remove" aria-labelledby="stacked-filters-copy-v-status-v-open-remove stacked-filters-copy-v-status-v-open-label" data-chip-remove>
              <span class="hero-x-mark size-3" aria-hidden="true"></span>
            </button>
          </li>
          <li id="stacked-filters-copy-v-status-v-paid" class="badge chip badge-secondary" data-index="1" data-value="paid" data-chip-of="status" hidden phx-remove="[[&quot;dispatch&quot;,{&quot;event&quot;:&quot;chip-exit&quot;}],[&quot;transition&quot;,{&quot;time&quot;:180,&quot;transition&quot;:[[&quot;chip-exit&quot;],[],[]]}]]" data-chip-value data-chip-copy>
            <span id="stacked-filters-copy-v-status-v-paid-label" class="chip-label">Paid</span>
            <button type="button" id="stacked-filters-copy-v-status-v-paid-remove" class="chip-remove" aria-label="Remove" aria-labelledby="stacked-filters-copy-v-status-v-paid-remove stacked-filters-copy-v-status-v-paid-label" data-chip-remove>
              <span class="hero-x-mark size-3" aria-hidden="true"></span>
            </button>
          </li>
          <li id="stacked-filters-copy-v-brands-v-acme" class="badge chip badge-secondary" data-index="2" data-value="acme" data-chip-of="brands" hidden phx-remove="[[&quot;dispatch&quot;,{&quot;event&quot;:&quot;chip-exit&quot;}],[&quot;transition&quot;,{&quot;time&quot;:180,&quot;transition&quot;:[[&quot;chip-exit&quot;],[],[]]}]]" data-chip-value data-chip-copy>
            <span id="stacked-filters-copy-v-brands-v-acme-label" class="chip-label">Acme sandbox</span>
            <button type="button" id="stacked-filters-copy-v-brands-v-acme-remove" class="chip-remove" aria-label="Remove" aria-labelledby="stacked-filters-copy-v-brands-v-acme-remove stacked-filters-copy-v-brands-v-acme-label" data-chip-remove>
              <span class="hero-x-mark size-3" aria-hidden="true"></span>
            </button>
          </li>
          <li id="stacked-filters-copy-v-brands-v-northwind" class="badge chip badge-secondary" data-index="2" data-value="northwind" data-chip-of="brands" hidden phx-remove="[[&quot;dispatch&quot;,{&quot;event&quot;:&quot;chip-exit&quot;}],[&quot;transition&quot;,{&quot;time&quot;:180,&quot;transition&quot;:[[&quot;chip-exit&quot;],[],[]]}]]" data-chip-value data-chip-copy>
            <span id="stacked-filters-copy-v-brands-v-northwind-label" class="chip-label">Northwind</span>
            <button type="button" id="stacked-filters-copy-v-brands-v-northwind-remove" class="chip-remove" aria-label="Remove" aria-labelledby="stacked-filters-copy-v-brands-v-northwind-remove stacked-filters-copy-v-brands-v-northwind-label" data-chip-remove>
              <span class="hero-x-mark size-3" aria-hidden="true"></span>
            </button>
          </li>
          <li id="stacked-filters-copy-v-brands-v-northwind-sandbox" class="badge chip badge-secondary" data-index="2" data-value="northwind-sandbox" data-chip-of="brands" hidden phx-remove="[[&quot;dispatch&quot;,{&quot;event&quot;:&quot;chip-exit&quot;}],[&quot;transition&quot;,{&quot;time&quot;:180,&quot;transition&quot;:[[&quot;chip-exit&quot;],[],[]]}]]" data-chip-value data-chip-copy>
            <span id="stacked-filters-copy-v-brands-v-northwind-sandbox-label" class="chip-label">Northwind sandbox</span>
            <button type="button" id="stacked-filters-copy-v-brands-v-northwind-sandbox-remove" class="chip-remove" aria-label="Remove" aria-labelledby="stacked-filters-copy-v-brands-v-northwind-sandbox-remove stacked-filters-copy-v-brands-v-northwind-sandbox-label" data-chip-remove>
              <span class="hero-x-mark size-3" aria-hidden="true"></span>
            </button>
          </li>
          <li id="stacked-filters-copy-v-brands-v-northgate" class="badge chip badge-secondary" data-index="2" data-value="northgate" data-chip-of="brands" hidden phx-remove="[[&quot;dispatch&quot;,{&quot;event&quot;:&quot;chip-exit&quot;}],[&quot;transition&quot;,{&quot;time&quot;:180,&quot;transition&quot;:[[&quot;chip-exit&quot;],[],[]]}]]" data-chip-value data-chip-copy>
            <span id="stacked-filters-copy-v-brands-v-northgate-label" class="chip-label">Northgate</span>
            <button type="button" id="stacked-filters-copy-v-brands-v-northgate-remove" class="chip-remove" aria-label="Remove" aria-labelledby="stacked-filters-copy-v-brands-v-northgate-remove stacked-filters-copy-v-brands-v-northgate-label" data-chip-remove>
              <span class="hero-x-mark size-3" aria-hidden="true"></span>
            </button>
          </li>
        </ul>
      </div>
    </div>
  </div>
</div>
```

## A stack in a row that overflows

HEEx:

```heex
<%!-- a stack counts as one chip; in +N its values show flat, each removable --%>
<div class="w-full max-w-xs">
  <.chip_row id="stacked-overflow" aria_label="Active filters">
    <:chip value="status" items={@statuses}>Status</:chip>
    <:chip value="brands" items={@brands}>Brands</:chip>
    <:chip value="owner">Owner: Pat Lee</:chip>
    <:chip value="region">Region: North</:chip>
  </.chip_row>
</div>
```

```html
<div class="w-full max-w-xs">
  <div id="stacked-overflow" data-chip-row role="group" aria-label="Active filters" class="chip-row">
    <ul class="chip-row-chips" data-chip-row-chips>
      <li id="stacked-overflow-chip-v-status" class="chip-stack" data-index="0" data-value="status" data-edges="1" phx-remove="[[&quot;dispatch&quot;,{&quot;event&quot;:&quot;chip-exit&quot;}],[&quot;transition&quot;,{&quot;time&quot;:180,&quot;transition&quot;:[[&quot;chip-exit&quot;],[],[]]}]]" data-chip data-chip-stack>
        <div class="badge chip chip-stack-front badge-secondary" data-chip-stack-front>
          <button type="button" id="stacked-overflow-chip-v-status-open" class="chip-stack-open" aria-expanded="false" aria-controls="stacked-overflow-chip-v-status-values" data-chip-stack-open>
            <span class="chip-label chip-stack-name" aria-hidden="true" data-chip-stack-name>Open</span>
            <span class="chip-stack-count" aria-hidden="true" data-chip-stack-count>+1</span>
            <span class="sr-only"><span id="stacked-overflow-chip-v-status-name">Status</span>: <span data-chip-stack-values>Open, Paid</span></span>
          </button>
          <button type="button" id="stacked-overflow-chip-v-status-remove" class="chip-remove" aria-label="Remove" aria-labelledby="stacked-overflow-chip-v-status-remove stacked-overflow-chip-v-status-name" data-chip-remove>
            <span class="hero-x-mark size-3" aria-hidden="true"></span>
          </button>
        </div>
        <ul id="stacked-overflow-chip-v-status-values" class="chip-stack-values" aria-labelledby="stacked-overflow-chip-v-status-name" hidden data-chip-stack-list>
          <li id="stacked-overflow-chip-v-status-value-v-open" class="badge chip badge-secondary" data-index="0" data-value="open" data-chip-of="status" phx-remove="[[&quot;dispatch&quot;,{&quot;event&quot;:&quot;chip-exit&quot;}],[&quot;transition&quot;,{&quot;time&quot;:180,&quot;transition&quot;:[[&quot;chip-exit&quot;],[],[]]}]]" data-chip-value>
            <span id="stacked-overflow-chip-v-status-value-v-open-label" class="chip-label">Open</span>
            <button type="button" id="stacked-overflow-chip-v-status-value-v-open-remove" class="chip-remove" aria-label="Remove" aria-labelledby="stacked-overflow-chip-v-status-value-v-open-remove stacked-overflow-chip-v-status-value-v-open-label" data-chip-remove>
              <span class="hero-x-mark size-3" aria-hidden="true"></span>
            </button>
          </li>
          <li id="stacked-overflow-chip-v-status-value-v-paid" class="badge chip badge-secondary" data-index="0" data-value="paid" data-chip-of="status" phx-remove="[[&quot;dispatch&quot;,{&quot;event&quot;:&quot;chip-exit&quot;}],[&quot;transition&quot;,{&quot;time&quot;:180,&quot;transition&quot;:[[&quot;chip-exit&quot;],[],[]]}]]" data-chip-value>
            <span id="stacked-overflow-chip-v-status-value-v-paid-label" class="chip-label">Paid</span>
            <button type="button" id="stacked-overflow-chip-v-status-value-v-paid-remove" class="chip-remove" aria-label="Remove" aria-labelledby="stacked-overflow-chip-v-status-value-v-paid-remove stacked-overflow-chip-v-status-value-v-paid-label" data-chip-remove>
              <span class="hero-x-mark size-3" aria-hidden="true"></span>
            </button>
          </li>
        </ul>
      </li>
      <li id="stacked-overflow-chip-v-brands" class="chip-stack" data-index="1" data-value="brands" data-edges="2" phx-remove="[[&quot;dispatch&quot;,{&quot;event&quot;:&quot;chip-exit&quot;}],[&quot;transition&quot;,{&quot;time&quot;:180,&quot;transition&quot;:[[&quot;chip-exit&quot;],[],[]]}]]" data-chip data-chip-stack>
        <div class="badge chip chip-stack-front badge-secondary" data-chip-stack-front>
          <button type="button" id="stacked-overflow-chip-v-brands-open" class="chip-stack-open" aria-expanded="false" aria-controls="stacked-overflow-chip-v-brands-values" data-chip-stack-open>
            <span class="chip-label chip-stack-name" aria-hidden="true" data-chip-stack-name>Acme sandbox</span>
            <span class="chip-stack-count" aria-hidden="true" data-chip-stack-count>+3</span>
            <span class="sr-only"><span id="stacked-overflow-chip-v-brands-name">Brands</span>: <span data-chip-stack-values>Acme sandbox, Northwind, Northwind sandbox, Northgate</span></span>
          </button>
          <button type="button" id="stacked-overflow-chip-v-brands-remove" class="chip-remove" aria-label="Remove" aria-labelledby="stacked-overflow-chip-v-brands-remove stacked-overflow-chip-v-brands-name" data-chip-remove>
            <span class="hero-x-mark size-3" aria-hidden="true"></span>
          </button>
        </div>
        <ul id="stacked-overflow-chip-v-brands-values" class="chip-stack-values" aria-labelledby="stacked-overflow-chip-v-brands-name" hidden data-chip-stack-list>
          <li id="stacked-overflow-chip-v-brands-value-v-acme" class="badge chip badge-secondary" data-index="1" data-value="acme" data-chip-of="brands" phx-remove="[[&quot;dispatch&quot;,{&quot;event&quot;:&quot;chip-exit&quot;}],[&quot;transition&quot;,{&quot;time&quot;:180,&quot;transition&quot;:[[&quot;chip-exit&quot;],[],[]]}]]" data-chip-value>
            <span id="stacked-overflow-chip-v-brands-value-v-acme-label" class="chip-label">Acme sandbox</span>
            <button type="button" id="stacked-overflow-chip-v-brands-value-v-acme-remove" class="chip-remove" aria-label="Remove" aria-labelledby="stacked-overflow-chip-v-brands-value-v-acme-remove stacked-overflow-chip-v-brands-value-v-acme-label" data-chip-remove>
              <span class="hero-x-mark size-3" aria-hidden="true"></span>
            </button>
          </li>
          <li id="stacked-overflow-chip-v-brands-value-v-northwind" class="badge chip badge-secondary" data-index="1" data-value="northwind" data-chip-of="brands" phx-remove="[[&quot;dispatch&quot;,{&quot;event&quot;:&quot;chip-exit&quot;}],[&quot;transition&quot;,{&quot;time&quot;:180,&quot;transition&quot;:[[&quot;chip-exit&quot;],[],[]]}]]" data-chip-value>
            <span id="stacked-overflow-chip-v-brands-value-v-northwind-label" class="chip-label">Northwind</span>
            <button type="button" id="stacked-overflow-chip-v-brands-value-v-northwind-remove" class="chip-remove" aria-label="Remove" aria-labelledby="stacked-overflow-chip-v-brands-value-v-northwind-remove stacked-overflow-chip-v-brands-value-v-northwind-label" data-chip-remove>
              <span class="hero-x-mark size-3" aria-hidden="true"></span>
            </button>
          </li>
          <li id="stacked-overflow-chip-v-brands-value-v-northwind-sandbox" class="badge chip badge-secondary" data-index="1" data-value="northwind-sandbox" data-chip-of="brands" phx-remove="[[&quot;dispatch&quot;,{&quot;event&quot;:&quot;chip-exit&quot;}],[&quot;transition&quot;,{&quot;time&quot;:180,&quot;transition&quot;:[[&quot;chip-exit&quot;],[],[]]}]]" data-chip-value>
            <span id="stacked-overflow-chip-v-brands-value-v-northwind-sandbox-label" class="chip-label">Northwind sandbox</span>
            <button type="button" id="stacked-overflow-chip-v-brands-value-v-northwind-sandbox-remove" class="chip-remove" aria-label="Remove" aria-labelledby="stacked-overflow-chip-v-brands-value-v-northwind-sandbox-remove stacked-overflow-chip-v-brands-value-v-northwind-sandbox-label" data-chip-remove>
              <span class="hero-x-mark size-3" aria-hidden="true"></span>
            </button>
          </li>
          <li id="stacked-overflow-chip-v-brands-value-v-northgate" class="badge chip badge-secondary" data-index="1" data-value="northgate" data-chip-of="brands" phx-remove="[[&quot;dispatch&quot;,{&quot;event&quot;:&quot;chip-exit&quot;}],[&quot;transition&quot;,{&quot;time&quot;:180,&quot;transition&quot;:[[&quot;chip-exit&quot;],[],[]]}]]" data-chip-value>
            <span id="stacked-overflow-chip-v-brands-value-v-northgate-label" class="chip-label">Northgate</span>
            <button type="button" id="stacked-overflow-chip-v-brands-value-v-northgate-remove" class="chip-remove" aria-label="Remove" aria-labelledby="stacked-overflow-chip-v-brands-value-v-northgate-remove stacked-overflow-chip-v-brands-value-v-northgate-label" data-chip-remove>
              <span class="hero-x-mark size-3" aria-hidden="true"></span>
            </button>
          </li>
        </ul>
      </li>
      <li id="stacked-overflow-chip-v-owner" class="badge chip badge-secondary" data-index="2" data-value="owner" phx-remove="[[&quot;dispatch&quot;,{&quot;event&quot;:&quot;chip-exit&quot;}],[&quot;transition&quot;,{&quot;time&quot;:180,&quot;transition&quot;:[[&quot;chip-exit&quot;],[],[]]}]]" data-chip>
        <span id="stacked-overflow-chip-v-owner-label" class="chip-label">Owner: Pat Lee</span>
        <button type="button" id="stacked-overflow-chip-v-owner-remove" class="chip-remove" aria-label="Remove" aria-labelledby="stacked-overflow-chip-v-owner-remove stacked-overflow-chip-v-owner-label" data-chip-remove>
          <span class="hero-x-mark size-3" aria-hidden="true"></span>
        </button>
      </li>
      <li id="stacked-overflow-chip-v-region" class="badge chip badge-secondary" data-index="3" data-value="region" phx-remove="[[&quot;dispatch&quot;,{&quot;event&quot;:&quot;chip-exit&quot;}],[&quot;transition&quot;,{&quot;time&quot;:180,&quot;transition&quot;:[[&quot;chip-exit&quot;],[],[]]}]]" data-chip>
        <span id="stacked-overflow-chip-v-region-label" class="chip-label">Region: North</span>
        <button type="button" id="stacked-overflow-chip-v-region-remove" class="chip-remove" aria-label="Remove" aria-labelledby="stacked-overflow-chip-v-region-remove stacked-overflow-chip-v-region-label" data-chip-remove>
          <span class="hero-x-mark size-3" aria-hidden="true"></span>
        </button>
      </li>
    </ul>
    <div class="chip-row-more" data-chip-row-more hidden>
      <button type="button" class="badge badge-outline chip chip-more" aria-expanded="false" aria-controls="stacked-overflow-overflow" data-chip-row-trigger data-more-label="Show {count} more">
      </button>
      <div id="stacked-overflow-overflow" class="popover-panel chip-row-panel" data-chip-row-panel hidden>
        <ul class="flex flex-wrap gap-2" aria-label="Active filters">
          <li id="stacked-overflow-copy-v-status-v-open" class="badge chip badge-secondary" data-index="0" data-value="open" data-chip-of="status" hidden phx-remove="[[&quot;dispatch&quot;,{&quot;event&quot;:&quot;chip-exit&quot;}],[&quot;transition&quot;,{&quot;time&quot;:180,&quot;transition&quot;:[[&quot;chip-exit&quot;],[],[]]}]]" data-chip-value data-chip-copy>
            <span id="stacked-overflow-copy-v-status-v-open-label" class="chip-label">Open</span>
            <button type="button" id="stacked-overflow-copy-v-status-v-open-remove" class="chip-remove" aria-label="Remove" aria-labelledby="stacked-overflow-copy-v-status-v-open-remove stacked-overflow-copy-v-status-v-open-label" data-chip-remove>
              <span class="hero-x-mark size-3" aria-hidden="true"></span>
            </button>
          </li>
          <li id="stacked-overflow-copy-v-status-v-paid" class="badge chip badge-secondary" data-index="0" data-value="paid" data-chip-of="status" hidden phx-remove="[[&quot;dispatch&quot;,{&quot;event&quot;:&quot;chip-exit&quot;}],[&quot;transition&quot;,{&quot;time&quot;:180,&quot;transition&quot;:[[&quot;chip-exit&quot;],[],[]]}]]" data-chip-value data-chip-copy>
            <span id="stacked-overflow-copy-v-status-v-paid-label" class="chip-label">Paid</span>
            <button type="button" id="stacked-overflow-copy-v-status-v-paid-remove" class="chip-remove" aria-label="Remove" aria-labelledby="stacked-overflow-copy-v-status-v-paid-remove stacked-overflow-copy-v-status-v-paid-label" data-chip-remove>
              <span class="hero-x-mark size-3" aria-hidden="true"></span>
            </button>
          </li>
          <li id="stacked-overflow-copy-v-brands-v-acme" class="badge chip badge-secondary" data-index="1" data-value="acme" data-chip-of="brands" hidden phx-remove="[[&quot;dispatch&quot;,{&quot;event&quot;:&quot;chip-exit&quot;}],[&quot;transition&quot;,{&quot;time&quot;:180,&quot;transition&quot;:[[&quot;chip-exit&quot;],[],[]]}]]" data-chip-value data-chip-copy>
            <span id="stacked-overflow-copy-v-brands-v-acme-label" class="chip-label">Acme sandbox</span>
            <button type="button" id="stacked-overflow-copy-v-brands-v-acme-remove" class="chip-remove" aria-label="Remove" aria-labelledby="stacked-overflow-copy-v-brands-v-acme-remove stacked-overflow-copy-v-brands-v-acme-label" data-chip-remove>
              <span class="hero-x-mark size-3" aria-hidden="true"></span>
            </button>
          </li>
          <li id="stacked-overflow-copy-v-brands-v-northwind" class="badge chip badge-secondary" data-index="1" data-value="northwind" data-chip-of="brands" hidden phx-remove="[[&quot;dispatch&quot;,{&quot;event&quot;:&quot;chip-exit&quot;}],[&quot;transition&quot;,{&quot;time&quot;:180,&quot;transition&quot;:[[&quot;chip-exit&quot;],[],[]]}]]" data-chip-value data-chip-copy>
            <span id="stacked-overflow-copy-v-brands-v-northwind-label" class="chip-label">Northwind</span>
            <button type="button" id="stacked-overflow-copy-v-brands-v-northwind-remove" class="chip-remove" aria-label="Remove" aria-labelledby="stacked-overflow-copy-v-brands-v-northwind-remove stacked-overflow-copy-v-brands-v-northwind-label" data-chip-remove>
              <span class="hero-x-mark size-3" aria-hidden="true"></span>
            </button>
          </li>
          <li id="stacked-overflow-copy-v-brands-v-northwind-sandbox" class="badge chip badge-secondary" data-index="1" data-value="northwind-sandbox" data-chip-of="brands" hidden phx-remove="[[&quot;dispatch&quot;,{&quot;event&quot;:&quot;chip-exit&quot;}],[&quot;transition&quot;,{&quot;time&quot;:180,&quot;transition&quot;:[[&quot;chip-exit&quot;],[],[]]}]]" data-chip-value data-chip-copy>
            <span id="stacked-overflow-copy-v-brands-v-northwind-sandbox-label" class="chip-label">Northwind sandbox</span>
            <button type="button" id="stacked-overflow-copy-v-brands-v-northwind-sandbox-remove" class="chip-remove" aria-label="Remove" aria-labelledby="stacked-overflow-copy-v-brands-v-northwind-sandbox-remove stacked-overflow-copy-v-brands-v-northwind-sandbox-label" data-chip-remove>
              <span class="hero-x-mark size-3" aria-hidden="true"></span>
            </button>
          </li>
          <li id="stacked-overflow-copy-v-brands-v-northgate" class="badge chip badge-secondary" data-index="1" data-value="northgate" data-chip-of="brands" hidden phx-remove="[[&quot;dispatch&quot;,{&quot;event&quot;:&quot;chip-exit&quot;}],[&quot;transition&quot;,{&quot;time&quot;:180,&quot;transition&quot;:[[&quot;chip-exit&quot;],[],[]]}]]" data-chip-value data-chip-copy>
            <span id="stacked-overflow-copy-v-brands-v-northgate-label" class="chip-label">Northgate</span>
            <button type="button" id="stacked-overflow-copy-v-brands-v-northgate-remove" class="chip-remove" aria-label="Remove" aria-labelledby="stacked-overflow-copy-v-brands-v-northgate-remove stacked-overflow-copy-v-brands-v-northgate-label" data-chip-remove>
              <span class="hero-x-mark size-3" aria-hidden="true"></span>
            </button>
          </li>
          <li id="stacked-overflow-copy-v-owner" class="badge chip badge-secondary" data-index="2" data-value="owner" hidden phx-remove="[[&quot;dispatch&quot;,{&quot;event&quot;:&quot;chip-exit&quot;}],[&quot;transition&quot;,{&quot;time&quot;:180,&quot;transition&quot;:[[&quot;chip-exit&quot;],[],[]]}]]" data-chip-copy>
            <span id="stacked-overflow-copy-v-owner-label" class="chip-label">Owner: Pat Lee</span>
            <button type="button" id="stacked-overflow-copy-v-owner-remove" class="chip-remove" aria-label="Remove" aria-labelledby="stacked-overflow-copy-v-owner-remove stacked-overflow-copy-v-owner-label" data-chip-remove>
              <span class="hero-x-mark size-3" aria-hidden="true"></span>
            </button>
          </li>
          <li id="stacked-overflow-copy-v-region" class="badge chip badge-secondary" data-index="3" data-value="region" hidden phx-remove="[[&quot;dispatch&quot;,{&quot;event&quot;:&quot;chip-exit&quot;}],[&quot;transition&quot;,{&quot;time&quot;:180,&quot;transition&quot;:[[&quot;chip-exit&quot;],[],[]]}]]" data-chip-copy>
            <span id="stacked-overflow-copy-v-region-label" class="chip-label">Region: North</span>
            <button type="button" id="stacked-overflow-copy-v-region-remove" class="chip-remove" aria-label="Remove" aria-labelledby="stacked-overflow-copy-v-region-remove stacked-overflow-copy-v-region-label" data-chip-remove>
              <span class="hero-x-mark size-3" aria-hidden="true"></span>
            </button>
          </li>
        </ul>
      </div>
    </div>
  </div>
</div>
```

## Add and remove (animated)

HEEx:

```heex
<button type="button" class="btn btn-outline btn-sm" phx-click="add_filter">
  <.icon name="hero-plus" class="size-4" /> Add filter
</button>
<%!-- keep the row rendered (no :if); `open` slides it in and out --%>
<.reveal open={@filters != []} class="pt-3">
  <.chip_row id="live-filters" aria-label="Active filters">
    <:chip :for={f <- @filters} value={f.id} on_remove={JS.push("remove_filter", value: %{id: f.id})}>
      {f.label}
    </:chip>
    <:action>
      <button type="button" class="btn btn-ghost btn-sm" phx-click="clear_filters">Clear all</button>
    </:action>
  </.chip_row>
</.reveal>
```

```html
<div class="w-full max-w-md">
  <button type="button" class="btn btn-outline btn-sm" data-demo-chip-add="live-filters">
    <span class="hero-plus size-4" aria-hidden="true"></span> Add filter
  </button>
  <div id="live-filters-reveal" class="reveal" data-open>
    <div class="reveal-track">
      <div class="pt-3">
      <div id="live-filters" data-chip-row role="group" aria-label="Active filters" class="chip-row">
        <ul class="chip-row-chips" data-chip-row-chips>
          <li id="live-filters-chip-v-todo" class="badge chip badge-secondary" data-index="0" data-value="todo" data-chip><span id="live-filters-chip-v-todo-label" class="chip-label">Status: Todo</span><button type="button" id="live-filters-chip-v-todo-remove" class="chip-remove" aria-label="Remove" aria-labelledby="live-filters-chip-v-todo-remove live-filters-chip-v-todo-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
          <li id="live-filters-chip-v-high" class="badge chip badge-secondary" data-index="1" data-value="high" data-chip><span id="live-filters-chip-v-high-label" class="chip-label">Priority: High</span><button type="button" id="live-filters-chip-v-high-remove" class="chip-remove" aria-label="Remove" aria-labelledby="live-filters-chip-v-high-remove live-filters-chip-v-high-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
        </ul>
        <div class="chip-row-more" data-chip-row-more hidden>
          <button type="button" class="badge badge-outline chip chip-more" aria-expanded="false" aria-controls="live-filters-overflow" data-chip-row-trigger data-more-label="Show {count} more"></button>
          <div id="live-filters-overflow" class="popover-panel chip-row-panel" data-chip-row-panel hidden>
            <ul class="flex flex-wrap gap-2" aria-label="Active filters">
                <li id="live-filters-copy-v-todo" class="badge chip badge-secondary" data-index="0" data-value="todo" hidden data-chip-copy><span id="live-filters-copy-v-todo-label" class="chip-label">Status: Todo</span><button type="button" id="live-filters-copy-v-todo-remove" class="chip-remove" aria-label="Remove" aria-labelledby="live-filters-copy-v-todo-remove live-filters-copy-v-todo-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
                <li id="live-filters-copy-v-high" class="badge chip badge-secondary" data-index="1" data-value="high" hidden data-chip-copy><span id="live-filters-copy-v-high-label" class="chip-label">Priority: High</span><button type="button" id="live-filters-copy-v-high-remove" class="chip-remove" aria-label="Remove" aria-labelledby="live-filters-copy-v-high-remove live-filters-copy-v-high-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
            </ul>
          </div>
        </div>
        <div id="live-filters-actions" class="chip-row-actions" data-chip-row-actions>
          <button type="button" class="btn btn-ghost btn-sm" data-chip-row-clear>Clear all</button>
        </div>
      </div>
      </div>
    </div>
  </div>
</div>
```

## Outline (recipients)

HEEx:

```heex
<.chip_row id="recipients" aria-label="Recipients" variant="outline">
  <:chip :for={r <- @recipients} value={r.email} on_remove={JS.push("remove_recipient", value: %{email: r.email})}>
    {r.email}
  </:chip>
</.chip_row>
```

```html
<div id="recipients" data-chip-row role="group" aria-label="Recipients" class="chip-row">
  <ul class="chip-row-chips" data-chip-row-chips>
    <li class="badge chip badge-outline" data-index="0" data-value="olivia@example.com" data-chip><span id="recipients-chip-0-label" class="chip-label">olivia@example.com</span><button type="button" id="recipients-chip-0-remove" class="chip-remove" aria-label="Remove" aria-labelledby="recipients-chip-0-remove recipients-chip-0-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
    <li class="badge chip badge-outline" data-index="1" data-value="jackson@example.com" data-chip><span id="recipients-chip-1-label" class="chip-label">jackson@example.com</span><button type="button" id="recipients-chip-1-remove" class="chip-remove" aria-label="Remove" aria-labelledby="recipients-chip-1-remove recipients-chip-1-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
    <li class="badge chip badge-outline" data-index="2" data-value="isabella@example.com" data-chip><span id="recipients-chip-2-label" class="chip-label">isabella@example.com</span><button type="button" id="recipients-chip-2-remove" class="chip-remove" aria-label="Remove" aria-labelledby="recipients-chip-2-remove recipients-chip-2-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
    <li class="badge chip badge-outline" data-index="3" data-value="william@example.com" data-chip><span id="recipients-chip-3-label" class="chip-label">william@example.com</span><button type="button" id="recipients-chip-3-remove" class="chip-remove" aria-label="Remove" aria-labelledby="recipients-chip-3-remove recipients-chip-3-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
    <li class="badge chip badge-outline" data-index="4" data-value="sofia@example.com" data-chip><span id="recipients-chip-4-label" class="chip-label">sofia@example.com</span><button type="button" id="recipients-chip-4-remove" class="chip-remove" aria-label="Remove" aria-labelledby="recipients-chip-4-remove recipients-chip-4-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
  </ul>
  <div class="chip-row-more" data-chip-row-more hidden>
    <button type="button" class="badge badge-outline chip chip-more" aria-expanded="false" aria-controls="recipients-overflow" data-chip-row-trigger data-more-label="Show {count} more"></button>
    <div id="recipients-overflow" class="popover-panel chip-row-panel" data-chip-row-panel hidden>
      <ul class="flex flex-wrap gap-2" aria-label="Recipients">
        <li class="badge chip badge-outline" data-index="0" data-value="olivia@example.com" hidden data-chip-copy><span id="recipients-copy-0-label" class="chip-label">olivia@example.com</span><button type="button" id="recipients-copy-0-remove" class="chip-remove" aria-label="Remove" aria-labelledby="recipients-copy-0-remove recipients-copy-0-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
        <li class="badge chip badge-outline" data-index="1" data-value="jackson@example.com" hidden data-chip-copy><span id="recipients-copy-1-label" class="chip-label">jackson@example.com</span><button type="button" id="recipients-copy-1-remove" class="chip-remove" aria-label="Remove" aria-labelledby="recipients-copy-1-remove recipients-copy-1-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
        <li class="badge chip badge-outline" data-index="2" data-value="isabella@example.com" hidden data-chip-copy><span id="recipients-copy-2-label" class="chip-label">isabella@example.com</span><button type="button" id="recipients-copy-2-remove" class="chip-remove" aria-label="Remove" aria-labelledby="recipients-copy-2-remove recipients-copy-2-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
        <li class="badge chip badge-outline" data-index="3" data-value="william@example.com" hidden data-chip-copy><span id="recipients-copy-3-label" class="chip-label">william@example.com</span><button type="button" id="recipients-copy-3-remove" class="chip-remove" aria-label="Remove" aria-labelledby="recipients-copy-3-remove recipients-copy-3-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
        <li class="badge chip badge-outline" data-index="4" data-value="sofia@example.com" hidden data-chip-copy><span id="recipients-copy-4-label" class="chip-label">sofia@example.com</span><button type="button" id="recipients-copy-4-remove" class="chip-remove" aria-label="Remove" aria-labelledby="recipients-copy-4-remove recipients-copy-4-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
      </ul>
    </div>
  </div>
</div>
```
