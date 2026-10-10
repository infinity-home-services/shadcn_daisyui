# Tab Nav

A row of link tabs that fits its width: tabs that don't fit move into a More menu, which also holds extra views.

> Requires a JS hook: initialize with `initShadcnDaisyui()` (dead views) or the corresponding `Shadcn*` LiveView hook from `shadcn-daisyui.js`.

Needs the ShadcnTabNav hook (or initShadcnDaisyui() in dead views). Every tab renders twice, once in the row and once hidden in the menu, and the hook only flips hidden on the two copies, so LiveView patches never fight it; it re-fits on resize (ResizeObserver), after web fonts load, and in updated(), all before the browser paints. The active tab always stays in the row, swapping out the last visible one. When an active :menu_item lives in the menu, More shows its name. When even the active tab and More don't fit side by side, every tab folds into the menu (the active one checked) and the trigger names the active tab with its count, e.g. "Needs a call 17"; the label truncates with an ellipsis, the count never does.

## Usage guidance

Use when:

- Saved views or filters of one list (All / Active / Backlog / …) where each view is a URL
- Sections of a page or settings area that people deep-link to
- Rows whose tab count or labels vary (user-created views, translated labels)

Don't use for:

- Panels on the same URL with no navigation - use tabs (radio-based)
- Primary app navigation - that's the dock / sidebar's job
- Two to four fixed peers that always fit - plain tabs are simpler

Sizing: The boxed tabs look: an h-9 p-[3px] muted list with 29px text-sm triggers (h-10 on touch); the active tab is the white box in light, bg-input/30 with an input border in dark. Counts are a 20px muted pill. The More menu is floating content: rounded-md, p-1, ring-1 ring-foreground/10, shadow-md, 32px rows (44px on touch).

Responsive: Never wraps or scrolls: on compact the row keeps the active tab and as many neighbours as fit, and the rest move into More. On phones prefer three to five short labels; long tails live in the menu.

iOS: A segmented Picker for two to four views; past that, a Menu in the toolbar (or a navigation title menu) listing every view, with a checkmark on the current one.

## Specs

| Part | Description |
| --- | --- |
| Nav | <nav aria-label> landmark that fills its container (the observed width). |
| List | tabs-box segmented list, fit-content up to the nav width, never wraps. |
| Tab | A link (.tab) with an optional count pill; the active one is the white box with aria-current=page. |
| More trigger | A .tab button with a chevron (aria-expanded, aria-controls). Shows the active menu item's name when there is one. |
| Menu | Floating panel: overflowed tabs first (in order), a separator, then the :menu_item sections with group labels. |

| Property | Value |
| --- | --- |
| Tab height | 1.75rem / 28px (2.5rem on touch) |
| List padding | 3px, radius var(--radius-lg) |
| Count pill | 1.25rem min, rounded-full, text-xs tabular-nums, foreground 8% |
| Menu | min 12rem, max 18rem, max-h 20rem, p-1, 4px below the list |
| Menu row | 0.375rem 0.5rem padding, rounded-sm, 44px min on touch |

Tokens used: `muted`, `muted-foreground`, `background`, `foreground`, `popover`, `popover-foreground`, `accent`, `accent-foreground`, `border-color`, `ring`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab / Shift+Tab | Move through the visible tabs and More, like any links |
| Left / Right | Move across the visible tabs and into More (wraps; mirrored in RTL) |
| Home / End | First tab / More |
| Enter / Space / Down | On More: open the menu and focus its first link |
| Up | On More: open the menu and focus its last link |
| Up / Down, Home / End | Move within the menu |
| Esc | Close the menu, focus More (does not close a surrounding sheet) |
| Tab | Leave the menu (closes it) |

Role / ARIA: Link tabs are navigation, not an ARIA tablist: a <nav aria-label> of links, the current one aria-current=page. More is a disclosure button (aria-expanded, aria-controls) for a panel of links; :menu_item groups are role=group named by their label.

Focus: Tabs and menu links show the 3px ring. If a focused tab is pushed into the menu by a resize, focus moves to More instead of disappearing.

Screen reader: Hidden copies are display:none, so each destination is announced once. More reads as "More, collapsed", or "More: Open bugs" when the active view is in the menu; counts are read after the label.

Touch target: Tabs grow to 40px (46px with the list padding) and menu rows to 44px on coarse pointers; the menu opens on tap and closes on an outside tap.

Reduced motion: Fitting and the menu are instant; nothing animates.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
@State private var view: IssueView = .all

ToolbarItem(placement: .principal) {
    Menu {
        Picker("View", selection: $view) {
            ForEach(IssueView.builtIn) { v in
                Label("\(v.title)  \(v.count)", systemImage: v.symbol).tag(v)
            }
        }
        Section("Shared") {
            ForEach(sharedViews) { v in Button(v.title) { view = v } }
        }
        Button("Manage views…", systemImage: "gearshape") { showManage = true }
    } label: {
        Label(view.title, systemImage: "chevron.down").labelStyle(.titleAndIcon)
    }
}
```

iOS has no width-fitting tab strip. Use a segmented Picker (.pickerStyle(.segmented)) when two to four views always fit; otherwise a single Menu whose label is the current view, which is exactly the overflow state of the web row. ViewThatFits can choose between the two at runtime.

## Props

| Name | Type | Default |
| --- | --- | --- |
| id | string (required) | - |
| aria_label | string | "Tabs" |
| more_label | string | "More" |
| :tab navigate / patch / href | slot attrs | - |
| :tab active | boolean | false |
| :tab count | number \| string | nil |
| :menu_item navigate / patch / href / phx-click | slot attrs | - |
| :menu_item group / icon / active | string / string / boolean | nil |

## Views with a More menu

HEEx:

```heex
<.tab_nav id="issue-views" aria-label="Views">
  <:tab
    :for={v <- @views}
    patch={~p"/issues?view=#{v.slug}"}
    active={@view == v.slug}
    count={v.count}
  >
    {v.title}
  </:tab>
  <:menu_item group="Mine" patch={~p"/issues?view=assigned"}>Assigned to me</:menu_item>
  <:menu_item group="Mine" patch={~p"/issues?view=created"}>Created by me</:menu_item>
  <:menu_item group="Shared" patch={~p"/issues?view=bugs"}>Open bugs</:menu_item>
  <:menu_item group="Shared" patch={~p"/issues?view=roadmap"}>Q4 roadmap</:menu_item>
  <:menu_item navigate={~p"/views"} icon="hero-cog-6-tooth">Manage views…</:menu_item>
</.tab_nav>
```

```html
<nav id="issue-views" data-tab-nav aria-label="Views" class="tab-nav">
  <div class="tabs tabs-box tab-nav-list">
    <div class="tab-nav-tabs" data-tab-nav-tabs>
      <a href="#all" class="tab tab-active" aria-current="page" data-tab-nav-item data-index="0"><span class="tab-nav-label">All issues</span><span class="tab-count">128</span></a>
      <a href="#active" class="tab" data-tab-nav-item data-index="1"><span class="tab-nav-label">Active</span><span class="tab-count">24</span></a>
      <a href="#backlog" class="tab" data-tab-nav-item data-index="2"><span class="tab-nav-label">Backlog</span><span class="tab-count">61</span></a>
      <a href="#triage" class="tab" data-tab-nav-item data-index="3"><span class="tab-nav-label">Triage</span><span class="tab-count">7</span></a>
      <a href="#review" class="tab" data-tab-nav-item data-index="4"><span class="tab-nav-label">In review</span><span class="tab-count">5</span></a>
      <a href="#done" class="tab" data-tab-nav-item data-index="5"><span class="tab-nav-label">Done</span><span class="tab-count">312</span></a>
      <a href="#canceled" class="tab" data-tab-nav-item data-index="6"><span class="tab-nav-label">Canceled</span><span class="tab-count">9</span></a>
    </div>
    <div class="tab-nav-more" data-tab-nav-more>
      <button type="button" class="tab" aria-expanded="false" aria-controls="issue-views-menu" data-tab-nav-trigger>
        <span class="tab-nav-label" data-tab-nav-default>More</span>
        <span class="tab-nav-label" data-tab-nav-current>All issues</span><span class="tab-count" data-tab-nav-current>128</span>
        <span class="hero-chevron-down size-4 opacity-50" aria-hidden="true"></span>
      </button>
      <div id="issue-views-menu" class="popover-panel tab-nav-menu" data-tab-nav-menu hidden>
        <div data-tab-nav-overflow hidden>
          <a href="#all" class="combo-item" aria-current="page" tabindex="-1" data-tab-nav-copy data-index="0" hidden><span class="truncate">All issues</span><span class="ml-auto font-mono text-xs text-muted-foreground">128</span><span class="hero-check size-4" aria-hidden="true"></span></a>
          <a href="#active" class="combo-item" tabindex="-1" data-tab-nav-copy data-index="1" hidden><span class="truncate">Active</span><span class="ml-auto font-mono text-xs text-muted-foreground">24</span></a>
          <a href="#backlog" class="combo-item" tabindex="-1" data-tab-nav-copy data-index="2" hidden><span class="truncate">Backlog</span><span class="ml-auto font-mono text-xs text-muted-foreground">61</span></a>
          <a href="#triage" class="combo-item" tabindex="-1" data-tab-nav-copy data-index="3" hidden><span class="truncate">Triage</span><span class="ml-auto font-mono text-xs text-muted-foreground">7</span></a>
          <a href="#review" class="combo-item" tabindex="-1" data-tab-nav-copy data-index="4" hidden><span class="truncate">In review</span><span class="ml-auto font-mono text-xs text-muted-foreground">5</span></a>
          <a href="#done" class="combo-item" tabindex="-1" data-tab-nav-copy data-index="5" hidden><span class="truncate">Done</span><span class="ml-auto font-mono text-xs text-muted-foreground">312</span></a>
          <a href="#canceled" class="combo-item" tabindex="-1" data-tab-nav-copy data-index="6" hidden><span class="truncate">Canceled</span><span class="ml-auto font-mono text-xs text-muted-foreground">9</span></a>
        </div>
        <div class="tab-nav-sep" data-tab-nav-sep hidden></div>
        <div role="group" aria-labelledby="issue-views-group-0">
          <div id="issue-views-group-0" class="command-group-label">Mine</div>
          <a href="#assigned" class="combo-item" tabindex="-1" data-tab-nav-entry><span class="truncate">Assigned to me</span></a>
          <a href="#created" class="combo-item" tabindex="-1" data-tab-nav-entry><span class="truncate">Created by me</span></a>
        </div>
        <div role="group" aria-labelledby="issue-views-group-1" class="tab-nav-group">
          <div id="issue-views-group-1" class="command-group-label">Shared</div>
          <a href="#bugs" class="combo-item" tabindex="-1" data-tab-nav-entry><span class="truncate">Open bugs</span></a>
          <a href="#roadmap" class="combo-item" tabindex="-1" data-tab-nav-entry><span class="truncate">Q4 roadmap</span></a>
        </div>
        <div role="group" class="tab-nav-group">
          <a href="#views" class="combo-item" tabindex="-1" data-tab-nav-entry><span class="hero-cog-6-tooth size-4" aria-hidden="true"></span><span class="truncate">Manage views…</span></a>
        </div>
      </div>
    </div>
  </div>
</nav>
```

## Active view in the menu

HEEx:

```heex
<.tab_nav id="issue-views" aria-label="Views">
  <:tab :for={v <- @views} patch={~p"/issues?view=#{v.slug}"} count={v.count}>{v.title}</:tab>
  <:menu_item group="Shared" patch={~p"/issues?view=bugs"} active={@view == "bugs"}>
    Open bugs
  </:menu_item>
</.tab_nav>
```

```html
<nav id="issue-views-shared" data-tab-nav aria-label="Views" class="tab-nav">
  <div class="tabs tabs-box tab-nav-list">
    <div class="tab-nav-tabs" data-tab-nav-tabs>
      <a href="#all" class="tab" data-tab-nav-item data-index="0"><span class="tab-nav-label">All issues</span><span class="tab-count">128</span></a>
      <a href="#active" class="tab" data-tab-nav-item data-index="1"><span class="tab-nav-label">Active</span><span class="tab-count">24</span></a>
      <a href="#backlog" class="tab" data-tab-nav-item data-index="2"><span class="tab-nav-label">Backlog</span><span class="tab-count">61</span></a>
      <a href="#triage" class="tab" data-tab-nav-item data-index="3"><span class="tab-nav-label">Triage</span><span class="tab-count">7</span></a>
      <a href="#review" class="tab" data-tab-nav-item data-index="4"><span class="tab-nav-label">In review</span><span class="tab-count">5</span></a>
      <a href="#done" class="tab" data-tab-nav-item data-index="5"><span class="tab-nav-label">Done</span><span class="tab-count">312</span></a>
      <a href="#canceled" class="tab" data-tab-nav-item data-index="6"><span class="tab-nav-label">Canceled</span><span class="tab-count">9</span></a>
    </div>
    <div class="tab-nav-more" data-tab-nav-more>
      <button type="button" class="tab tab-active" aria-expanded="false" aria-controls="issue-views-shared-menu" data-tab-nav-trigger>
        <span class="sr-only" data-tab-nav-default>More: </span><span class="tab-nav-label" data-tab-nav-default>Open bugs</span>
        <span class="hero-chevron-down size-4 opacity-50" aria-hidden="true"></span>
      </button>
      <div id="issue-views-shared-menu" class="popover-panel tab-nav-menu" data-tab-nav-menu hidden>
        <div data-tab-nav-overflow hidden>
          <a href="#all" class="combo-item" tabindex="-1" data-tab-nav-copy data-index="0" hidden><span class="truncate">All issues</span><span class="ml-auto font-mono text-xs text-muted-foreground">128</span></a>
          <a href="#active" class="combo-item" tabindex="-1" data-tab-nav-copy data-index="1" hidden><span class="truncate">Active</span><span class="ml-auto font-mono text-xs text-muted-foreground">24</span></a>
          <a href="#backlog" class="combo-item" tabindex="-1" data-tab-nav-copy data-index="2" hidden><span class="truncate">Backlog</span><span class="ml-auto font-mono text-xs text-muted-foreground">61</span></a>
          <a href="#triage" class="combo-item" tabindex="-1" data-tab-nav-copy data-index="3" hidden><span class="truncate">Triage</span><span class="ml-auto font-mono text-xs text-muted-foreground">7</span></a>
          <a href="#review" class="combo-item" tabindex="-1" data-tab-nav-copy data-index="4" hidden><span class="truncate">In review</span><span class="ml-auto font-mono text-xs text-muted-foreground">5</span></a>
          <a href="#done" class="combo-item" tabindex="-1" data-tab-nav-copy data-index="5" hidden><span class="truncate">Done</span><span class="ml-auto font-mono text-xs text-muted-foreground">312</span></a>
          <a href="#canceled" class="combo-item" tabindex="-1" data-tab-nav-copy data-index="6" hidden><span class="truncate">Canceled</span><span class="ml-auto font-mono text-xs text-muted-foreground">9</span></a>
        </div>
        <div class="tab-nav-sep" data-tab-nav-sep hidden></div>
        <div role="group" aria-labelledby="issue-views-shared-group-0">
          <div id="issue-views-shared-group-0" class="command-group-label">Mine</div>
          <a href="#assigned" class="combo-item" tabindex="-1" data-tab-nav-entry><span class="truncate">Assigned to me</span></a>
          <a href="#created" class="combo-item" tabindex="-1" data-tab-nav-entry><span class="truncate">Created by me</span></a>
        </div>
        <div role="group" aria-labelledby="issue-views-shared-group-1" class="tab-nav-group">
          <div id="issue-views-shared-group-1" class="command-group-label">Shared</div>
          <a href="#bugs" class="combo-item" aria-current="page" tabindex="-1" data-tab-nav-entry><span class="truncate">Open bugs</span><span class="hero-check ml-auto size-4" aria-hidden="true"></span></a>
          <a href="#roadmap" class="combo-item" tabindex="-1" data-tab-nav-entry><span class="truncate">Q4 roadmap</span></a>
        </div>
      </div>
    </div>
  </div>
</nav>
```

## Tabs only (active stays visible)

HEEx:

```heex
<.tab_nav id="settings-nav" aria-label="Settings">
  <:tab navigate={~p"/settings"} active={@section == :overview}>Overview</:tab>
  <:tab navigate={~p"/settings/analytics"}>Analytics</:tab>
  <:tab navigate={~p"/settings/reports"}>Reports</:tab>
  <:tab navigate={~p"/settings/notifications"}>Notifications</:tab>
  <:tab navigate={~p"/settings/integrations"}>Integrations</:tab>
  <:tab navigate={~p"/settings/billing"} active={@section == :billing}>Billing</:tab>
</.tab_nav>
```

```html
<nav id="settings-nav" data-tab-nav aria-label="Settings" class="tab-nav">
  <div class="tabs tabs-box tab-nav-list">
    <div class="tab-nav-tabs" data-tab-nav-tabs>
      <a href="#overview" class="tab" data-tab-nav-item data-index="0"><span class="tab-nav-label">Overview</span></a>
      <a href="#analytics" class="tab" data-tab-nav-item data-index="1"><span class="tab-nav-label">Analytics</span></a>
      <a href="#reports" class="tab" data-tab-nav-item data-index="2"><span class="tab-nav-label">Reports</span></a>
      <a href="#notifications" class="tab" data-tab-nav-item data-index="3"><span class="tab-nav-label">Notifications</span></a>
      <a href="#integrations" class="tab" data-tab-nav-item data-index="4"><span class="tab-nav-label">Integrations</span></a>
      <a href="#billing" class="tab tab-active" aria-current="page" data-tab-nav-item data-index="5"><span class="tab-nav-label">Billing</span></a>
    </div>
    <div class="tab-nav-more" data-tab-nav-more hidden>
      <button type="button" class="tab" aria-expanded="false" aria-controls="settings-nav-menu" data-tab-nav-trigger>
        <span class="tab-nav-label" data-tab-nav-default>More</span>
        <span class="tab-nav-label" data-tab-nav-current>Billing</span>
        <span class="hero-chevron-down size-4 opacity-50" aria-hidden="true"></span>
      </button>
      <div id="settings-nav-menu" class="popover-panel tab-nav-menu" data-tab-nav-menu hidden>
        <div data-tab-nav-overflow hidden>
          <a href="#overview" class="combo-item" tabindex="-1" data-tab-nav-copy data-index="0" hidden><span class="truncate">Overview</span></a>
          <a href="#analytics" class="combo-item" tabindex="-1" data-tab-nav-copy data-index="1" hidden><span class="truncate">Analytics</span></a>
          <a href="#reports" class="combo-item" tabindex="-1" data-tab-nav-copy data-index="2" hidden><span class="truncate">Reports</span></a>
          <a href="#notifications" class="combo-item" tabindex="-1" data-tab-nav-copy data-index="3" hidden><span class="truncate">Notifications</span></a>
          <a href="#integrations" class="combo-item" tabindex="-1" data-tab-nav-copy data-index="4" hidden><span class="truncate">Integrations</span></a>
          <a href="#billing" class="combo-item" aria-current="page" tabindex="-1" data-tab-nav-copy data-index="5" hidden><span class="truncate">Billing</span><span class="hero-check ml-auto size-4" aria-hidden="true"></span></a>
        </div>
      </div>
    </div>
  </div>
</nav>
```

## Narrow: everything in the menu

HEEx:

```heex
<%!-- too narrow for the active tab and More side by side: every tab
     folds into the menu and the trigger names the active one --%>
<.tab_nav id="call-queue" aria-label="Call queue">
  <:tab
    :for={q <- @queues}
    patch={~p"/calls?queue=#{q.slug}"}
    active={@queue == q.slug}
    count={q.count}
  >
    {q.title}
  </:tab>
</.tab_nav>
```

```html
<nav id="call-queue" data-tab-nav aria-label="Call queue" class="tab-nav">
  <div class="tabs tabs-box tab-nav-list">
    <div class="tab-nav-tabs" data-tab-nav-tabs>
      <a href="#all" class="tab" data-tab-nav-item data-index="0"><span class="tab-nav-label">All calls</span><span class="tab-count">240</span></a>
      <a href="#needs-call" class="tab tab-active" aria-current="page" data-tab-nav-item data-index="1"><span class="tab-nav-label">Needs a call</span><span class="tab-count">17</span></a>
      <a href="#scheduled" class="tab" data-tab-nav-item data-index="2"><span class="tab-nav-label">Scheduled</span><span class="tab-count">52</span></a>
      <a href="#voicemail" class="tab" data-tab-nav-item data-index="3"><span class="tab-nav-label">Voicemail</span><span class="tab-count">9</span></a>
      <a href="#closed" class="tab" data-tab-nav-item data-index="4"><span class="tab-nav-label">Closed</span><span class="tab-count">1,204</span></a>
    </div>
    <div class="tab-nav-more" data-tab-nav-more>
      <button type="button" class="tab" aria-expanded="false" aria-controls="call-queue-menu" data-tab-nav-trigger>
        <span class="tab-nav-label" data-tab-nav-default>More</span>
        <span class="tab-nav-label" data-tab-nav-current>Needs a call</span><span class="tab-count" data-tab-nav-current>17</span>
        <span class="hero-chevron-down size-4 opacity-50" aria-hidden="true"></span>
      </button>
      <div id="call-queue-menu" class="popover-panel tab-nav-menu" data-tab-nav-menu hidden>
        <div data-tab-nav-overflow hidden>
          <a href="#all" class="combo-item" tabindex="-1" data-tab-nav-copy data-index="0" hidden><span class="truncate">All calls</span><span class="ml-auto font-mono text-xs text-muted-foreground">240</span></a>
          <a href="#needs-call" class="combo-item" aria-current="page" tabindex="-1" data-tab-nav-copy data-index="1" hidden><span class="truncate">Needs a call</span><span class="ml-auto font-mono text-xs text-muted-foreground">17</span><span class="hero-check size-4" aria-hidden="true"></span></a>
          <a href="#scheduled" class="combo-item" tabindex="-1" data-tab-nav-copy data-index="2" hidden><span class="truncate">Scheduled</span><span class="ml-auto font-mono text-xs text-muted-foreground">52</span></a>
          <a href="#voicemail" class="combo-item" tabindex="-1" data-tab-nav-copy data-index="3" hidden><span class="truncate">Voicemail</span><span class="ml-auto font-mono text-xs text-muted-foreground">9</span></a>
          <a href="#closed" class="combo-item" tabindex="-1" data-tab-nav-copy data-index="4" hidden><span class="truncate">Closed</span><span class="ml-auto font-mono text-xs text-muted-foreground">1,204</span></a>
        </div>
      </div>
    </div>
  </div>
</nav>
```
