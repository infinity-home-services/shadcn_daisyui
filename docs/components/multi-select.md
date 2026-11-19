# Multi Select

Pick several values from a list: multiple on Select and Combobox, with checkbox rows, counts and Clear.

> Requires a JS hook: initialize with `initShadcnDaisyui()` (dead views) or the corresponding `Shadcn*` LiveView hook from `shadcn-daisyui.js`.

Form params: an always-present name="" input plus one name[] input per value, so a selection posts ["a", "b"] and a cleared one posts "" (Ecto casts it to the field default). Each toggle dispatches input + change on the form, so phx-change fires; a select-change / combobox-change event with { value } bubbles from the root. The open list, label and checks survive LiveView patches, and a server-side change to the value (a reset) wins.

## Usage guidance

Use when:

- Filters and tags: several values of one field (status, labels, assignees)
- The data-table faceted filter - pass count for the matching rows per option
- Long lists (> ~10): use <.combobox multiple> so people can type to filter

Don't use for:

- Two to five always-visible options - a checkbox group shows every state at once
- One value - use <.select> or <.combobox> without multiple
- Free-form tags people invent - use an input with a tag pattern

Sizing: Trigger h-9 (field metrics); popover rounded-md, p-1, ring-1 ring-foreground/10, shadow-md; rows 32px desktop, 44px on touch; 16px checkbox; counts font-mono text-xs.

Responsive: On compact screens and in sheets use full_width: the trigger fills the container and grows to 44px on touch. The trigger shows two labels then +N, so it never wraps.

iOS: A List with selection (EditButton / .environment(\.editMode)) or a NavigationLink to a checkmark list. Menus with Toggle items for short filter sets.

## Specs

| Part | Description |
| --- | --- |
| Trigger | Outline field button (role=combobox on select). Shows the placeholder, or up to two selected labels then a muted +N. |
| Search (combobox) | Filters rows by label and value; Space types, Enter toggles. |
| Listbox | role=listbox with aria-multiselectable=true; rows are role=option with aria-selected. |
| Checkbox row | 16px box (primary border, filled + check when selected, 50% when not), label, optional right-aligned count. |
| Clear row | Separated footer action, shown once anything is selected. |
| Hidden inputs | name="" sentinel + one name[] per value, kept in sync by the hook. |

| Property | Value |
| --- | --- |
| Trigger height | 2.25rem / 36px (2.75rem on touch with full_width) |
| Popover | rounded-md, p-1, ring-1 ring-foreground/10, shadow-md |
| Row | 0.375rem 0.5rem padding, rounded-sm, 44px min on touch |
| Checkbox | 1rem, rounded-sm, 1px var(--primary) |
| Count | font-mono 0.75rem, var(--muted-foreground) |
| List height | max 18rem (select) / 15rem (combobox), scrolls |

Tokens used: `popover`, `popover-foreground`, `accent`, `accent-foreground`, `primary`, `primary-foreground`, `muted-foreground`, `border-color`, `input`, `ring`

## Accessibility

| Keys | Action |
| --- | --- |
| Enter / Space / Down / Up | Open the list from the trigger |
| Up / Down | Move the active row (wraps) |
| Home / End | First / last row (select) |
| Space / Enter | Toggle the active row; the list stays open |
| Type (combobox) | Filter rows; Space types, Enter toggles |
| Tab | Reach the Clear row, then leave (closes the list) |
| Esc | Close and return focus to the trigger (does not close a surrounding sheet) |

Role / ARIA: Select: the trigger is role=combobox (aria-haspopup=listbox, aria-expanded, aria-controls, aria-activedescendant). Combobox: the search box carries those roles. The list is role=listbox aria-multiselectable=true; rows are role=option with aria-selected. Name the control with a <label for> on the trigger (field binding sets its id to the field id), aria-label or aria-labelledby.

Focus: Focus stays on the trigger (or search box) while toggling - clicks on rows do not steal it - and the active row is tracked with aria-activedescendant and the accent fill.

Screen reader: Each row announces its label, count and selected state; the trigger reads the selected labels and "+N more". The listbox announces as multi-selectable.

Touch target: Rows are 44px tall on coarse pointers; pass full_width for a 44px trigger in sheets and compact forms.

Reduced motion: The list toggles without movement, so there is nothing to reduce.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
@State private var status: Set<String> = []

List(statuses, id: \.self, selection: $status) { s in
    HStack {
        Text(s.title)
        Spacer()
        Text("\(s.count)").font(.caption.monospaced()).foregroundStyle(.secondary)
    }
}
.environment(\.editMode, .constant(.active))
.toolbar { Button("Clear") { status.removeAll() }.disabled(status.isEmpty) }
```

A List bound to a Set<ID> in edit mode is the native multi-select. For a compact filter in a toolbar, a Menu of Toggle items (one per value) matches the faceted-filter popover.

## Props

| Name | Type | Default |
| --- | --- | --- |
| multiple | boolean | false |
| field | Phoenix.HTML.FormField | nil |
| name / value | string / list | nil |
| placeholder | string | "Select…" |
| full_width | boolean | false |
| clear_label | string | "Clear" |
| disabled | boolean | false |
| aria-label / aria-labelledby | string | nil |
| :option value count | slot | - |
| search_placeholder / empty (combobox) | string | placeholder / "No results." |

## Select multiple

HEEx:

```heex
<.select id="status-filter" multiple placeholder="Status" aria-label="Status">
  <:option value="backlog">Backlog</:option>
  <:option value="todo">Todo</:option>
  <:option value="in-progress">In progress</:option>
  <:option value="done">Done</:option>
  <:option value="canceled">Canceled</:option>
</.select>
```

```html
<div id="status-filter" data-select data-multiple data-placeholder="Status" class="relative w-60">
  <button type="button" role="combobox" aria-haspopup="listbox" aria-expanded="false" aria-label="Status" class="btn btn-outline w-full justify-between font-normal" data-select-trigger>
    <span class="flex min-w-0 items-center gap-1 text-muted-foreground" data-select-label>Status</span>
    <span class="hero-chevron-down size-4 shrink-0 opacity-50" aria-hidden="true"></span>
  </button>
  <div class="popover-panel absolute z-50 mt-1 hidden w-full p-1" data-select-panel>
    <div role="listbox" aria-multiselectable="true" class="max-h-72 overflow-auto" data-select-list>
      <button type="button" tabindex="-1" role="option" aria-selected="false" class="combo-item" data-select-item data-value="backlog"><span class="facet-check" aria-hidden="true"><span class="hero-check size-3.5"></span></span><span data-label class="truncate">Backlog</span></button>
      <button type="button" tabindex="-1" role="option" aria-selected="false" class="combo-item" data-select-item data-value="todo"><span class="facet-check" aria-hidden="true"><span class="hero-check size-3.5"></span></span><span data-label class="truncate">Todo</span></button>
      <button type="button" tabindex="-1" role="option" aria-selected="false" class="combo-item" data-select-item data-value="in-progress"><span class="facet-check" aria-hidden="true"><span class="hero-check size-3.5"></span></span><span data-label class="truncate">In progress</span></button>
      <button type="button" tabindex="-1" role="option" aria-selected="false" class="combo-item" data-select-item data-value="done"><span class="facet-check" aria-hidden="true"><span class="hero-check size-3.5"></span></span><span data-label class="truncate">Done</span></button>
      <button type="button" tabindex="-1" role="option" aria-selected="false" class="combo-item" data-select-item data-value="canceled"><span class="facet-check" aria-hidden="true"><span class="hero-check size-3.5"></span></span><span data-label class="truncate">Canceled</span></button>
    </div>
    <div class="-mx-1 mt-1 hidden border-t border-border px-1 pt-1" data-select-clear>
      <button type="button" class="combo-item justify-center" data-select-clear-btn>Clear</button>
    </div>
  </div>
</div>
```

## Faceted filter (combobox with counts)

HEEx:

```heex
<.combobox
  id="label-filter"
  multiple
  placeholder="Labels"
  search_placeholder="Filter labels…"
  empty="No labels found."
  aria-label="Labels"
>
  <:option :for={l <- @labels} value={l.id} count={l.count}>{l.name}</:option>
</.combobox>
```

```html
<div id="label-filter" data-combobox data-multiple data-placeholder="Labels" class="relative w-60">
  <button type="button" aria-haspopup="listbox" aria-expanded="false" aria-label="Labels" class="btn btn-outline w-full justify-between font-normal" data-combobox-trigger>
    <span class="flex min-w-0 items-center gap-1 text-muted-foreground" data-combobox-label>Labels</span>
    <span class="hero-chevron-up-down size-4 shrink-0 opacity-50" aria-hidden="true"></span>
  </button>
  <div class="popover-panel absolute z-50 mt-1 hidden w-full p-1" data-combobox-panel>
    <input data-combobox-search class="input mb-1 w-full" placeholder="Filter labels…" autocomplete="off" />
    <ul role="listbox" aria-multiselectable="true" class="max-h-60 overflow-auto" data-combobox-list>
      <li><button type="button" tabindex="-1" role="option" aria-selected="false" class="combo-item" data-value="bug"><span class="facet-check" aria-hidden="true"><span class="hero-check size-3.5"></span></span><span data-label class="truncate">Bug</span><span class="ml-auto font-mono text-xs text-muted-foreground">12</span></button></li>
      <li><button type="button" tabindex="-1" role="option" aria-selected="false" class="combo-item" data-value="feature"><span class="facet-check" aria-hidden="true"><span class="hero-check size-3.5"></span></span><span data-label class="truncate">Feature</span><span class="ml-auto font-mono text-xs text-muted-foreground">8</span></button></li>
      <li><button type="button" tabindex="-1" role="option" aria-selected="false" class="combo-item" data-value="docs"><span class="facet-check" aria-hidden="true"><span class="hero-check size-3.5"></span></span><span data-label class="truncate">Documentation</span><span class="ml-auto font-mono text-xs text-muted-foreground">5</span></button></li>
      <li><button type="button" tabindex="-1" role="option" aria-selected="false" class="combo-item" data-value="perf"><span class="facet-check" aria-hidden="true"><span class="hero-check size-3.5"></span></span><span data-label class="truncate">Performance</span><span class="ml-auto font-mono text-xs text-muted-foreground">3</span></button></li>
      <li><button type="button" tabindex="-1" role="option" aria-selected="false" class="combo-item" data-value="security"><span class="facet-check" aria-hidden="true"><span class="hero-check size-3.5"></span></span><span data-label class="truncate">Security</span><span class="ml-auto font-mono text-xs text-muted-foreground">2</span></button></li>
      <li><button type="button" tabindex="-1" role="option" aria-selected="false" class="combo-item" data-value="ui"><span class="facet-check" aria-hidden="true"><span class="hero-check size-3.5"></span></span><span data-label class="truncate">UI</span><span class="ml-auto font-mono text-xs text-muted-foreground">9</span></button></li>
    </ul>
    <p data-combobox-empty class="hidden p-2 text-center text-sm text-muted-foreground">No labels found.</p>
    <div class="-mx-1 mt-1 hidden border-t border-border px-1 pt-1" data-combobox-clear>
      <button type="button" class="combo-item justify-center" data-combobox-clear-btn>Clear filters</button>
    </div>
  </div>
</div>
```

## Form (field binding, full width)

HEEx:

```heex
<.form for={@form} id="member-form" phx-change="validate" phx-submit="save" class="w-full max-w-sm space-y-2">
  <.label for={@form[:roles].id}>Roles</.label>
  <.select id="member-roles" field={@form[:roles]} multiple full_width placeholder="Pick roles">
    <:option value="viewer">Viewer</:option>
    <:option value="editor">Editor</:option>
    <:option value="billing">Billing</:option>
    <:option value="admin">Admin</:option>
  </.select>
</.form>
```

```html
<form class="w-full max-w-sm space-y-2">
  <label for="member_roles" class="text-sm font-medium">Roles</label>
  <div id="member-roles" data-select data-multiple data-full-width data-placeholder="Pick roles" class="relative w-full">
    <input type="hidden" name="member[roles]" value="" data-select-sentinel />
    <input type="hidden" name="member[roles][]" value="editor" data-select-value />
    <button type="button" id="member_roles" role="combobox" aria-haspopup="listbox" aria-expanded="false" class="btn btn-outline w-full justify-between font-normal" data-select-trigger>
      <span class="flex min-w-0 items-center gap-1" data-select-label><span class="truncate">Editor</span></span>
      <span class="hero-chevron-down size-4 shrink-0 opacity-50" aria-hidden="true"></span>
    </button>
    <div class="popover-panel absolute z-50 mt-1 hidden w-full p-1" data-select-panel>
      <div role="listbox" aria-multiselectable="true" class="max-h-72 overflow-auto" data-select-list>
        <button type="button" tabindex="-1" role="option" aria-selected="false" class="combo-item" data-select-item data-value="viewer"><span class="facet-check" aria-hidden="true"><span class="hero-check size-3.5"></span></span><span data-label class="truncate">Viewer</span></button>
        <button type="button" tabindex="-1" role="option" aria-selected="true" class="combo-item" data-select-item data-value="editor" data-selected><span class="facet-check" aria-hidden="true"><span class="hero-check size-3.5"></span></span><span data-label class="truncate">Editor</span></button>
        <button type="button" tabindex="-1" role="option" aria-selected="false" class="combo-item" data-select-item data-value="billing"><span class="facet-check" aria-hidden="true"><span class="hero-check size-3.5"></span></span><span data-label class="truncate">Billing</span></button>
        <button type="button" tabindex="-1" role="option" aria-selected="false" class="combo-item" data-select-item data-value="admin"><span class="facet-check" aria-hidden="true"><span class="hero-check size-3.5"></span></span><span data-label class="truncate">Admin</span></button>
      </div>
      <div class="-mx-1 mt-1 border-t border-border px-1 pt-1" data-select-clear>
        <button type="button" class="combo-item justify-center" data-select-clear-btn>Clear</button>
      </div>
    </div>
  </div>
</form>
```
