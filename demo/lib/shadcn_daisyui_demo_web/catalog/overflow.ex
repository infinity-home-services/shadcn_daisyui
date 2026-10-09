defmodule ShadcnDaisyuiDemoWeb.Catalog.Overflow do
  @moduledoc """
  Catalog pages for the 0.8 width-aware rows: link tabs that overflow into a
  More menu (<.tab_nav>), a chip row that collapses into "+N" (<.chip_row>),
  and the sanctioned collapsing-row animation (<.reveal>). Their design
  metadata (specs, accessibility, SwiftUI) is inline here.

  Each example's code is the markup the function component renders (minus the
  LiveView-only phx-hook / phx-mounted attributes), so it works as a
  plain-HTML recipe with initShadcnDaisyui(). The overflow examples are
  `resizable`: the docs preview adds a width slider.
  """

  def all, do: [tab_nav(), chip_row(), reveal()]

  defp tab_nav do
    %{
      slug: "tab-nav",
      title: "Tab Nav",
      description:
        "A row of link tabs that fits its width: tabs that don't fit move into a More menu, which also holds extra views.",
      hook: true,
      guidance: %{
        use_when: [
          "Saved views or filters of one list (All / Active / Backlog / …) where each view is a URL",
          "Sections of a page or settings area that people deep-link to",
          "Rows whose tab count or labels vary (user-created views, translated labels)"
        ],
        avoid_when: [
          "Panels on the same URL with no navigation - use tabs (radio-based)",
          "Primary app navigation - that's the dock / sidebar's job",
          "Two to four fixed peers that always fit - plain tabs are simpler"
        ],
        sizing:
          "The boxed tabs look: h-7 text-sm triggers in a p-[3px] muted list (h-10 on touch). Counts are a 20px muted pill. The More menu is floating content: rounded-md, p-1, ring-1 ring-foreground/10, shadow-md, 32px rows (44px on touch).",
        responsive:
          "Never wraps or scrolls: on compact the row keeps the active tab and as many neighbours as fit, and the rest move into More. On phones prefer three to five short labels; long tails live in the menu.",
        ios:
          "A segmented Picker for two to four views; past that, a Menu in the toolbar (or a navigation title menu) listing every view, with a checkmark on the current one."
      },
      props: [
        %{name: "id", type: "string (required)", default: "-"},
        %{name: "aria_label", type: "string", default: ~s("Tabs")},
        %{name: "more_label", type: "string", default: ~s("More")},
        %{name: ":tab navigate / patch / href", type: "slot attrs", default: "-"},
        %{name: ":tab active", type: "boolean", default: "false"},
        %{name: ":tab count", type: "number | string", default: "nil"},
        %{
          name: ":menu_item navigate / patch / href / phx-click",
          type: "slot attrs",
          default: "-"
        },
        %{
          name: ":menu_item group / icon / active",
          type: "string / string / boolean",
          default: "nil"
        }
      ],
      notes:
        "Needs the ShadcnTabNav hook (or initShadcnDaisyui() in dead views). Every tab renders twice, once in the row and once hidden in the menu, and the hook only flips hidden on the two copies, so LiveView patches never fight it; it re-fits on resize (ResizeObserver), after web fonts load, and in updated(), all before the browser paints. The active tab always stays in the row, swapping out the last visible one. When an active :menu_item lives in the menu, More shows its name. When even the active tab and More don't fit side by side, every tab folds into the menu (the active one checked) and the trigger names the active tab with its count, e.g. \"Needs a call 17\"; the label truncates with an ellipsis, the count never does.",
      specs: %{
        anatomy: [
          %{
            part: "Nav",
            description:
              "<nav aria-label> landmark that fills its container (the observed width)."
          },
          %{
            part: "List",
            description: "tabs-box segmented list, fit-content up to the nav width, never wraps."
          },
          %{
            part: "Tab",
            description:
              "A link (.tab) with an optional count pill; the active one is the white box with aria-current=page."
          },
          %{
            part: "More trigger",
            description:
              "A .tab button with a chevron (aria-expanded, aria-controls). Shows the active menu item's name when there is one."
          },
          %{
            part: "Menu",
            description:
              "Floating panel: overflowed tabs first (in order), a separator, then the :menu_item sections with group labels."
          }
        ],
        measurements: [
          %{property: "Tab height", value: "1.75rem / 28px (2.5rem on touch)"},
          %{property: "List padding", value: "3px, radius var(--radius-lg)"},
          %{
            property: "Count pill",
            value: "1.25rem min, rounded-full, text-xs tabular-nums, foreground 8%"
          },
          %{
            property: "Menu",
            value: "min 12rem, max 18rem, max-h 20rem, p-1, 4px below the list"
          },
          %{property: "Menu row", value: "0.375rem 0.5rem padding, rounded-sm, 44px min on touch"}
        ],
        tokens: [
          "muted",
          "muted-foreground",
          "background",
          "foreground",
          "popover",
          "popover-foreground",
          "accent",
          "accent-foreground",
          "border-color",
          "ring"
        ]
      },
      accessibility: %{
        roles:
          "Link tabs are navigation, not an ARIA tablist: a <nav aria-label> of links, the current one aria-current=page. More is a disclosure button (aria-expanded, aria-controls) for a panel of links; :menu_item groups are role=group named by their label.",
        keyboard: [
          %{
            keys: "Tab / Shift+Tab",
            action: "Move through the visible tabs and More, like any links"
          },
          %{
            keys: "Left / Right",
            action: "Move across the visible tabs and into More (wraps; mirrored in RTL)"
          },
          %{keys: "Home / End", action: "First tab / More"},
          %{
            keys: "Enter / Space / Down",
            action: "On More: open the menu and focus its first link"
          },
          %{keys: "Up", action: "On More: open the menu and focus its last link"},
          %{keys: "Up / Down, Home / End", action: "Move within the menu"},
          %{
            keys: "Esc",
            action: "Close the menu, focus More (does not close a surrounding sheet)"
          },
          %{keys: "Tab", action: "Leave the menu (closes it)"}
        ],
        focus:
          "Tabs and menu links show the 3px ring. If a focused tab is pushed into the menu by a resize, focus moves to More instead of disappearing.",
        screen_reader:
          "Hidden copies are display:none, so each destination is announced once. More reads as \"More, collapsed\", or \"More: Open bugs\" when the active view is in the menu; counts are read after the label.",
        touch_target:
          "Tabs grow to 40px (46px with the list padding) and menu rows to 44px on coarse pointers; the menu opens on tap and closes on an outside tap.",
        reduced_motion: "Fitting and the menu are instant; nothing animates."
      },
      swiftui: %{
        code: ~S"""
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
        """,
        notes:
          "iOS has no width-fitting tab strip. Use a segmented Picker (.pickerStyle(.segmented)) when two to four views always fit; otherwise a single Menu whose label is the current view, which is exactly the overflow state of the web row. ViewThatFits can choose between the two at runtime."
      },
      ios_status: :partial,
      examples: [
        %{
          title: "Views with a More menu",
          center: false,
          resizable: true,
          heex: ~S"""
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
          """,
          code: ~S"""
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
          """
        },
        %{
          title: "Active view in the menu",
          center: false,
          resizable: true,
          heex: ~S"""
          <.tab_nav id="issue-views" aria-label="Views">
            <:tab :for={v <- @views} patch={~p"/issues?view=#{v.slug}"} count={v.count}>{v.title}</:tab>
            <:menu_item group="Shared" patch={~p"/issues?view=bugs"} active={@view == "bugs"}>
              Open bugs
            </:menu_item>
          </.tab_nav>
          """,
          code: ~S"""
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
          """
        },
        %{
          title: "Tabs only (active stays visible)",
          center: false,
          resizable: true,
          heex: ~S"""
          <.tab_nav id="settings-nav" aria-label="Settings">
            <:tab navigate={~p"/settings"} active={@section == :overview}>Overview</:tab>
            <:tab navigate={~p"/settings/analytics"}>Analytics</:tab>
            <:tab navigate={~p"/settings/reports"}>Reports</:tab>
            <:tab navigate={~p"/settings/notifications"}>Notifications</:tab>
            <:tab navigate={~p"/settings/integrations"}>Integrations</:tab>
            <:tab navigate={~p"/settings/billing"} active={@section == :billing}>Billing</:tab>
          </.tab_nav>
          """,
          code: ~S"""
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
          """
        },
        %{
          title: "Narrow: everything in the menu",
          center: false,
          resizable: true,
          width: 25,
          heex: ~S"""
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
          """,
          code: ~S"""
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
          """
        }
      ]
    }
  end

  defp chip_row do
    %{
      slug: "chip-row",
      title: "Chip Row",
      description:
        "One line of removable chips: the ones that don't fit collapse into a +N chip that opens a popover listing them.",
      hook: true,
      guidance: %{
        use_when: [
          "Active filters above a list or table, each removable on its own",
          "Recipients, tags or selected values shown compactly in a toolbar or form",
          "Rows whose chip count varies and must stay one line high"
        ],
        avoid_when: [
          "Picking values - use <.select multiple> or <.combobox multiple>; the chip row shows the result",
          "Status labels that aren't removable - plain badges",
          "Every chip must always be visible - let them wrap (flex-wrap gap-2) instead"
        ],
        sizing:
          "Badge metrics (text-xs, rounded-full, py-0.5 px-2) with a 16px remove button; 32px chips on touch. The +N chip is an outline badge; the popover is floating content with p-3 and wrapping chips. 8px between chips.",
        responsive:
          "Always one line: compact screens show fewer chips and a larger +N. Trailing actions (Clear all) keep their space; the chips give way first.",
        ios:
          "A horizontal row of capsule buttons that ends in a \"+N\" button opening a sheet (or a List with swipe-to-delete) of the rest."
      },
      props: [
        %{name: "id", type: "string (required)", default: "-"},
        %{name: "aria_label", type: "string", default: ~s("Chips")},
        %{name: "variant", type: "secondary | outline", default: "secondary"},
        %{name: "more_label", type: "string ({count})", default: ~s("Show {count} more")},
        %{name: ":chip value", type: "any", default: "nil"},
        %{name: ":chip on_remove", type: "event name | JS", default: "nil"},
        %{name: ":chip remove_label", type: "string", default: ~s("Remove" + chip text)},
        %{name: ":chip removable", type: "boolean", default: "true"},
        %{name: ":action", type: "slot", default: "-"}
      ],
      notes:
        "Needs the ShadcnChipRow hook (or initShadcnDaisyui()). In LiveView pass on_remove (e.g. JS.push(\"remove_filter\", value: %{id: f.id})); the server drops the chip and the patch re-fits the row. Without it the hook removes the chip itself after a cancelable chip-remove event ({ value, index }) bubbles from the root; a data-chip-row-clear button does the same for every chip (chip-clear). After a removal focus moves to the chip that took its place, then +N, then the last chip.",
      specs: %{
        anatomy: [
          %{
            part: "Row",
            description: "role=group (aria-label) flex row, one line, fills its container."
          },
          %{
            part: "Chip",
            description:
              "A badge list item: label (truncates when it alone is too wide) + remove button."
          },
          %{
            part: "Remove",
            description: "16px round icon button, 60% opacity, named \"Remove <label>\"."
          },
          %{
            part: "+N chip",
            description: "Outline badge button (aria-expanded) whose name is \"Show N more\"."
          },
          %{
            part: "Popover",
            description: "Floating panel of the collapsed chips (wrapping), each removable."
          },
          %{part: "Actions", description: "Optional trailing content that always stays visible."}
        ],
        measurements: [
          %{
            property: "Chip",
            value: "text-xs, py-0.5 px-2 (pe-1 with remove), rounded-full; 2rem min on touch"
          },
          %{property: "Remove button", value: "1rem (1.5rem on touch, 44px hit area)"},
          %{property: "Gap", value: "0.5rem between chips, +N and actions"},
          %{property: "Popover", value: "p-3, max 18rem wide, max-h 16rem, 4px below +N"}
        ],
        tokens: [
          "secondary",
          "secondary-foreground",
          "border-color",
          "foreground",
          "popover",
          "accent",
          "accent-foreground",
          "ring"
        ]
      },
      accessibility: %{
        roles:
          "The row is role=group with a name; chips are a list, so a screen reader announces how many are visible. Each remove button is named \"Remove\" plus the chip text (aria-labelledby), or remove_label. +N is a disclosure button (aria-expanded, aria-controls) labelled \"Show N more\".",
        keyboard: [
          %{
            keys: "Tab / Shift+Tab",
            action: "Move through the remove buttons, +N and the actions"
          },
          %{
            keys: "Enter / Space / Down",
            action: "On +N: open the popover and focus its first remove button"
          },
          %{
            keys: "Arrow keys, Home / End",
            action: "Move between the remove buttons in the popover"
          },
          %{keys: "Enter / Space", action: "Remove the focused chip"},
          %{keys: "Esc", action: "Close the popover, focus +N"}
        ],
        focus:
          "Removing a chip never drops focus to the page: it lands on the chip that took its place, the previous one, +N, or the first action.",
        screen_reader:
          "Hidden copies are display:none, so each chip is announced once, in the row or in the popover. The list length tells how many chips are visible; +N says how many more there are.",
        touch_target:
          "On coarse pointers chips are 32px and the remove button and +N reach a 44px hit area through an invisible pseudo-element inside the 8px gap.",
        reduced_motion:
          "Nothing animates. Wrap the row in <.reveal> to slide it in and out (instant under reduced motion)."
      },
      swiftui: %{
        code: ~S"""
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
        """,
        notes:
          "ViewThatFits picks the first candidate that fits, which reproduces the fitting rule. Show the rest in a sheet with a List and swipe-to-delete (or EditButton)."
      },
      ios_status: :partial,
      examples: [
        %{
          title: "Active filters",
          center: false,
          resizable: true,
          heex: ~S"""
          <.chip_row id="active-filters" aria-label="Active filters">
            <:chip :for={f <- @filters} value={f.id} on_remove={JS.push("remove_filter", value: %{id: f.id})}>
              {f.field}: {f.label}
            </:chip>
            <:action>
              <button type="button" class="btn btn-ghost btn-sm" phx-click="clear_filters">Clear all</button>
            </:action>
          </.chip_row>
          """,
          code: ~S"""
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
          """
        },
        %{
          title: "Outline (recipients)",
          center: false,
          resizable: true,
          heex: ~S"""
          <.chip_row id="recipients" aria-label="Recipients" variant="outline">
            <:chip :for={r <- @recipients} value={r.email} on_remove={JS.push("remove_recipient", value: %{email: r.email})}>
              {r.email}
            </:chip>
          </.chip_row>
          """,
          code: ~S"""
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
          """
        }
      ]
    }
  end

  defp reveal do
    %{
      slug: "reveal",
      title: "Reveal",
      description:
        "Slides a row open and closed in place: grid-template-rows 0fr to 1fr plus opacity, 180ms ease-out.",
      guidance: %{
        use_when: [
          "A row that appears and disappears inside the page flow: active filter chips, an inline alert, a bulk-action bar",
          "Optional fields revealed by a toggle (\"More options\")"
        ],
        avoid_when: [
          "Floating content (menus, popovers) - those fade and scale, they don't push the page",
          "Page content on load - content appears immediately",
          "Large regions or whole sections - navigate, use an accordion, or a sheet"
        ],
        sizing:
          "No metrics of its own. Put spacing inside (class=\"pt-3\") rather than on the parent: space-y-* or gap-* keeps the gap while the row is closed.",
        responsive:
          "Same at every size class. Keep revealed rows short; tall content belongs in a sheet on compact.",
        ios:
          "Insert or remove the row with withAnimation(.easeOut(duration: 0.18)) and .transition(.opacity.combined(with: .move(edge: .top))); the system honors Reduce Motion."
      },
      props: [
        %{name: "open", type: "boolean", default: "false"},
        %{name: "id", type: "string", default: "nil"},
        %{name: "client", type: "boolean", default: "false"},
        %{name: "class", type: "classes for the content", default: "nil"}
      ],
      notes:
        "This is the one sanctioned layout animation (styles-motion.md): the accordion / collapse already animates grid-template-rows the same way. The server owns open (flip an assign); for client-side toggles give it an id and point a <button data-reveal-toggle=\"id\"> at it (shadcn-daisyui.js sets data-open and aria-expanded), and pass client so LiveView patches keep the toggled state. Plain HTML: <div class=\"reveal\" data-open><div class=\"reveal-track\"><div>…</div></div></div>.",
      specs: %{
        anatomy: [
          %{
            part: "Reveal",
            description: ".reveal grid with one row: 0fr closed, 1fr open (data-open)."
          },
          %{
            part: "Track",
            description: ".reveal-track: min-height 0, clips the content while it grows."
          },
          %{
            part: "Content",
            description: "Your row; the class attr lands here, so padding is safe."
          }
        ],
        measurements: [
          %{property: "Duration", value: "180ms (small-surface tier)"},
          %{property: "Easing", value: "ease-out"},
          %{
            property: "Properties",
            value: "grid-template-rows 0fr ↔ 1fr, opacity 0 ↔ 1, visibility"
          },
          %{property: "Reduced motion", value: "transition: none (instant)"}
        ],
        tokens: []
      },
      accessibility: %{
        roles:
          "No role of its own. A client toggle is a disclosure: the button carries aria-expanded and aria-controls (set by the package JS). Server-driven rows that announce something (an inline alert) keep their own role=alert / role=status.",
        keyboard: [
          %{
            keys: "Enter / Space",
            action: "On a data-reveal-toggle button: open or close the row"
          }
        ],
        focus:
          "Closed content is visibility:hidden once collapsed, so it leaves the tab order. If focus is inside when it closes, move it to the toggle (the toggle usually still has it).",
        screen_reader:
          "Closed content is hidden from assistive tech; opening it does not announce by itself, so rows that matter (errors) should be role=alert or role=status.",
        touch_target: "The toggle is a normal button: 44px on touch per the interaction rules.",
        reduced_motion:
          "prefers-reduced-motion: reduce removes the transition; the row appears and disappears instantly."
      },
      swiftui: %{
        code: ~S"""
        VStack(alignment: .leading, spacing: 0) {
            Button(showFilters ? "Hide filters" : "Filters") {
                withAnimation(.easeOut(duration: 0.18)) { showFilters.toggle() }
            }
            if showFilters {
                FilterChips(filters: $filters)
                    .padding(.top, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            ResultsList()
        }
        .clipped()
        """,
        notes:
          "Insertion with a transition is the SwiftUI equivalent; the Motion.surface preset (0.18s ease-out) matches the web timing. Respect accessibilityReduceMotion by dropping the move and keeping (or skipping) the fade."
      },
      ios_status: :parity,
      examples: [
        %{
          title: "Filter row",
          center: false,
          heex: ~S"""
          <button type="button" class="btn btn-outline btn-sm" phx-click="toggle_filters">
            <.icon name="hero-funnel" class="size-4" /> Filters
          </button>
          <.reveal open={@filters != []} class="pt-3">
            <.chip_row id="active-filters" aria-label="Active filters">…</.chip_row>
          </.reveal>
          <div class="card mt-3">…results…</div>
          """,
          code: ~S"""
          <div class="w-full">
            <button type="button" class="btn btn-outline btn-sm" data-reveal-toggle="filter-row" aria-expanded="false">
              <span class="hero-funnel size-4" aria-hidden="true"></span> Filters
            </button>
            <div id="filter-row" class="reveal">
              <div class="reveal-track">
                <div class="pt-3">
                <div id="reveal-filters" data-chip-row role="group" aria-label="Active filters" class="chip-row">
                  <ul class="chip-row-chips" data-chip-row-chips>
                    <li class="badge chip badge-secondary" data-index="0" data-value="status:todo" data-chip><span id="reveal-filters-chip-0-label" class="chip-label">Status: Todo</span><button type="button" id="reveal-filters-chip-0-remove" class="chip-remove" aria-label="Remove" aria-labelledby="reveal-filters-chip-0-remove reveal-filters-chip-0-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
                    <li class="badge chip badge-secondary" data-index="1" data-value="status:in-progress" data-chip><span id="reveal-filters-chip-1-label" class="chip-label">Status: In progress</span><button type="button" id="reveal-filters-chip-1-remove" class="chip-remove" aria-label="Remove" aria-labelledby="reveal-filters-chip-1-remove reveal-filters-chip-1-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
                    <li class="badge chip badge-secondary" data-index="2" data-value="priority:high" data-chip><span id="reveal-filters-chip-2-label" class="chip-label">Priority: High</span><button type="button" id="reveal-filters-chip-2-remove" class="chip-remove" aria-label="Remove" aria-labelledby="reveal-filters-chip-2-remove reveal-filters-chip-2-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
                    <li class="badge chip badge-secondary" data-index="3" data-value="label:bug" data-chip><span id="reveal-filters-chip-3-label" class="chip-label">Label: Bug</span><button type="button" id="reveal-filters-chip-3-remove" class="chip-remove" aria-label="Remove" aria-labelledby="reveal-filters-chip-3-remove reveal-filters-chip-3-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
                  </ul>
                  <div class="chip-row-more" data-chip-row-more hidden>
                    <button type="button" class="badge badge-outline chip chip-more" aria-expanded="false" aria-controls="reveal-filters-overflow" data-chip-row-trigger data-more-label="Show {count} more"></button>
                    <div id="reveal-filters-overflow" class="popover-panel chip-row-panel" data-chip-row-panel hidden>
                      <ul class="flex flex-wrap gap-2" aria-label="Active filters">
                        <li class="badge chip badge-secondary" data-index="0" data-value="status:todo" hidden data-chip-copy><span id="reveal-filters-copy-0-label" class="chip-label">Status: Todo</span><button type="button" id="reveal-filters-copy-0-remove" class="chip-remove" aria-label="Remove" aria-labelledby="reveal-filters-copy-0-remove reveal-filters-copy-0-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
                        <li class="badge chip badge-secondary" data-index="1" data-value="status:in-progress" hidden data-chip-copy><span id="reveal-filters-copy-1-label" class="chip-label">Status: In progress</span><button type="button" id="reveal-filters-copy-1-remove" class="chip-remove" aria-label="Remove" aria-labelledby="reveal-filters-copy-1-remove reveal-filters-copy-1-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
                        <li class="badge chip badge-secondary" data-index="2" data-value="priority:high" hidden data-chip-copy><span id="reveal-filters-copy-2-label" class="chip-label">Priority: High</span><button type="button" id="reveal-filters-copy-2-remove" class="chip-remove" aria-label="Remove" aria-labelledby="reveal-filters-copy-2-remove reveal-filters-copy-2-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
                        <li class="badge chip badge-secondary" data-index="3" data-value="label:bug" hidden data-chip-copy><span id="reveal-filters-copy-3-label" class="chip-label">Label: Bug</span><button type="button" id="reveal-filters-copy-3-remove" class="chip-remove" aria-label="Remove" aria-labelledby="reveal-filters-copy-3-remove reveal-filters-copy-3-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
                      </ul>
                    </div>
                  </div>
                  <div class="chip-row-actions" data-chip-row-actions>
                    <button type="button" class="btn btn-ghost btn-sm" data-reveal-toggle="filter-row" aria-expanded="false">Clear all</button>
                  </div>
                </div>
                </div>
              </div>
            </div>
            <div class="card mt-3 w-full">
              <div class="card-body gap-1 text-sm">
                <p class="font-medium">128 issues</p>
                <p class="text-muted-foreground">The results move down while the filter row slides open.</p>
              </div>
            </div>
          </div>
          """
        },
        %{
          title: "Inline alert",
          center: false,
          heex: ~S"""
          <.reveal open={@saved?} class="pb-3">
            <.alert><:title>Changes saved</:title>Your profile has been updated.</.alert>
          </.reveal>
          """,
          code: ~S"""
          <div class="w-full max-w-md">
            <div id="saved-alert" class="reveal">
              <div class="reveal-track">
                <div class="pb-3">
                  <div class="alert" role="status">
                    <span class="hero-check-circle size-4" aria-hidden="true"></span>
                    <div>
                      <h3 class="text-sm font-medium">Changes saved</h3>
                      <p class="text-sm text-muted-foreground">Your profile has been updated.</p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <button type="button" class="btn btn-outline" data-reveal-toggle="saved-alert" aria-expanded="false">Toggle alert</button>
          </div>
          """
        }
      ]
    }
  end
end
