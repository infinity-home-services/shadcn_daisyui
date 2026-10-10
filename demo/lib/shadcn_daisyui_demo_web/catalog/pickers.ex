defmodule ShadcnDaisyuiDemoWeb.Catalog.Pickers do
  @moduledoc """
  Catalog pages for the 0.7 picker features: multiple on <.select> /
  <.combobox> (bits-ui Select type="multiple" and shadcn's data-table
  faceted filter), the form-bindable <.date_range> with presets, and
  <.time_picker>. Their design metadata (specs, accessibility, SwiftUI) is inline here.

  Each example's code is the markup the function component renders, so it
  works as a plain-HTML recipe with initShadcnDaisyui().
  """

  def all, do: [multi_select(), date_range_picker(), time_picker()]

  defp multi_select do
    %{
      slug: "multi-select",
      title: "Multi Select",
      description:
        "Pick several values from a list: multiple on Select and Combobox, with checkbox rows, counts and Clear.",
      hook: true,
      guidance: %{
        use_when: [
          "Filters and tags: several values of one field (status, labels, assignees)",
          "The data-table faceted filter - pass count for the matching rows per option",
          "Long lists (> ~10): use <.combobox multiple> so people can type to filter"
        ],
        avoid_when: [
          "Two to five always-visible options - a checkbox group shows every state at once",
          "One value - use <.select> or <.combobox> without multiple",
          "Free-form tags people invent - use an input with a tag pattern"
        ],
        sizing:
          "Trigger h-9 (field metrics); popover rounded-md, p-1, ring-1 ring-foreground/10, shadow-md; rows 32px desktop, 44px on touch; 16px checkbox; counts font-mono text-xs.",
        responsive:
          "On compact screens and in sheets use full_width: the trigger fills the container and grows to 44px on touch. The trigger shows two labels then +N, so it never wraps.",
        ios:
          "A List with selection (EditButton / .environment(\\.editMode)) or a NavigationLink to a checkmark list. Menus with Toggle items for short filter sets."
      },
      props: [
        %{name: "multiple", type: "boolean", default: "false"},
        %{name: "field", type: "Phoenix.HTML.FormField", default: "nil"},
        %{name: "name / value", type: "string / list", default: "nil"},
        %{name: "placeholder", type: "string", default: ~s("Select…")},
        %{name: "full_width", type: "boolean", default: "false"},
        %{name: "clear_label", type: "string", default: ~s("Clear")},
        %{name: "disabled", type: "boolean", default: "false"},
        %{name: "aria-label / aria-labelledby", type: "string", default: "nil"},
        %{name: ":option value count", type: "slot", default: "-"},
        %{
          name: "search_placeholder / empty (combobox)",
          type: "string",
          default: "placeholder / \"No results.\""
        }
      ],
      notes:
        "Form params: an always-present name=\"\" input plus one name[] input per value, so a selection posts [\"a\", \"b\"] and a cleared one posts \"\" (Ecto casts it to the field default). Each toggle dispatches input + change on the form, so phx-change fires; a select-change / combobox-change event with { value } bubbles from the root. The open list, label and checks survive LiveView patches, and a server-side change to the value (a reset) wins.",
      specs: %{
        anatomy: [
          %{
            part: "Trigger",
            description:
              "Outline field button (role=combobox on select). Shows the placeholder, or up to two selected labels then a muted +N."
          },
          %{
            part: "Search (combobox)",
            description: "Filters rows by label and value; Space types, Enter toggles."
          },
          %{
            part: "Listbox",
            description:
              "role=listbox with aria-multiselectable=true; rows are role=option with aria-selected."
          },
          %{
            part: "Checkbox row",
            description:
              "16px box (primary border, filled + check when selected, 50% when not), label, optional right-aligned count."
          },
          %{
            part: "Clear row",
            description: "Separated footer action, shown once anything is selected."
          },
          %{
            part: "Hidden inputs",
            description: "name=\"\" sentinel + one name[] per value, kept in sync by the hook."
          }
        ],
        measurements: [
          %{
            property: "Trigger height",
            value: "2.25rem / 36px (2.75rem on touch with full_width)"
          },
          %{property: "Popover", value: "rounded-md, p-1, ring-1 ring-foreground/10, shadow-md"},
          %{property: "Row", value: "0.375rem 0.5rem padding, rounded-sm, 44px min on touch"},
          %{property: "Checkbox", value: "1rem, rounded-sm, 1px var(--primary)"},
          %{property: "Count", value: "font-mono 0.75rem, var(--muted-foreground)"},
          %{property: "List height", value: "max 18rem (select) / 15rem (combobox), scrolls"}
        ],
        tokens: [
          "popover",
          "popover-foreground",
          "accent",
          "accent-foreground",
          "primary",
          "primary-foreground",
          "muted-foreground",
          "border-color",
          "input",
          "ring"
        ]
      },
      accessibility: %{
        roles:
          "Select: the trigger is role=combobox (aria-haspopup=listbox, aria-expanded, aria-controls, aria-activedescendant). Combobox: the search box carries those roles. The list is role=listbox aria-multiselectable=true; rows are role=option with aria-selected. Name the control with a <label for> on the trigger (field binding sets its id to the field id), aria-label or aria-labelledby.",
        keyboard: [
          %{keys: "Enter / Space / Down / Up", action: "Open the list from the trigger"},
          %{keys: "Up / Down", action: "Move the active row (wraps)"},
          %{keys: "Home / End", action: "First / last row (select)"},
          %{keys: "Space / Enter", action: "Toggle the active row; the list stays open"},
          %{keys: "Type (combobox)", action: "Filter rows; Space types, Enter toggles"},
          %{keys: "Tab", action: "Reach the Clear row, then leave (closes the list)"},
          %{
            keys: "Esc",
            action: "Close and return focus to the trigger (does not close a surrounding sheet)"
          }
        ],
        focus:
          "Focus stays on the trigger (or search box) while toggling - clicks on rows do not steal it - and the active row is tracked with aria-activedescendant and the accent fill.",
        screen_reader:
          "Each row announces its label, count and selected state; the trigger reads the selected labels and \"+N more\". The listbox announces as multi-selectable.",
        touch_target:
          "Rows are 44px tall on coarse pointers; pass full_width for a 44px trigger in sheets and compact forms.",
        reduced_motion: "The list toggles without movement, so there is nothing to reduce."
      },
      swiftui: %{
        code: ~S"""
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
        """,
        notes:
          "A List bound to a Set<ID> in edit mode is the native multi-select. For a compact filter in a toolbar, a Menu of Toggle items (one per value) matches the faceted-filter popover."
      },
      ios_status: :partial,
      examples: [
        %{
          title: "Select multiple",
          heex: ~S"""
          <.select id="status-filter" multiple placeholder="Status" aria-label="Status">
            <:option value="backlog">Backlog</:option>
            <:option value="todo">Todo</:option>
            <:option value="in-progress">In progress</:option>
            <:option value="done">Done</:option>
            <:option value="canceled">Canceled</:option>
          </.select>
          """,
          code: ~S"""
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
          """
        },
        %{
          title: "Faceted filter (combobox with counts)",
          heex: ~S"""
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
          """,
          code: ~S"""
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
          """
        },
        %{
          title: "Form (field binding, full width)",
          heex: ~S"""
          <.form for={@form} id="member-form" phx-change="validate" phx-submit="save" class="w-full max-w-sm space-y-2">
            <.label for={@form[:roles].id}>Roles</.label>
            <.select id="member-roles" field={@form[:roles]} multiple full_width placeholder="Pick roles">
              <:option value="viewer">Viewer</:option>
              <:option value="editor">Editor</:option>
              <:option value="billing">Billing</:option>
              <:option value="admin">Admin</:option>
            </.select>
          </.form>
          """,
          code: ~S"""
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
          """
        }
      ]
    }
  end

  defp date_range_picker do
    %{
      slug: "date-range-picker",
      title: "Date Range Picker",
      description:
        "A popover with two months and optional preset ranges, bound to a form as two ISO dates.",
      hook: true,
      guidance: %{
        use_when: [
          "Report periods and filters where the range is one field among several",
          "Forms that store a start and an end date - bind start_name / end_name",
          "Common ranges people pick repeatedly - add :preset slots"
        ],
        avoid_when: [
          "The range is the main control of the page (booking) - use <.range_calendar> inline",
          "A single date - use <.date_picker>",
          "Dates far from today (birthdays) - typed inputs are faster than paging months"
        ],
        sizing:
          "Trigger w-64 at field height; popover p-3, rounded-md, ring + shadow-md; 32px day cells; presets column 9rem with btn-sm rows.",
        responsive:
          "Under 640px the months stack and the presets wrap into a row above them. Keep the trigger full width in compact forms.",
        ios:
          "Two DatePickers (start, end) with .compact style, plus a Menu of preset ranges; or a sheet with a .graphical DatePicker per endpoint."
      },
      props: [
        %{name: "id", type: "string (required)", default: "-"},
        %{name: "start / end", type: "Date | ISO string", default: "nil"},
        %{name: "start_name / end_name", type: "string (form field names)", default: "nil"},
        %{name: "months", type: "integer", default: "2"},
        %{name: "placeholder", type: "string", default: ~s("Pick a date range")},
        %{name: ":preset label start end", type: "slot", default: "-"},
        %{name: ":preset label days", type: "slot (last N days ending today)", default: "-"}
      ],
      notes:
        "Hidden inputs carry ISO dates (YYYY-MM-DD) and dispatch input + change once a full range is picked (two days or a preset), so phx-change fires once per range, not per click. A half-picked range is dropped when the popover closes. The open popover and label survive LiveView patches; a changed server value wins. A range-change event with { start, end } bubbles from the root.",
      specs: %{
        anatomy: [
          %{
            part: "Trigger",
            description:
              "Outline field button (aria-haspopup=dialog, aria-expanded) with a calendar icon and the formatted range or placeholder."
          },
          %{
            part: "Popover",
            description: "role=dialog panel: presets column + calendar, floating-content styles."
          },
          %{
            part: "Presets",
            description: "Ghost btn-sm rows; one click sets the range, closes, and emits."
          },
          %{
            part: "Calendar",
            description:
              "Two role=grid months with the range band: endpoints primary, the span accent, rounded at week edges."
          },
          %{
            part: "Hidden inputs",
            description: "start_name / end_name, ISO dates, synced by the hook."
          }
        ],
        measurements: [
          %{property: "Trigger", value: "w-64 default, 2.25rem tall, var(--radius-md)"},
          %{property: "Popover", value: "p-3, rounded-md, ring-1 ring-foreground/10, shadow-md"},
          %{property: "Day cell", value: "2rem x 2rem, rounded-md"},
          %{property: "Presets column", value: "9rem, end border, 0.75rem gap"}
        ],
        tokens: [
          "popover",
          "popover-foreground",
          "primary",
          "primary-foreground",
          "accent",
          "accent-foreground",
          "muted-foreground",
          "border-color",
          "ring"
        ]
      },
      accessibility: %{
        roles:
          "The trigger is a button with aria-haspopup=dialog and aria-expanded; the popover is role=dialog named by the placeholder; each month is a role=grid of gridcells with full date labels and aria-selected on the endpoints.",
        keyboard: [
          %{keys: "Enter / Space", action: "Open the popover; focus moves to the calendar"},
          %{keys: "Arrows", action: "Move a day / week"},
          %{keys: "Home / End", action: "Start / end of the week"},
          %{keys: "PageUp / PageDown", action: "Previous / next month (Shift: year)"},
          %{keys: "Enter / Space on a day", action: "Pick the start, then the end"},
          %{keys: "Tab", action: "Reach the presets and month buttons"},
          %{
            keys: "Esc",
            action: "Close (drops a half-picked range) and return focus to the trigger"
          }
        ],
        focus:
          "Opening with the keyboard focuses the calendar's tab stop (the start date, else today). Picking a full range or a preset closes the popover and focus returns to the trigger.",
        screen_reader:
          "The trigger reads the committed range (\"Oct 4 – Oct 11, 2026\"); day cells read their full localized date and selected state. While picking, the label shows \"Oct 4 – …\".",
        touch_target:
          "Day cells are 32px - pad the popover or switch to <.range_calendar> in a sheet for touch-first flows. Preset rows are 32px; give them a full-width sheet on compact.",
        reduced_motion: "The popover toggles without movement."
      },
      swiftui: %{
        code: ~S"""
        @State private var from = Date.now.addingTimeInterval(-6 * 86_400)
        @State private var to = Date.now

        HStack {
            DatePicker("From", selection: $from, in: ...to, displayedComponents: .date)
            DatePicker("To", selection: $to, in: from..., displayedComponents: .date)
            Menu("Presets") {
                Button("Last 7 days") { (from, to) = (.now.addingTimeInterval(-6 * 86_400), .now) }
                Button("Last 30 days") { (from, to) = (.now.addingTimeInterval(-29 * 86_400), .now) }
            }
        }
        .labelsHidden()
        """,
        notes:
          "SwiftUI has no range DatePicker; two bounded compact pickers plus a presets Menu is the platform pattern. MultiDatePicker selects discrete days, not a span."
      },
      ios_status: :partial,
      examples: [
        %{
          title: "Presets",
          heex: ~S"""
          <.date_range id="period">
            <:preset label="Today" days={1} />
            <:preset label="Last 7 days" days={7} />
            <:preset label="Last 30 days" days={30} />
            <:preset label="Last 90 days" days={90} />
          </.date_range>
          """,
          code: ~S"""
          <div id="period" data-daterange data-months="2" data-placeholder="Pick a date range" class="relative w-64">
            <button type="button" data-daterange-trigger aria-haspopup="dialog" aria-expanded="false" class="btn btn-outline w-full justify-start gap-2 font-normal">
              <span class="hero-calendar size-4 opacity-70" aria-hidden="true"></span>
              <span data-daterange-label class="truncate text-muted-foreground">Pick a date range</span>
            </button>
            <div data-daterange-panel role="dialog" aria-label="Pick a date range" class="popover-panel absolute z-50 mt-1 hidden p-3">
              <div class="flex flex-col gap-3 sm:flex-row">
                <div class="flex flex-wrap gap-1 border-border sm:w-36 sm:flex-col sm:flex-nowrap sm:border-e sm:pe-3">
                  <button type="button" class="btn btn-ghost btn-sm justify-start font-normal" data-daterange-preset data-days="1">Today</button>
                  <button type="button" class="btn btn-ghost btn-sm justify-start font-normal" data-daterange-preset data-days="7">Last 7 days</button>
                  <button type="button" class="btn btn-ghost btn-sm justify-start font-normal" data-daterange-preset data-days="30">Last 30 days</button>
                  <button type="button" class="btn btn-ghost btn-sm justify-start font-normal" data-daterange-preset data-days="90">Last 90 days</button>
                </div>
                <div data-calendar-range></div>
              </div>
            </div>
          </div>
          """
        },
        %{
          title: "Form",
          heex: ~S"""
          <.form for={@form} id="report-form" phx-change="filter" class="space-y-2">
            <.date_range
              id="report-period"
              start_name={@form[:from].name}
              end_name={@form[:to].name}
              start={@form[:from].value}
              end={@form[:to].value}
            >
              <:preset label="Last 7 days" start={Date.add(@today, -6)} end={@today} />
              <:preset label="This month" start={Date.beginning_of_month(@today)} end={@today} />
            </.date_range>
          </.form>
          """,
          code: ~S"""
          <form class="space-y-2">
            <div id="report-period" data-daterange data-months="2" data-start="2026-10-01" data-end="2026-10-09" data-placeholder="Pick a date range" class="relative w-64">
              <input type="hidden" name="report[from]" value="2026-10-01" data-range-start />
              <input type="hidden" name="report[to]" value="2026-10-09" data-range-end />
              <button type="button" data-daterange-trigger aria-haspopup="dialog" aria-expanded="false" class="btn btn-outline w-full justify-start gap-2 font-normal">
                <span class="hero-calendar size-4 opacity-70" aria-hidden="true"></span>
                <span data-daterange-label class="truncate">Oct 1 – Oct 9, 2026</span>
              </button>
              <div data-daterange-panel role="dialog" aria-label="Pick a date range" class="popover-panel absolute z-50 mt-1 hidden p-3">
                <div class="flex flex-col gap-3 sm:flex-row">
                  <div class="flex flex-wrap gap-1 border-border sm:w-36 sm:flex-col sm:flex-nowrap sm:border-e sm:pe-3">
                    <button type="button" class="btn btn-ghost btn-sm justify-start font-normal" data-daterange-preset data-days="7">Last 7 days</button>
                    <button type="button" class="btn btn-ghost btn-sm justify-start font-normal" data-daterange-preset data-start="2026-10-01" data-end="2026-10-09">Oct 1 – 9</button>
                  </div>
                  <div data-calendar-range></div>
                </div>
              </div>
            </div>
          </form>
          """
        }
      ]
    }
  end

  defp time_picker do
    %{
      slug: "time-picker",
      title: "Time Picker",
      description:
        "A field-style trigger that opens hour, minute and AM/PM columns, bound to a form as an ISO time.",
      hook: true,
      guidance: %{
        use_when: [
          "A time of day in a form: opening hours, a meeting start, a reminder",
          "Times on a fixed grid - set minute_step (15 for scheduling)",
          "Pair with <.date_picker> when a date and a time are separate fields"
        ],
        avoid_when: [
          "Durations (1h 30m) - use number inputs or a select of lengths",
          "Fast keyboard entry of many times - a native <input type=\"time\"> types faster",
          "A handful of fixed slots - show them as a <.select> or a toggle group"
        ],
        sizing:
          "Trigger w-40 at field height; popover p-1, rounded-md, ring + shadow-md; columns 14rem tall, 2.75rem x 2rem options, 1px border between columns.",
        responsive:
          "Use full_width in compact forms and sheets: the trigger fills the row and grows to 44px on touch, and options grow to 44px.",
        ios:
          "DatePicker with displayedComponents: .hourAndMinute (.compact in forms, .wheel inline). Use a minuteInterval on a UIDatePicker for stepped minutes."
      },
      props: [
        %{name: "id", type: "string (required)", default: "-"},
        %{name: "field", type: "Phoenix.HTML.FormField", default: "nil"},
        %{name: "name / value", type: "string / Time | ISO string", default: "nil"},
        %{name: "hour_cycle", type: "12 | 24", default: "12"},
        %{name: "minute_step", type: "integer", default: "1"},
        %{name: "seconds", type: "boolean", default: "false"},
        %{name: "placeholder", type: "string", default: ~s("Pick a time")},
        %{name: "full_width", type: "boolean", default: "false"},
        %{name: "disabled", type: "boolean", default: "false"},
        %{name: "aria-label / aria-labelledby", type: "string", default: "nil"}
      ],
      notes:
        "The hidden input carries a 24-hour ISO time (HH:MM, or HH:MM:SS with seconds), which an Ecto :time field casts. Every pick commits and dispatches input + change, so phx-change fires; picking a minute before an hour starts from midnight. The open popover and label survive LiveView patches; a changed server value wins. A time-change event with { value } bubbles from the root.",
      specs: %{
        anatomy: [
          %{
            part: "Trigger",
            description:
              "Outline field button (aria-haspopup=dialog, aria-expanded) with a clock icon and the formatted time or placeholder."
          },
          %{
            part: "Popover",
            description: "role=dialog panel holding the columns, floating-content styles."
          },
          %{
            part: "Columns",
            description:
              "One role=listbox per part (Hours, Minutes, Seconds, AM/PM), scrolling on their own, divided by a 1px border."
          },
          %{
            part: "Option",
            description:
              "role=option button: accent on hover, primary fill when selected, tabular numbers."
          },
          %{part: "Hidden input", description: "name, ISO time, synced by the hook."}
        ],
        measurements: [
          %{property: "Trigger", value: "w-40 default, 2.25rem tall, var(--radius-md)"},
          %{property: "Popover", value: "p-1, rounded-md, ring-1 ring-foreground/10, shadow-md"},
          %{
            property: "Column",
            value: "max 14rem tall, 0.25rem padding, 2px gap, scrollbar hidden"
          },
          %{property: "Option", value: "2.75rem x 2rem (3rem x 2.75rem on touch), rounded-sm"}
        ],
        tokens: [
          "popover",
          "popover-foreground",
          "primary",
          "primary-foreground",
          "accent",
          "accent-foreground",
          "border-color",
          "input",
          "ring"
        ]
      },
      accessibility: %{
        roles:
          "The trigger is a button with aria-haspopup=dialog and aria-expanded; the popover is role=dialog named by the placeholder. Each column is a role=listbox named Hours, Minutes, Seconds or AM/PM; options are role=option with aria-selected. Name the control with a <label for> on the trigger (field binding sets its id to the field id), aria-label or aria-labelledby.",
        keyboard: [
          %{keys: "Enter / Space", action: "Open the popover; focus moves to the hours column"},
          %{keys: "Up / Down", action: "Pick the previous / next value in the column"},
          %{keys: "Home / End", action: "First / last value in the column"},
          %{keys: "Left / Right", action: "Move to the previous / next column"},
          %{keys: "Tab", action: "Move between columns"},
          %{keys: "Enter", action: "Close and return focus to the trigger"},
          %{keys: "Esc", action: "Close and return focus to the trigger"}
        ],
        focus:
          "Each column has one tab stop, its selected value (else the first). Opening scrolls every column so its value sits at the top.",
        screen_reader:
          "The trigger reads the committed time (\"2:30 PM\"); each column announces its name and each option its value and selected state.",
        touch_target:
          "Options are 44px tall on coarse pointers; pass full_width for a 44px trigger in sheets and compact forms.",
        reduced_motion: "The popover toggles and columns jump without animation."
      },
      swiftui: %{
        code: ~S"""
        @State private var opensAt = Calendar.current.date(from: DateComponents(hour: 9))!

        DatePicker("Opens at", selection: $opensAt, displayedComponents: .hourAndMinute)
            .datePickerStyle(.compact)
        """,
        notes:
          "A compact hourAndMinute DatePicker is the native trigger-plus-popover equivalent and follows the device's 12/24-hour setting. SwiftUI has no minute step; wrap UIDatePicker (minuteInterval = 15) when you need one."
      },
      ios_status: :partial,
      examples: [
        %{
          title: "Default (15-minute steps)",
          heex: ~S"""
          <.time_picker id="meeting-time" minute_step={15} aria-label="Meeting time" />
          """,
          code: ~S"""
          <div id="meeting-time" data-timepicker data-hour-cycle="12" data-placeholder="Pick a time" class="relative w-40">
            <button type="button" id="meeting-time-trigger" data-timepicker-trigger aria-haspopup="dialog" aria-expanded="false" aria-label="Meeting time" class="btn btn-outline w-full justify-start gap-2 font-normal">
              <span class="hero-clock size-4 opacity-70" aria-hidden="true"></span>
              <span data-timepicker-label class="truncate text-muted-foreground">Pick a time</span>
            </button>
            <div data-timepicker-panel role="dialog" aria-label="Pick a time" class="popover-panel absolute z-50 mt-1 hidden p-1">
              <div class="time-columns">
                  <div role="listbox" aria-label="Hours" class="time-col" data-time-col="h">
                    <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="12">12</button>
                    <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="1">1</button>
                    <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="2">2</button>
                    <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="3">3</button>
                    <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="4">4</button>
                    <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="5">5</button>
                    <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="6">6</button>
                    <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="7">7</button>
                    <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="8">8</button>
                    <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="9">9</button>
                    <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="10">10</button>
                    <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="11">11</button>
                  </div>
                  <div role="listbox" aria-label="Minutes" class="time-col" data-time-col="m">
                    <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="0">00</button>
                    <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="15">15</button>
                    <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="30">30</button>
                    <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="45">45</button>
                  </div>
                  <div role="listbox" aria-label="AM/PM" class="time-col" data-time-col="p">
                    <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="AM">AM</button>
                    <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="PM">PM</button>
                  </div>
              </div>
            </div>
          </div>
          """
        },
        %{
          title: "Form (24-hour, full width)",
          heex: ~S"""
          <.form for={@form} id="store-form" phx-change="validate" class="w-full max-w-sm space-y-2">
            <.label for={@form[:opens_at].id}>Opens at</.label>
            <.time_picker
              id="opens-at"
              field={@form[:opens_at]}
              hour_cycle={24}
              minute_step={15}
              full_width
            />
          </.form>
          """,
          code: ~S"""
          <form class="w-full max-w-sm space-y-2">
            <label for="store_opens_at" class="text-sm font-medium">Opens at</label>
            <div id="opens-at" data-timepicker data-value="09:00" data-hour-cycle="24" data-full-width data-placeholder="Pick a time" class="relative w-full">
              <input type="hidden" name="store[opens_at]" value="09:00" data-timepicker-input />
              <button type="button" id="store_opens_at" data-timepicker-trigger aria-haspopup="dialog" aria-expanded="false" class="btn btn-outline w-full justify-start gap-2 font-normal">
                <span class="hero-clock size-4 opacity-70" aria-hidden="true"></span>
                <span data-timepicker-label class="truncate">09:00</span>
              </button>
              <div data-timepicker-panel role="dialog" aria-label="Pick a time" class="popover-panel absolute z-50 mt-1 hidden p-1">
                <div class="time-columns">
                    <div role="listbox" aria-label="Hours" class="time-col" data-time-col="h">
                      <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="0">00</button>
                      <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="1">01</button>
                      <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="2">02</button>
                      <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="3">03</button>
                      <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="4">04</button>
                      <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="5">05</button>
                      <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="6">06</button>
                      <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="7">07</button>
                      <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="8">08</button>
                      <button type="button" role="option" tabindex="-1" aria-selected="true" class="time-option" data-value="9">09</button>
                      <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="10">10</button>
                      <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="11">11</button>
                      <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="12">12</button>
                      <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="13">13</button>
                      <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="14">14</button>
                      <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="15">15</button>
                      <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="16">16</button>
                      <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="17">17</button>
                      <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="18">18</button>
                      <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="19">19</button>
                      <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="20">20</button>
                      <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="21">21</button>
                      <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="22">22</button>
                      <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="23">23</button>
                    </div>
                    <div role="listbox" aria-label="Minutes" class="time-col" data-time-col="m">
                      <button type="button" role="option" tabindex="-1" aria-selected="true" class="time-option" data-value="0">00</button>
                      <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="15">15</button>
                      <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="30">30</button>
                      <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="45">45</button>
                    </div>
                </div>
              </div>
            </div>
          </form>
          """
        }
      ]
    }
  end
end
