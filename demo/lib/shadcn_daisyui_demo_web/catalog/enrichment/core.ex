defmodule ShadcnDaisyuiDemoWeb.Catalog.Enrichment.Core do
  @moduledoc "Specs / Accessibility / Native enrichment for the Core component group."

  @doc "Map of slug => enrichment fields. Button, Input, and Dialog are enriched inline in Catalog."
  def specs do
    %{
      "badge" => %{
        specs: %{
          anatomy: [
            %{
              part: "Container",
              description: "Inline span carrying the variant background and 1px border."
            },
            %{
              part: "Label",
              description: "Short text (and optional icon) describing the status or count."
            }
          ],
          measurements: [
            %{property: "Height", value: "auto (content + padding)"},
            %{property: "Padding", value: "0.125rem block, 0.5rem inline (py-0.5 px-2)"},
            %{property: "Radius", value: "9999px (rounded-full)"},
            %{
              property: "Border",
              value: "1px transparent (outline variant uses var(--border-color))"
            },
            %{property: "Font", value: "0.75rem / 500 (text-xs font-medium)"}
          ],
          tokens: ["primary", "primary-foreground", "secondary", "destructive", "border-color"]
        },
        accessibility: %{
          roles:
            "Plain inline span with no implicit role. Color is decorative; the text must carry the meaning, since the variant hue alone is not announced.",
          focus: "Not focusable - a badge is a static label, not an interactive target.",
          screen_reader:
            "Read inline as part of the surrounding text. If a badge conveys status (e.g. a count), give nearby context so it is not a bare number.",
          touch_target:
            "Decorative; no hit area requirement. If made tappable, wrap it in a button or link sized to 44pt.",
          reduced_motion: "No motion."
        },
        swiftui: %{
          code: ~S"""
          Text("Badge")
              .font(.caption.weight(.medium))
              .padding(.horizontal, 8)
              .padding(.vertical, 2)
              .background(Color.accentColor, in: Capsule())
              .foregroundStyle(.white)
          """,
          notes:
            "No first-class Badge view; compose a capsule-clipped Text. .badge(_:) on tab items is a different, count-only construct."
        },
        ios_status: :parity
      },
      "card" => %{
        specs: %{
          anatomy: [
            %{
              part: "Container",
              description: "Bordered surface with rounded corners and a subtle shadow."
            },
            %{
              part: "Body",
              description:
                "Padded content region (card-body) holding title, description, and actions."
            },
            %{
              part: "Title / Description",
              description: "Semibold heading plus muted supporting text."
            }
          ],
          measurements: [
            %{property: "Radius", value: "var(--radius-xl)"},
            %{property: "Border", value: "1px var(--border-color)"},
            %{property: "Shadow", value: "var(--shadow-sm)"},
            %{property: "Body padding", value: "1.5rem (p-6)"},
            %{property: "Body gap", value: "0.375rem"}
          ],
          tokens: ["card", "card-foreground", "border-color", "muted-foreground"],
          anatomy_svg: ~S"""
          <svg viewBox="0 0 440 184" xmlns="http://www.w3.org/2000/svg" class="w-full max-w-md" role="img" aria-label="Card anatomy diagram">
            <rect x="130" y="30" width="200" height="124" rx="12" fill="var(--card)" stroke="var(--border-color)" stroke-width="1.5" />
            <rect x="146" y="46" width="168" height="92" rx="4" fill="none" stroke="var(--muted-foreground)" stroke-width="1" stroke-dasharray="4 4" opacity="0.6" />
            <text x="160" y="80" fill="var(--card-foreground)" font-family="ui-sans-serif, system-ui" font-size="14" font-weight="600">Card title</text>
            <text x="160" y="100" fill="var(--muted-foreground)" font-family="ui-sans-serif, system-ui" font-size="12">Supporting description text.</text>
            <g stroke="var(--border-color)" stroke-width="1">
              <line x1="330" y1="44" x2="366" y2="34" />
              <line x1="314" y1="120" x2="366" y2="130" />
              <line x1="158" y1="76" x2="118" y2="62" />
            </g>
            <g font-family="ui-sans-serif, system-ui" font-size="12" font-weight="600">
              <circle cx="374" cy="30" r="11" fill="var(--foreground)" /><text x="374" y="34" text-anchor="middle" fill="var(--background)">1</text>
              <circle cx="374" cy="134" r="11" fill="var(--foreground)" /><text x="374" y="138" text-anchor="middle" fill="var(--background)">2</text>
              <circle cx="110" cy="58" r="11" fill="var(--foreground)" /><text x="110" y="62" text-anchor="middle" fill="var(--background)">3</text>
            </g>
          </svg>
          """
        },
        accessibility: %{
          roles:
            "Generic grouping container (div). It carries no implicit landmark; if the card is a single clickable target, make the whole card a link/button and label it.",
          focus:
            "Not focusable by itself. Interactive children (buttons, links) keep their own focus order.",
          screen_reader:
            "Use a real heading element for the title so the card participates in the heading outline.",
          touch_target:
            "Container has no hit requirement; nested actions follow the 44pt minimum.",
          reduced_motion: "Static surface; no animation."
        },
        swiftui: %{
          code: ~S"""
          VStack(alignment: .leading, spacing: 6) {
              Text("Title").font(.headline)
              Text("Description").foregroundStyle(.secondary)
          }
          .padding(24)
          .background(.background, in: RoundedRectangle(cornerRadius: 12))
          .overlay(RoundedRectangle(cornerRadius: 12).stroke(.separator))
          """,
          notes:
            "Closest native idiom is GroupBox or a styled container; a bordered RoundedRectangle background matches the shadcn metrics best."
        },
        ios_status: :parity
      },
      "textarea" => %{
        specs: %{
          anatomy: [
            %{part: "Label", description: "Optional field label tied to the control via for/id."},
            %{part: "Control", description: "Multi-line textarea with bordered surface."},
            %{
              part: "Error",
              description: "Validation message rendered below when the field is invalid."
            }
          ],
          measurements: [
            %{property: "Padding", value: "0.5rem block, 0.75rem inline (py-2 px-3)"},
            %{property: "Radius", value: "var(--radius-md)"},
            %{property: "Border", value: "1px var(--input)"},
            %{property: "Shadow", value: "var(--shadow-xs)"},
            %{property: "Font", value: "0.875rem (text-sm)"}
          ],
          tokens: ["input", "foreground", "muted-foreground", "ring", "destructive"]
        },
        accessibility: %{
          roles:
            "Native textarea (implicit role textbox, multiline). Bound to a FormField so id/name/value/errors are wired automatically.",
          keyboard: [
            %{keys: "Tab", action: "Move focus to / from the textarea"},
            %{keys: "Enter", action: "Insert a newline within the textarea"},
            %{keys: "Arrows / Home / End", action: "Move the caret through the text"}
          ],
          focus:
            "Border switches to var(--ring) with a ring shadow on focus; the focus ring is always visible (not hover-gated).",
          screen_reader:
            "Associated label is announced; placeholder is supplementary, never a label substitute. Errors surface via the rendered error text.",
          touch_target: "Resizable text region; comfortably exceeds the 44pt minimum.",
          reduced_motion: "Focus transition is instant under the theme; no animation to suppress."
        },
        swiftui: %{
          code: ~S"""
          TextEditor(text: $bio)
              .frame(minHeight: 80)
              .padding(8)
              .overlay(RoundedRectangle(cornerRadius: 6).stroke(.separator))
          """,
          notes:
            "TextEditor is the multiline equivalent; TextField(_, axis: .vertical) also grows vertically and is often a cleaner fit."
        },
        ios_status: :parity
      },
      "select" => %{
        specs: %{
          anatomy: [
            %{
              part: "Trigger",
              description: "Outline button showing the current value and a chevron-down icon."
            },
            %{
              part: "Panel",
              description: "Popover listbox of option buttons positioned below the trigger."
            },
            %{
              part: "Option",
              description: "Each row (combo-item) with a check icon revealed on selection."
            }
          ],
          measurements: [
            %{property: "Trigger height", value: "2.25rem / 36px (btn h-9)"},
            %{property: "Trigger radius", value: "var(--radius-md)"},
            %{property: "Panel radius", value: "var(--radius-md)"},
            %{property: "Panel border", value: "1px var(--border-color)"},
            %{property: "Option padding", value: "0.375rem block, 0.5rem inline"},
            %{property: "Option radius", value: "var(--radius-sm)"}
          ],
          tokens: [
            "popover",
            "popover-foreground",
            "border-color",
            "accent",
            "accent-foreground",
            "muted-foreground"
          ]
        },
        accessibility: %{
          roles:
            "Custom trigger button plus a popover list of option buttons, driven by the ShadcnSelect hook. Requires a unique id. Provide an accessible name on the trigger (the placeholder/label reads as the current value).",
          keyboard: [
            %{keys: "Enter / Space", action: "Open the listbox from the trigger"},
            %{keys: "Up / Down", action: "Move the active option"},
            %{keys: "Enter", action: "Select the active option and close"},
            %{keys: "Esc", action: "Close the listbox without changing the value"}
          ],
          focus:
            "Trigger shows the ring on focus; the active option is highlighted with the accent background.",
          screen_reader:
            "For a fully announced native experience prefer native-select; this custom control trades native semantics for shadcn visuals.",
          touch_target:
            "Trigger is 36px tall (desktop-fine); options are tappable rows. Pad to 44pt on touch-primary surfaces.",
          reduced_motion: "Panel toggles visibility without a color fade under the theme."
        },
        swiftui: %{
          code: ~S"""
          Picker("Fruit", selection: $fruit) {
              ForEach(fruits, id: \.self) { Text($0).tag($0) }
          }
          .pickerStyle(.menu)
          """,
          notes:
            "A .menu Picker gives the same trigger-then-list behavior natively, with system-managed selection semantics."
        },
        ios_status: :parity
      },
      "native-select" => %{
        specs: %{
          anatomy: [
            %{part: "Label", description: "Optional label tied to the select via for/id."},
            %{part: "Control", description: "Native HTML select styled with the .select class."},
            %{part: "Options", description: "Native option elements, optionally led by a prompt."}
          ],
          measurements: [
            %{property: "Height", value: "2.25rem / 36px (h-9)"},
            %{property: "Padding", value: "0.75rem inline"},
            %{property: "Radius", value: "var(--radius-md)"},
            %{property: "Border", value: "1px var(--input)"},
            %{property: "Shadow", value: "var(--shadow-xs)"}
          ],
          tokens: ["input", "foreground", "ring", "muted-foreground", "destructive"]
        },
        accessibility: %{
          roles:
            "Native select (implicit role combobox / listbox), fully accessible by default. Bound to a FormField for id/name/value/errors.",
          keyboard: [
            %{keys: "Enter / Space", action: "Open the option list"},
            %{keys: "Up / Down", action: "Move between options"},
            %{
              keys: "Type-ahead",
              action: "Jump to the option starting with the typed characters"
            },
            %{keys: "Esc", action: "Close the list"}
          ],
          focus: "Border switches to var(--ring) with a ring shadow on focus.",
          screen_reader:
            "Native semantics are announced automatically (role, expanded state, selected option). Pair with a visible label.",
          touch_target: "OS-native picker on touch devices guarantees an adequate hit area.",
          reduced_motion: "Native control; no theme animation."
        },
        swiftui: %{
          code: ~S"""
          Picker("Role", selection: $role) {
              ForEach(roles, id: \.self) { Text($0).tag($0) }
          }
          """,
          notes:
            "Maps directly to Picker, which renders as the platform-native control (wheel, menu, or list depending on context)."
        },
        ios_status: :parity
      },
      "checkbox" => %{
        specs: %{
          anatomy: [
            %{
              part: "Box",
              description:
                "Square control that fills with primary and shows a checkmark when checked."
            },
            %{part: "Label", description: "Adjacent tappable label text wrapping the input."}
          ],
          measurements: [
            %{property: "Size", value: "1rem x 1rem (size-4)"},
            %{property: "Radius", value: "var(--radius-sm)"},
            %{property: "Border", value: "1px var(--input)"},
            %{property: "Checked fill", value: "var(--primary)"},
            %{property: "Padding", value: "2px (so the check reads at size-4)"}
          ],
          tokens: ["input", "primary", "primary-foreground", "ring"]
        },
        accessibility: %{
          roles:
            "Native checkbox input (implicit role checkbox). The form variant renders a hidden false input so an unchecked box still submits.",
          keyboard: [
            %{keys: "Tab", action: "Move focus to / from the checkbox"},
            %{keys: "Space", action: "Toggle checked / unchecked"}
          ],
          focus: "Shows a ring shadow on focus-visible.",
          screen_reader:
            "Checked state is announced. Wrapping the input in a label row gives it an accessible name.",
          touch_target:
            "Visual box is 16px; wrap it in the full label row so the effective hit area reaches 44pt on touch.",
          reduced_motion: "Checkmark appears instantly under the theme."
        },
        swiftui: %{
          code: ~S"""
          Toggle("Active", isOn: $active)
              .toggleStyle(.checkbox)
          """,
          notes:
            ".checkbox toggle style exists on macOS; on iOS a Toggle renders as a switch, so a checkbox there is custom."
        },
        ios_status: :parity
      },
      "radio-group" => %{
        specs: %{
          anatomy: [
            %{
              part: "Group",
              description: "Fieldset grouping the radios with an optional legend label."
            },
            %{
              part: "Radio",
              description: "Circular control selected one-at-a-time, sharing a name."
            },
            %{part: "Label", description: "Tappable text label per option."}
          ],
          measurements: [
            %{property: "Size", value: "1rem x 1rem (radio radio-sm)"},
            %{property: "Border", value: "1px var(--input)"},
            %{property: "Checked", value: "border + dot use var(--primary)"},
            %{property: "Row gap", value: "0.5rem (gap-2)"}
          ],
          tokens: ["input", "primary", "ring", "foreground"]
        },
        accessibility: %{
          roles:
            "fieldset + legend grouping native radio inputs that share a name (implicit radiogroup / radio roles). The legend names the group.",
          keyboard: [
            %{keys: "Tab", action: "Move focus into / out of the group (to the checked radio)"},
            %{keys: "Arrow keys", action: "Move selection between radios in the group"},
            %{keys: "Space", action: "Select the focused radio"}
          ],
          focus: "Focused radio shows a ring shadow; arrow keys move both focus and selection.",
          screen_reader:
            "Legend is announced as the group name; each radio announces its label and position in the set.",
          touch_target: "Each option is a full label row, giving a 44pt-friendly hit area.",
          reduced_motion: "Selection dot appears instantly under the theme."
        },
        swiftui: %{
          code: ~S"""
          Picker("Plan", selection: $plan) {
              Text("Free").tag("free")
              Text("Pro").tag("pro")
          }
          .pickerStyle(.inline)
          """,
          notes:
            "An inline Picker is the idiomatic single-select group; on macOS .radioGroup style maps even more directly."
        },
        ios_status: :parity
      },
      "switch" => %{
        specs: %{
          anatomy: [
            %{
              part: "Track",
              description: "Pill background that turns primary when on (daisyUI toggle)."
            },
            %{part: "Knob", description: "Sliding circular thumb drawn in the background color."},
            %{part: "Label", description: "Tappable label row wrapping the input."}
          ],
          measurements: [
            %{property: "Height", value: "1.15rem (--size; width derives)"},
            %{property: "Radius", value: "9999px (pill)"},
            %{property: "Off track", value: "var(--input)"},
            %{property: "On track", value: "var(--primary)"},
            %{property: "Knob", value: "var(--background)"}
          ],
          tokens: ["input", "primary", "primary-foreground", "background", "ring"]
        },
        accessibility: %{
          roles:
            "Native checkbox input styled as a switch (the .toggle class). Bound to a boolean FormField with a hidden false input.",
          keyboard: [
            %{keys: "Tab", action: "Move focus to / from the switch"},
            %{keys: "Space", action: "Toggle on / off"}
          ],
          focus: "Ring shadow on focus-visible.",
          screen_reader:
            "On/off state is announced via the checkbox semantics; the wrapping label supplies the name. For a literal switch role add role=switch.",
          touch_target: "Wrap in the label row for a 44pt-friendly hit area on touch.",
          reduced_motion: "Theme forces an instant switch; the knob does not animate its slide."
        },
        swiftui: %{
          code: ~S"""
          Toggle("Email notifications", isOn: $notifications)
          """,
          notes: "Toggle is the exact native equivalent and renders as a sliding switch on iOS."
        },
        ios_status: :parity
      },
      "label" => %{
        specs: %{
          anatomy: [
            %{
              part: "Label",
              description: "Text element associated with a control via the for attribute."
            }
          ],
          measurements: [
            %{property: "Font", value: "0.875rem / 500 (text-sm font-medium)"},
            %{property: "Color", value: "inherits foreground"}
          ],
          tokens: ["foreground", "muted-foreground"]
        },
        accessibility: %{
          roles:
            "Native label element. Its for attribute ties it to a control id so the label is announced as that control name; clicking the label focuses/toggles the control.",
          focus: "Not focusable itself; it forwards activation to its associated control.",
          screen_reader:
            "Provides the accessible name for the linked input. Keep label text concise and descriptive.",
          touch_target:
            "When wrapping a control, sizes the combined tappable row toward the 44pt minimum.",
          reduced_motion: "No motion."
        },
        swiftui: %{
          code: ~S"""
          Text("Email")
              .font(.subheadline.weight(.medium))
          """,
          notes:
            "SwiftUI controls take their label inline (TextField(_:), Toggle(_:)), so a standalone Label maps to a styled Text or an accessibility label."
        },
        ios_status: :parity
      },
      "alert" => %{
        specs: %{
          anatomy: [
            %{
              part: "Container",
              description: "Bordered card-surface region carrying role=alert."
            },
            %{part: "Title", description: "Optional medium-weight heading line."},
            %{
              part: "Description",
              description: "Muted body text; tinted destructive in the error variant."
            }
          ],
          measurements: [
            %{property: "Padding", value: "0.75rem block, 1rem inline (py-3 px-4)"},
            %{property: "Radius", value: "var(--radius-lg)"},
            %{property: "Border", value: "1px var(--border-color); error blends 30% destructive"},
            %{property: "Font", value: "0.875rem (text-sm)"},
            %{property: "Shadow", value: "none (flat)"}
          ],
          tokens: ["card", "card-foreground", "border-color", "destructive", "muted-foreground"]
        },
        accessibility: %{
          roles:
            "Renders role=alert, so assistive tech announces the content as an assertive live region the moment it appears.",
          focus:
            "Not focusable; it is an announcement, not a control. Any action buttons inside keep their own focus.",
          screen_reader:
            "Inserted alert text is read immediately. Reserve role=alert for genuinely important, time-sensitive messages.",
          touch_target:
            "Container has no hit requirement; nested actions follow the 44pt minimum.",
          reduced_motion: "Static surface; no entrance animation."
        },
        swiftui: %{
          code: ~S"""
          VStack(alignment: .leading, spacing: 4) {
              Text("Error").font(.subheadline.weight(.medium))
              Text("Your session has expired.").foregroundStyle(.secondary)
          }
          .padding(.horizontal, 16).padding(.vertical, 12)
          .background(.background, in: RoundedRectangle(cornerRadius: 8))
          .overlay(RoundedRectangle(cornerRadius: 8).stroke(.separator))
          """,
          notes:
            "This is an inline banner, not an interrupting .alert() modal. SwiftUI has no inline alert primitive, so compose a bordered VStack."
        },
        ios_status: :guidance_only
      },
      "tabs" => %{
        specs: %{
          anatomy: [
            %{
              part: "Tablist",
              description: "Segmented box (tabs-box) on a muted background holding the triggers."
            },
            %{
              part: "Tab trigger",
              description: "Radio-driven label; the active one gets a white box and shadow."
            },
            %{part: "Panel", description: "tab-content region shown for the selected tab."}
          ],
          measurements: [
            %{property: "List padding", value: "3px (p-[3px])"},
            %{property: "List radius", value: "var(--radius-lg)"},
            %{property: "Trigger height", value: "1.75rem (28px)"},
            %{property: "Trigger radius", value: "var(--radius-md)"},
            %{property: "Trigger font", value: "0.875rem / 500"}
          ],
          tokens: ["muted", "muted-foreground", "background", "foreground"]
        },
        accessibility: %{
          roles:
            "Outer element carries role=tablist; triggers are radio inputs labeled via aria-label. The active trigger reflects aria-selected / checked.",
          keyboard: [
            %{keys: "Tab", action: "Move focus to the tablist"},
            %{keys: "Arrow keys", action: "Move between tabs (native radio-group behavior)"},
            %{keys: "Space", action: "Activate the focused tab"}
          ],
          focus:
            "Focused tab shows a ring; the selected tab is the white box with a subtle shadow.",
          screen_reader:
            "Each trigger is named by its aria-label; the radio grouping conveys selection and set size.",
          touch_target:
            "Triggers are 28px tall - fine for pointer; enlarge for touch-primary layouts.",
          reduced_motion: "Active-tab swap is instant; no slide animation."
        },
        swiftui: %{
          code: ~S"""
          TabView {
              Text("Account").tabItem { Label("Account", systemImage: "person") }
              Text("Password").tabItem { Label("Password", systemImage: "lock") }
          }
          """,
          notes:
            "TabView covers the same intent but presents as a bottom tab bar (or sidebar) rather than an inline segmented control; .pickerStyle(.segmented) is closer visually."
        },
        ios_status: :partial
      },
      "table" => %{
        specs: %{
          anatomy: [
            %{part: "Table", description: "Native table element at text-sm."},
            %{part: "Header", description: "th cells in muted-foreground with medium weight."},
            %{
              part: "Row",
              description: "tbody rows with hairline borders; hover tints with muted."
            }
          ],
          measurements: [
            %{property: "Font", value: "0.875rem (text-sm)"},
            %{property: "Header color", value: "var(--muted-foreground), weight 500"},
            %{property: "Cell border", value: "var(--border-color)"},
            %{property: "Row hover", value: "var(--muted) background"}
          ],
          tokens: ["muted-foreground", "border-color", "muted", "foreground"]
        },
        accessibility: %{
          roles:
            "Native table / thead / tbody / th / td with their implicit table roles. Header cells should scope columns; the demo uses semantic th elements.",
          keyboard: [
            %{keys: "Tab", action: "Move through any interactive cell content (links, buttons)"}
          ],
          focus:
            "The table itself is not focusable; interactive cell content keeps its own focus order and rings.",
          screen_reader:
            "Table semantics let users navigate by row and column. Provide a caption or surrounding heading for context.",
          touch_target:
            "Interactive cell content (action buttons/links) should meet the 44pt minimum on touch.",
          reduced_motion: "Row hover tint is instant under the theme."
        },
        swiftui: %{
          code: ~S"""
          Table(people) {
              TableColumn("Name", value: \.name)
              TableColumn("Email", value: \.email)
          }
          """,
          notes:
            "Table is full-featured on macOS/iPadOS; on iPhone a List of rows is the practical equivalent, so behavior differs by size class."
        },
        ios_status: :partial
      },
      "separator" => %{
        specs: %{
          anatomy: [
            %{
              part: "Rule",
              description:
                "A thin divider line, horizontal or vertical (divider / divider-horizontal)."
            }
          ],
          measurements: [
            %{property: "Thickness", value: "1px hairline"},
            %{property: "Color", value: "var(--border-color) via the divider"},
            %{property: "Orientation", value: "horizontal (default) or vertical"}
          ],
          tokens: ["border-color", "muted-foreground"]
        },
        accessibility: %{
          roles:
            "Purely decorative divider. If it semantically separates content, expose role=separator; otherwise keep it aria-hidden so it adds no noise.",
          focus: "Not focusable (a static separator, unlike the interactive resizable handle).",
          screen_reader:
            "A plain divider is ignored. Use a real heading/landmark when the separation carries meaning.",
          touch_target: "No hit area.",
          reduced_motion: "No motion."
        },
        swiftui: %{
          code: ~S"""
          Divider()
          """,
          notes:
            "Divider is the direct equivalent; it adapts to orientation based on its container (HStack vs VStack)."
        },
        ios_status: :parity
      },
      "accordion" => %{
        specs: %{
          anatomy: [
            %{
              part: "Section",
              description: "Each collapsible row (collapse collapse-arrow) inside a card."
            },
            %{
              part: "Trigger",
              description: "collapse-title row with a rotating chevron affordance."
            },
            %{
              part: "Content",
              description: "collapse-content panel revealed when open, in muted text."
            }
          ],
          measurements: [
            %{
              property: "Trigger padding",
              value: "1rem block, 2.5rem inline-end (room for the arrow)"
            },
            %{property: "Trigger font", value: "0.875rem / 500"},
            %{property: "Divider", value: "1px var(--border-color) between sections"},
            %{property: "Content font", value: "0.875rem, var(--muted-foreground)"}
          ],
          tokens: ["card", "border-color", "muted-foreground", "foreground"]
        },
        accessibility: %{
          roles:
            "Built on radio (single-open) or checkbox (multiple) inputs that drive native CSS collapse. Requires an id to group the radios. Toggling is keyboard-operable through the underlying input.",
          keyboard: [
            %{keys: "Tab", action: "Move focus to a section trigger"},
            %{keys: "Space / Enter", action: "Expand or collapse the focused section"},
            %{keys: "Arrow keys", action: "Move between sections in single-open (radio) mode"}
          ],
          focus:
            "The underlying input takes focus; the open section shows its content immediately.",
          screen_reader:
            "Conveyed via the radio/checkbox state. For a full disclosure pattern add aria-expanded / aria-controls on a button-based trigger.",
          touch_target:
            "Trigger rows are tall (1rem padding top and bottom) and easily exceed 44pt.",
          reduced_motion:
            "The collapse open/close uses daisyUI height animation; honor prefers-reduced-motion to disable it."
        },
        swiftui: %{
          code: ~S"""
          DisclosureGroup("Is it accessible?") {
              Text("Yes. It adheres to the WAI-ARIA pattern.")
          }
          """,
          notes:
            "DisclosureGroup is the native disclosure equivalent; stack several (or use a List with multiple groups) for accordion behavior."
        },
        ios_status: :parity
      },
      "avatar" => %{
        specs: %{
          anatomy: [
            %{
              part: "Frame",
              description: "Sized, shaped wrapper (rounded-full by default) clipping the image."
            },
            %{
              part: "Image / Fallback",
              description: "Photo when present, otherwise initials on a muted placeholder."
            }
          ],
          measurements: [
            %{property: "Default size", value: "w-10 (2.5rem); set via class"},
            %{property: "Shape", value: "rounded-full (default) or any radius class"},
            %{property: "Fallback bg", value: "var(--muted)"},
            %{property: "Fallback text", value: "var(--muted-foreground), text-sm / 500"},
            %{property: "Group overlap", value: "-space-x-3 with a background-colored ring"}
          ],
          tokens: ["muted", "muted-foreground", "background", "border-color"]
        },
        accessibility: %{
          roles:
            "An image (with alt text) or a decorative initials span. The image alt should name the person; a bare fallback like JD needs surrounding context to be meaningful.",
          focus: "Not focusable unless wrapped in a link/button.",
          screen_reader:
            "Provide a meaningful alt for the image; mark the initials fallback as decorative if the name is already announced nearby.",
          touch_target: "Decorative by default; if interactive, size the wrapper to 44pt.",
          reduced_motion: "Static; no animation."
        },
        swiftui: %{
          code: ~S"""
          AsyncImage(url: user.photoURL) { image in
              image.resizable().scaledToFill()
          } placeholder: {
              Text(user.initials)
          }
          .frame(width: 40, height: 40)
          .clipShape(Circle())
          """,
          notes:
            "Compose AsyncImage with a clip shape; supply the person's name as the accessibility label."
        },
        ios_status: :parity
      },
      "breadcrumb" => %{
        specs: %{
          anatomy: [
            %{part: "Nav", description: "nav landmark labeled Breadcrumb wrapping the trail."},
            %{
              part: "Crumb",
              description: "Linked ancestor pages, muted with a hover to foreground."
            },
            %{
              part: "Current page",
              description: "Final non-link item carrying aria-current=page."
            }
          ],
          measurements: [
            %{property: "Font", value: "0.875rem (text-sm)"},
            %{property: "Crumb color", value: "var(--muted-foreground)"},
            %{property: "Current color", value: "var(--foreground)"},
            %{property: "Separator", value: "daisyUI breadcrumbs slash between items"}
          ],
          tokens: ["muted-foreground", "foreground"]
        },
        accessibility: %{
          roles:
            "nav element with aria-label=Breadcrumb. Ancestor crumbs are links; the current page is a span with aria-current=page (not a link).",
          keyboard: [
            %{keys: "Tab", action: "Move between the breadcrumb links"},
            %{keys: "Enter", action: "Follow the focused crumb link"}
          ],
          focus:
            "Links show their standard focus indicator; the current page item is non-interactive.",
          screen_reader:
            "The nav label announces the region; aria-current=page identifies the user's location in the hierarchy.",
          touch_target:
            "Crumb links are small text; ensure adequate spacing on touch and only show breadcrumbs at medium width and up.",
          reduced_motion: "No motion."
        },
        swiftui: %{
          code: ~S"""
          HStack(spacing: 4) {
              Button("Home") { }.buttonStyle(.plain)
              Text("/").foregroundStyle(.secondary)
              Text("Breadcrumb").accessibilityAddTraits(.isSelected)
          }
          .accessibilityElement(children: .contain)
          .accessibilityLabel("Breadcrumb")
          """,
          notes:
            "No native breadcrumb control; on iOS the navigation stack back button usually serves this role. Compose an HStack when an explicit trail is needed."
        },
        ios_status: :guidance_only
      },
      "dropdown-menu" => %{
        specs: %{
          anatomy: [
            %{
              part: "Trigger",
              description:
                "Button (with chevron) that opens the menu on click via tabindex/focus."
            },
            %{
              part: "Menu",
              description:
                "Popover ul (dropdown-content menu) of items, optional menu-title label."
            },
            %{
              part: "Item",
              description: "Action or link row that tints with accent on hover/focus."
            }
          ],
          measurements: [
            %{property: "Default width", value: "w-48"},
            %{property: "Panel radius", value: "var(--radius-md)"},
            %{property: "Panel padding", value: "0.25rem"},
            %{property: "Item radius", value: "var(--radius-sm)"},
            %{property: "Item hover", value: "var(--accent) / var(--accent-foreground)"}
          ],
          tokens: [
            "popover",
            "popover-foreground",
            "border-color",
            "accent",
            "accent-foreground",
            "muted-foreground"
          ]
        },
        accessibility: %{
          roles:
            "CSS-only daisyUI dropdown: a role=button trigger plus a focusable list. For full menu semantics layer role=menu / menuitem; the label slot is a non-interactive menu-title.",
          keyboard: [
            %{keys: "Tab / Enter / Space", action: "Open the menu and move focus into it"},
            %{keys: "Arrow keys", action: "Move between menu items"},
            %{keys: "Esc", action: "Close the menu and return focus to the trigger"}
          ],
          focus:
            "Trigger and items show focus styling; the open menu closes when focus leaves it (CSS :focus-within mechanism).",
          screen_reader:
            "Trigger needs an accessible name; add aria-haspopup / aria-expanded for a complete menu-button pattern.",
          touch_target:
            "Item rows are comfortably tappable; ensure 44pt on touch-primary surfaces.",
          reduced_motion: "Menu shows/hides without a color fade under the theme."
        },
        swiftui: %{
          code: ~S"""
          Menu("Open menu") {
              Section("My Account") {
                  Button("Profile") { }
                  Button("Log out", role: .destructive) { }
              }
          }
          """,
          notes:
            "Menu is a close native equivalent with system-managed dismissal and keyboard support; visual chrome differs from the web menu."
        },
        ios_status: :partial
      },
      "tooltip" => %{
        specs: %{
          anatomy: [
            %{
              part: "Wrapper",
              description:
                "Element carrying the tooltip class and data-tip text around the trigger."
            },
            %{
              part: "Bubble",
              description: "CSS ::before bubble in primary, positioned top/bottom/left/right."
            }
          ],
          measurements: [
            %{property: "Bubble bg", value: "var(--primary)"},
            %{property: "Bubble text", value: "var(--primary-foreground), 0.75rem"},
            %{property: "Bubble radius", value: "var(--radius-md)"},
            %{property: "Position", value: "top (default) / bottom / left / right"}
          ],
          tokens: ["primary", "primary-foreground"]
        },
        accessibility: %{
          roles:
            "CSS tooltip driven by data-tip; appears on hover and focus of the wrapped trigger. The trigger should still carry its own accessible name (the tip is supplementary, not a label substitute).",
          keyboard: [
            %{keys: "Tab", action: "Focus the wrapped trigger to reveal the tooltip"},
            %{keys: "Esc", action: "Dismiss the tooltip (when scripted) while keeping focus"}
          ],
          focus:
            "Shows on focus as well as hover, so keyboard users see it; hover alone is never required.",
          screen_reader:
            "The CSS ::before text is not in the accessibility tree, so duplicate the tip in aria-label / aria-describedby for non-visual users.",
          touch_target:
            "Hover tooltips do not appear on touch; do not hide essential information behind a tooltip.",
          reduced_motion:
            "Tooltip is excluded from the instant-toggle rule, keeping its own gentle fade; respect reduced motion."
        },
        swiftui: %{
          code: ~S"""
          Button("Hover me") { }
              .help("Add to library")
          """,
          notes:
            ".help(_:) provides hover tooltips on macOS; iOS has no hover tooltip, so surface the text another way there."
        },
        ios_status: :guidance_only
      },
      "progress" => %{
        specs: %{
          anatomy: [
            %{part: "Track", description: "Rounded muted background bar."},
            %{
              part: "Value",
              description:
                "Primary-filled portion sized by value/max (omit value for indeterminate)."
            }
          ],
          measurements: [
            %{property: "Radius", value: "9999px (rounded-full)"},
            %{property: "Track", value: "var(--muted)"},
            %{property: "Fill", value: "var(--primary)"},
            %{property: "Width", value: "w-full by default"}
          ],
          tokens: ["muted", "primary"]
        },
        accessibility: %{
          roles:
            "Native progress element (implicit role progressbar) exposing value and max. Omitting value yields an indeterminate bar.",
          focus: "Not focusable; it is a status indicator, not a control.",
          screen_reader:
            "value/max are announced as a percentage. Add an aria-label or nearby text describing what is progressing.",
          touch_target: "No hit area (display-only).",
          reduced_motion:
            "Determinate fill is static; avoid added animation for reduced-motion users."
        },
        swiftui: %{
          code: ~S"""
          ProgressView(value: 0.6)
          """,
          notes:
            "ProgressView covers both determinate (value:) and indeterminate (no value) cases natively."
        },
        ios_status: :parity
      },
      "skeleton" => %{
        specs: %{
          anatomy: [
            %{
              part: "Placeholder",
              description: "Muted block sized with classes to mimic incoming content."
            }
          ],
          measurements: [
            %{property: "Background", value: "var(--muted)"},
            %{property: "Radius", value: "var(--radius-md) (round for avatars)"},
            %{property: "Size", value: "set via height/width classes (e.g. h-4 w-48)"}
          ],
          tokens: ["muted"]
        },
        accessibility: %{
          roles:
            "Purely visual loading placeholder with no role. Mark it aria-hidden and announce loading state via an aria-live status elsewhere so screen-reader users are not given empty boxes.",
          focus: "Not focusable.",
          screen_reader:
            "Skeletons should be hidden from the accessibility tree; convey loading with a live-region message instead.",
          touch_target: "No hit area.",
          reduced_motion:
            "Skeleton is excluded from the instant-toggle rule so its shimmer can run; disable the shimmer under prefers-reduced-motion."
        },
        swiftui: %{
          code: ~S"""
          RoundedRectangle(cornerRadius: 6)
              .fill(Color(.systemGray5))
              .frame(height: 16)
              .redacted(reason: .placeholder)
          """,
          notes:
            "iOS uses .redacted(reason: .placeholder) for skeleton-style loading; the shimmer effect is a custom modifier."
        },
        ios_status: :guidance_only
      },
      "kbd" => %{
        specs: %{
          anatomy: [
            %{part: "Key", description: "Inline kbd element styled as a keycap."}
          ],
          measurements: [
            %{property: "Radius", value: "var(--radius-sm)"},
            %{property: "Border", value: "1px var(--border-color)"},
            %{property: "Background", value: "var(--muted)"},
            %{property: "Text", value: "var(--muted-foreground), 0.75rem"}
          ],
          tokens: ["muted", "muted-foreground", "border-color"]
        },
        accessibility: %{
          roles:
            "Native kbd element marking keyboard input. Semantic but non-interactive; it labels a shortcut, it does not trigger one.",
          focus: "Not focusable.",
          screen_reader:
            "Read inline as its text content. Spell out non-obvious symbols (write Command K rather than relying on the glyph alone) where clarity matters.",
          touch_target: "Decorative; no hit area.",
          reduced_motion: "No motion."
        },
        swiftui: %{
          code: ~S"""
          Text("⌘K")
              .font(.caption.monospaced())
              .padding(.horizontal, 4)
              .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 4))
          """,
          notes:
            "No native keycap view; SwiftUI's .keyboardShortcut(_:) wires the actual shortcut while a styled Text shows the hint."
        },
        ios_status: :guidance_only
      },
      "slider" => %{
        specs: %{
          anatomy: [
            %{part: "Track", description: "Muted rail showing the selectable range."},
            %{part: "Fill", description: "Primary-colored portion left of the thumb."},
            %{part: "Thumb", description: "Round background-faced knob with a 2px primary ring."}
          ],
          measurements: [
            %{property: "Thumb size", value: "1rem (size-4)"},
            %{property: "Thumb border", value: "2px var(--primary), rounded-full"},
            %{property: "Track", value: "var(--muted)"},
            %{property: "Fill", value: "var(--primary)"}
          ],
          tokens: ["muted", "primary", "background", "ring"]
        },
        accessibility: %{
          roles: "Native range input (implicit role slider) exposing min/max/value.",
          keyboard: [
            %{keys: "Left / Down", action: "Decrease the value by one step"},
            %{keys: "Right / Up", action: "Increase the value by one step"},
            %{keys: "Home / End", action: "Jump to the minimum / maximum"}
          ],
          focus: "Thumb shows a ring shadow on focus-visible.",
          screen_reader:
            "Current, min, and max values are announced. Add an aria-label describing what the slider controls.",
          touch_target:
            "Thumb is 16px visually; the native range control provides a larger effective drag area, but verify 44pt on touch.",
          reduced_motion: "Thumb movement tracks input directly; no decorative animation."
        },
        swiftui: %{
          code: ~S"""
          Slider(value: $volume, in: 0...100, step: 1)
              .accessibilityLabel("Volume")
          """,
          notes:
            "Slider is the exact native equivalent, with built-in step and accessibility value reporting."
        },
        ios_status: :parity
      },
      "spinner" => %{
        specs: %{
          anatomy: [
            %{
              part: "Spinner",
              description: "Animated loading glyph (loading loading-spinner) sized via class."
            }
          ],
          measurements: [
            %{property: "Color", value: "var(--muted-foreground)"},
            %{property: "Size", value: "loading-xs / sm / (default) / lg"}
          ],
          tokens: ["muted-foreground", "primary"]
        },
        accessibility: %{
          roles:
            "Decorative animated indicator with no implicit role. Pair it with an aria-live status message (Loading…) so screen-reader users learn that something is in progress.",
          focus: "Not focusable.",
          screen_reader:
            "The spinner itself conveys nothing; announce the loading state via accompanying live-region text.",
          touch_target: "No hit area.",
          reduced_motion:
            "Spinner is excluded from the instant-toggle rule so its rotation runs; consider pausing or simplifying it under prefers-reduced-motion."
        },
        swiftui: %{
          code: ~S"""
          ProgressView()
              .progressViewStyle(.circular)
          """,
          notes:
            "A value-less circular ProgressView is the native indeterminate spinner and handles reduced-motion automatically."
        },
        ios_status: :parity
      },
      "pagination" => %{
        specs: %{
          anatomy: [
            %{part: "Nav", description: "nav landmark labeled Pagination wrapping the controls."},
            %{
              part: "Prev / Next",
              description: "Ghost buttons with chevron icons; disabled at the ends."
            },
            %{
              part: "Page buttons",
              description: "Square buttons; the current page is outlined and marked aria-current."
            }
          ],
          measurements: [
            %{property: "Button size", value: "btn-sm (h-8 / 2rem) square"},
            %{property: "Gap", value: "0.25rem (gap-1)"},
            %{property: "Current page", value: "btn-outline + aria-current=page"},
            %{property: "Gap marker", value: "ellipsis in muted-foreground"}
          ],
          tokens: [
            "accent",
            "accent-foreground",
            "muted-foreground",
            "border-color",
            "foreground"
          ]
        },
        accessibility: %{
          roles:
            "nav element with aria-label=Pagination. Pages render as links (path mode) or buttons (event mode); the current page carries aria-current=page and end controls set aria-disabled / disabled.",
          keyboard: [
            %{keys: "Tab", action: "Move between page links/buttons"},
            %{keys: "Enter / Space", action: "Activate the focused page control"}
          ],
          focus:
            "Each control shows its focus ring; disabled prev/next are skipped/marked aria-disabled.",
          screen_reader:
            "The nav label names the region and aria-current identifies the active page. Icon-only prev/next buttons include visible Previous / Next text.",
          touch_target:
            "btn-sm controls are 32px; bump spacing or size for touch-primary layouts toward 44pt.",
          reduced_motion: "No motion."
        },
        swiftui: %{
          code: ~S"""
          HStack {
              Button("Previous") { page -= 1 }.disabled(page <= 1)
              ForEach(1...totalPages, id: \.self) { p in
                  Button("\(p)") { page = p }
                      .buttonStyle(p == page ? .borderedProminent : .bordered)
              }
              Button("Next") { page += 1 }.disabled(page >= totalPages)
          }
          """,
          notes:
            "No native pager control (iOS uses .page TabView dots or infinite lists); compose buttons when explicit numbered pagination is required."
        },
        ios_status: :partial
      },
      "popover" => %{
        specs: %{
          anatomy: [
            %{
              part: "Trigger",
              description: "role=button element (outline button by default) opened on click."
            },
            %{
              part: "Panel",
              description: "dropdown-content floating surface holding rich content."
            }
          ],
          measurements: [
            %{property: "Default width", value: "w-72"},
            %{property: "Panel radius", value: "var(--radius-md)"},
            %{property: "Panel padding", value: "1rem (p-4)"},
            %{property: "Border", value: "1px var(--border-color)"},
            %{property: "Shadow", value: "var(--shadow-sm)"}
          ],
          tokens: ["popover", "popover-foreground", "border-color", "foreground"]
        },
        accessibility: %{
          roles:
            "CSS-only daisyUI dropdown: a role=button trigger and a focusable content panel. Add aria-haspopup / aria-expanded and aria-controls for a complete popover pattern.",
          keyboard: [
            %{keys: "Tab / Enter / Space", action: "Open the popover and move focus into it"},
            %{keys: "Tab", action: "Cycle through focusable content inside the panel"},
            %{keys: "Esc", action: "Close the popover and return focus to the trigger"}
          ],
          focus:
            "Opens via focus and closes when focus leaves the group. Keep an explicit focus target inside for keyboard users.",
          screen_reader:
            "Give the trigger an accessible name and wire aria-expanded so the open/closed state is announced.",
          touch_target:
            "Trigger follows button sizing (44pt on touch); panel content controls keep their own hit areas.",
          reduced_motion: "Panel shows/hides without a color fade under the theme."
        },
        swiftui: %{
          code: ~S"""
          Button("Open popover") { showPopover = true }
              .popover(isPresented: $showPopover) {
                  VStack { /* rich content */ }.padding()
              }
          """,
          notes:
            ".popover(isPresented:) is the native equivalent on iPad/macOS; on iPhone it falls back to a sheet, so presentation differs by size class."
        },
        ios_status: :partial
      },
      "toast" => %{
        specs: %{
          anatomy: [
            %{
              part: "Host",
              description:
                "Fixed bottom-end container (toast-host) with role=status and aria-live=polite."
            },
            %{
              part: "Toast",
              description: "Alert/card injected by showToast(), animated in and out."
            }
          ],
          measurements: [
            %{property: "Position", value: "toast-end toast-bottom, z-60"},
            %{property: "Toast shadow", value: "var(--shadow-sm)"},
            %{property: "Enter", value: "shadcn-toast-in keyframe (~slide + fade)"},
            %{property: "Exit", value: "shadcn-toast-out keyframe"}
          ],
          tokens: ["popover", "popover-foreground", "card", "border-color"]
        },
        accessibility: %{
          roles:
            "The host is role=status with aria-live=polite, so appended toasts are announced without stealing focus. Use an assertive live region only for truly urgent messages.",
          keyboard: [
            %{keys: "Tab", action: "Reach an action/close control inside a toast (if present)"}
          ],
          focus:
            "Toasts do not steal focus; any close/action button inside is reachable in normal tab order.",
          screen_reader:
            "The polite live region reads new toasts after the current utterance. Keep messages short and self-contained.",
          touch_target:
            "Any dismiss/action control inside the toast should meet the 44pt minimum.",
          reduced_motion:
            "The slide/fade keyframes should be reduced to a plain appearance under prefers-reduced-motion."
        },
        swiftui: %{
          code: ~S"""
          someView
              .overlay(alignment: .bottom) {
                  if showToast {
                      Text("Saved")
                          .padding()
                          .background(.regularMaterial, in: Capsule())
                          .transition(.move(edge: .bottom).combined(with: .opacity))
                  }
              }
          """,
          notes:
            "No native toast/snackbar; compose a transient overlay with a transition. Announce it with .accessibilityAddTraits or an accessibility notification."
        },
        ios_status: :partial
      }
    }
  end
end
