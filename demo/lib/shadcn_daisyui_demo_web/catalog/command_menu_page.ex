defmodule ShadcnDaisyuiDemoWeb.Catalog.CommandMenuPage do
  @moduledoc """
  The catalog page for `<.command_menu>`: a searchable dropdown over a long
  grouped list (a company, its divisions and regions, brands and their
  locations). Like `ShadcnDaisyuiDemoWeb.Catalog.CodeBlockPage`, each
  example's `code` is rendered from the real component at runtime (through
  `DataPages.code/1`), so the preview is the markup the component renders
  today, working with `initShadcnDaisyui()`. Rows are plain links here (a
  dead page has no LiveView for `phx-click`); /lab/command-menu is the same
  menu in a LiveView, a few hundred rows long.
  """
  use Phoenix.Component

  import ShadcnDaisyui.Components.CommandMenu
  import ShadcnDaisyui.Components.Shell, only: [app_shell_heading: 1]

  alias ShadcnDaisyuiDemoWeb.Catalog.DataPages
  alias ShadcnDaisyuiDemoWeb.ScopeData

  @sources [
    __MODULE__,
    DataPages,
    ScopeData,
    ShadcnDaisyui.Components.CommandMenu,
    ShadcnDaisyui.Components.Shell
  ]

  @doc "The page, built once per code version (see `DataPages.all/0`)."
  def all do
    key = {__MODULE__, Enum.map(@sources, & &1.module_info(:md5))}

    case :persistent_term.get(key, nil) do
      nil ->
        pages = [command_menu()]
        :persistent_term.put(key, pages)
        pages

      pages ->
        pages
    end
  end

  defp command_menu do
    %{
      slug: "command-menu",
      title: "Command Menu",
      description:
        "A searchable dropdown for long grouped lists: a search box over grouped, nested rows, anchored to its trigger, a drawer on phones.",
      hook: true,
      guidance: %{
        use_when: [
          "Choosing one of many (dozens to a few hundred) places, scopes or records from a trigger: a brand and location switcher, a team picker",
          "The list has groups and levels (brands and their locations) and people find a row by typing part of its name",
          "Each row does something: goes somewhere, submits a form or runs an event"
        ],
        avoid_when: [
          "Setting a form field - use <.combobox> or <.select> (they post a value)",
          "A handful of actions - use <.dropdown_menu>",
          "Searching the whole app, or a list only the server can search - use <.command> (on_search)"
        ],
        sizing:
          "Panel w-72 (18rem) by default, at least the trigger's width; the list scrolls past 300px, and the panel never outgrows the room beside its trigger. Rows are 32px (44px in the drawer); each level of nesting steps in 1.5rem, so a child's icon sits under its parent's label.",
        responsive:
          "From 48rem a dropdown in the top layer: below its trigger (side=\"right\": beside it), flipped above or to the left when there's more room there, kept inside the window, following the trigger as the page scrolls. Below 48rem a bottom drawer, up to 85% of the screen, with a 16px search box that isn't focused on open, so the keyboard doesn't cover the list.",
        ios:
          "A sheet with .searchable and a List of Sections; DisclosureGroup or indented rows for children, a checkmark on the current row, .presentationDetents([.medium, .large])."
      },
      props: [
        %{name: "id", type: "string (required)", default: "-"},
        %{name: "label", type: "string (required, the accessible name)", default: "-"},
        %{name: "placeholder", type: "string", default: ~s("Search…")},
        %{
          name: "trigger_id",
          type: "string (an element elsewhere that opens it)",
          default: "nil (the :trigger slot)"
        },
        %{name: "trigger_class", type: "any", default: ~s("btn btn-outline w-64 …")},
        %{name: "side", type: "bottom | right", default: "bottom"},
        %{name: "align", type: "start | end", default: "start"},
        %{name: "class", type: "any (the panel's width)", default: ~s("w-72")},
        %{name: "phx-target", type: "any (rows' phx-click)", default: "nil"},
        %{name: ":trigger", type: "slot (inside the trigger button)", default: "-"},
        %{
          name: ":item",
          type:
            "slot: id group parent icon description keywords current, phx-click values | navigate | patch | href method | form name value, confirm disabled",
          default: "-"
        },
        %{name: ":empty", type: "slot", default: ~s("No results found.")}
      ],
      notes:
        "Needs the ShadcnCommandMenu hook (in Hooks; dead views: initShadcnDaisyui()). Build the rows in Elixir, each child right after its parent, and render them with one :for (a slot entry can't sit inside a for block). parent nests a row under another (up to four levels). Typing filters every level: a row shows when every word typed starts a word of its own text (label, description, keywords) or its parents', so a location's name shows it under its brand (muted, for context) and a brand's name shows it with all its locations; accents and case don't matter, the first match is active, and the count is announced. current marks the chosen row (a check, aria-selected) and is active when the menu opens. Choosing a row closes the menu (a row with confirm, once it's accepted). Esc closes and returns focus to the trigger; a press outside or Tab closes it. One command menu is open at a time.",
      specs: %{
        anatomy: [
          %{part: "Trigger", description: "The menu's own button (:trigger), or trigger_id."},
          %{
            part: "Panel",
            description:
              "Popover surface in the top layer (popover=manual): search row, list, empty text."
          },
          %{part: "Search", description: "A combobox input, 36px row with a search icon."},
          %{
            part: "List",
            description: "A listbox of groups (heading + options); scrolls past 300px."
          },
          %{
            part: "Row",
            description:
              "Icon, label, optional description, a check on the current row; indented by level."
          }
        ],
        measurements: [
          %{
            property: "Panel",
            value: "w-72, ≥ trigger width, var(--radius-md), popover ring + shadow-md, 4px gap"
          },
          %{property: "Search row", value: "36px (44px in the drawer), 1px bottom border"},
          %{property: "Row", value: "32px, 14px text, 8px gaps; drawer 44px"},
          %{property: "Nesting", value: "1.5rem per level (up to 4)"},
          %{
            property: "Motion",
            value:
              "dropdown fades and zooms from 95% in 150ms; drawer slides up in 300ms; none with reduced motion"
          }
        ]
      },
      accessibility: %{
        roles:
          "The trigger has aria-haspopup=\"dialog\", aria-expanded and aria-controls (the panel). The panel is role=\"dialog\" named by label; its search box is role=\"combobox\" (aria-controls the list, aria-activedescendant the active row) over a role=\"listbox\" of role=\"group\"s, each labelled by its heading. Rows are role=\"option\", the current one aria-selected=\"true\"; disabled rows aria-disabled.",
        keyboard: [
          %{
            keys: "Enter / Space / ↓ / ↑",
            action: "On the trigger: open (↑ starts at the last row)"
          },
          %{keys: "↓ / ↑", action: "Move through the rows (wraps, skips disabled ones)"},
          %{keys: "Page Down / Page Up", action: "Move ten rows"},
          %{keys: "Enter", action: "Choose the active row"},
          %{keys: "Esc", action: "Close, focus back on the trigger"},
          %{keys: "Tab", action: "Close and move on"}
        ],
        focus:
          "Opening focuses the search box (the drawer focuses itself instead; typing goes to the search). Focus stays in the search box while the arrow keys move the active row, which scrolls into view. Closing with Esc or a choice returns focus to the trigger.",
        screen_reader:
          "The active row is read through aria-activedescendant; after typing, the number of results (or the empty text) is announced in a polite status region. Nested rows are indented visually only: put what a row belongs to in its description when it matters.",
        touch_target: "Drawer rows are 44px, its search box 44px with 16px text.",
        reduced_motion: "No fade, zoom or slide: the menu and the drawer appear at once."
      },
      examples: [
        %{
          title: "Switch location",
          about: [
            "The company, divisions with their regions, and brands with their locations. Type a city: the location shows under its brand."
          ],
          heex: ~S"""
          <.command_menu id="scope" label="Switch location" placeholder="Search brands and locations">
            <:trigger>
              <span class="truncate">{@scope.label}</span>
              <span class="hero-chevron-up-down size-4 opacity-50" aria-hidden="true"></span>
            </:trigger>
            <:item
              :for={row <- @rows}
              id={row.id}
              group={row.group}
              parent={row[:parent]}
              icon={row.icon}
              description={row[:description]}
              current={row.id == @scope.id}
              patch={~p"/?scope=#{row.id}"}
            >
              {row.label}
            </:item>
            <:empty>No brand or location matches.</:empty>
          </.command_menu>
          """,
          code: switcher_code()
        },
        %{
          title: "From the sidebar header",
          about: [
            "trigger_id points the menu at the app shell's heading, rendered as a button; side=\"right\" opens it beside the sidebar, as shadcn's team switcher does."
          ],
          heex: ~S"""
          <:header>
            <.app_shell_heading id="scope-trigger" as="button" icon="hero-building-office-2"
              title={@scope.label} subtitle="Location" tip={@scope.label} chevron />
          </:header>
          …
          <.command_menu id="scope" trigger_id="scope-trigger" side="right" label="Switch location">
            <:item :for={row <- @rows} id={row.id} group={row.group} parent={row[:parent]}
              icon={row.icon} current={row.id == @scope.id} patch={~p"/?scope=#{row.id}"}>
              {row.label}
            </:item>
          </.command_menu>
          """,
          center: false,
          code: sidebar_code()
        }
      ]
    }
  end

  defp switcher_code do
    assigns = %{rows: ScopeData.rows(6, 3), current: "loc-2-1"}

    DataPages.code(~H"""
    <.command_menu id="scope" label="Switch location" placeholder="Search brands and locations">
      <:trigger>
        <span class="truncate">{ScopeData.find(@rows, @current).label}</span>
        <span class="hero-chevron-up-down size-4 opacity-50" aria-hidden="true"></span>
      </:trigger>
      <:item
        :for={row <- @rows}
        id={row.id}
        group={row.group}
        parent={row[:parent]}
        icon={row.icon}
        description={row[:description]}
        current={row.id == @current}
        href={"#scope=" <> row.id}
      >
        {row.label}
      </:item>
      <:empty>No brand or location matches.</:empty>
    </.command_menu>
    """)
  end

  defp sidebar_code do
    assigns = %{rows: ScopeData.rows(6, 3), current: "acme"}

    DataPages.code(~H"""
    <div class="w-64 rounded-lg border border-border bg-base-200 p-2">
      <.app_shell_heading
        id="scope-heading"
        as="button"
        icon="hero-building-office-2"
        title="All of Acme"
        subtitle="Location"
        chevron
      />
    </div>
    <.command_menu
      id="scope-side"
      trigger_id="scope-heading"
      side="right"
      label="Switch location"
      placeholder="Search brands and locations"
    >
      <:item
        :for={row <- @rows}
        id={"side-" <> row.id}
        group={row.group}
        parent={row[:parent] && "side-" <> row.parent}
        icon={row.icon}
        current={row.id == @current}
        href={"#scope=" <> row.id}
      >
        {row.label}
      </:item>
    </.command_menu>
    """)
  end
end
