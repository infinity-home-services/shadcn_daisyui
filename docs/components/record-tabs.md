# Record Tabs

A tab row inside a record (Details, Activity, Files): the active tab is underlined and the server owns which one shows.

Each tab sends the event ("tab" by default) with %{"tab" => key}; assign it and render that tab's content (keep it in the URL with push_patch/2 if people link to it). The arrow keys come from shadcn-daisyui.js (one delegated listener, no hook needed). On this static page the keys work but nothing is sent; the record page on the dev server (`/lab/data-table/:id`) switches Details and Activity.

## Usage guidance

Use when:

- Parts of one record that don't fit on one page: Details, Activity, Files
- Under the record's page header (its :below slot), so it pins with the title

Don't use for:

- Saved views of a list, each a URL - use <.tab_nav>
- Panels switched in the browser with no server state - use <.tabs>
- Sections of one long form - use <.section_nav>

Sizing: shadcn's line tabs: 40px tabs (44px on touch), text-sm medium, 16px apart on a 1px line; the active tab is foreground with a 2px underline, the rest muted. A count is a muted pill after the label.

Responsive: Two to four short labels fit every width; labels truncate rather than wrap, and the row never scrolls. More than four belong in a <.tab_nav> or a different structure.

iOS: A segmented Picker under the navigation title, or a TabView for top-level parts.

## Specs

| Part | Description |
| --- | --- |
| Tablist | A flex row on a 1px border line. |
| Tab | A button: label (truncates) and an optional count; muted until hover or active. |
| Underline | The active tab's 2px foreground bar over the line. |

| Property | Value |
| --- | --- |
| Tab height | 2.5rem / 40px (2.75rem / 44px on coarse pointers) |
| Gap | 1rem between tabs; 0.25rem inline padding |
| Label | 0.875rem, weight 500 |
| Underline | 2px, var(--foreground), rounded, over the 1px line |

Tokens used: `foreground`, `muted-foreground`, `border-color`, `muted`, `ring`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Focus the active tab; Tab again leaves the row |
| Left / Right | Move to the previous / next tab (wraps; mirrored in RTL) |
| Home / End | First / last tab |
| Enter / Space | Pick the focused tab (sends the event) |

Role / ARIA: role=tablist (named with aria_label); each tab is a role=tab button with aria-selected. One tab stop: the active tab has tabindex=0, the rest -1.

Focus: A ring on the focused tab; picking keeps focus on it.

Screen reader: Announced as a tab, n of m, selected or not; a count reads after the label.

Touch target: 44px tall on touch; tabs are at least label-wide with 4px padding.

Reduced motion: Only the 150ms colour change; the underline moves instantly.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
@State private var tab: OrderTab = .details

Picker("Order", selection: $tab) {
    Text("Details").tag(OrderTab.details)
    Text("Activity (4)").tag(OrderTab.activity)
    Text("Files (2)").tag(OrderTab.files)
}
.pickerStyle(.segmented)
```

A segmented Picker is the closest native control; it is boxed rather than underlined. Keep the selection in the view model so a deep link can choose it.

## Props

| Name | Type | Default |
| --- | --- | --- |
| id | string (required) | - |
| tabs | [{key, label}] or [{key, label, count}] | - |
| active | any (a tab's key) | nil (the first tab) |
| event | string | "tab" |
| target | phx-target | nil |
| aria_label | string | nil |
| class | any | nil |

## Default

HEEx:

```heex
<.record_tabs
  id="order-tabs"
  tabs={[{"details", "Details"}, {"activity", "Activity", 4}, {"files", "Files", 2}]}
  active={@tab}
  aria_label="Order"
/>

def handle_event("tab", %{"tab" => tab}, socket), do: {:noreply, assign(socket, tab: tab)}
```

```html
<div id="order-tabs" role="tablist" aria-label="Order" class="record-tabs" data-record-tabs>
  <button type="button" role="tab" id="order-tabs-details" class="record-tab" aria-selected="true" tabindex="0" phx-click="[[&quot;push&quot;,{&quot;value&quot;:{&quot;tab&quot;:&quot;details&quot;},&quot;event&quot;:&quot;tab&quot;}]]">
    <span class="record-tab-label">Details</span>
  </button>
  <button type="button" role="tab" id="order-tabs-activity" class="record-tab" aria-selected="false" tabindex="-1" phx-click="[[&quot;push&quot;,{&quot;value&quot;:{&quot;tab&quot;:&quot;activity&quot;},&quot;event&quot;:&quot;tab&quot;}]]">
    <span class="record-tab-label">Activity</span>
    <span class="tab-count">4</span>
  </button>
  <button type="button" role="tab" id="order-tabs-files" class="record-tab" aria-selected="false" tabindex="-1" phx-click="[[&quot;push&quot;,{&quot;value&quot;:{&quot;tab&quot;:&quot;files&quot;},&quot;event&quot;:&quot;tab&quot;}]]">
    <span class="record-tab-label">Files</span>
    <span class="tab-count">2</span>
  </button>
</div>
```
