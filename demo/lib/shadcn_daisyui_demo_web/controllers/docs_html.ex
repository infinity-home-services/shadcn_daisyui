defmodule ShadcnDaisyuiDemoWeb.DocsHTML do
  @moduledoc """
  Templates for the documentation pages (component pages + themes guide).
  """
  use ShadcnDaisyuiDemoWeb, :html

  import ShadcnDaisyuiDemoWeb.DocsComponents
  # package function components rendered live on the dark-mode / CSP page
  import ShadcnDaisyui.Components, only: [select: 1, combobox: 1, input_otp: 1]

  import ShadcnDaisyui.Components.Overlay,
    only: [dialog: 1, sheet: 1, drawer: 1, popover: 1, tooltip: 1, dropdown_menu: 1, command: 1]

  embed_templates "docs_html/*"

  @doc false
  def swatches do
    [
      %{label: "Background", token: "--background", class: "bg-base-100"},
      %{label: "Foreground", token: "--foreground", class: "bg-foreground"},
      %{label: "Card", token: "--card", class: "bg-card"},
      %{label: "Muted", token: "--muted", class: "bg-muted"},
      %{label: "Primary", token: "--primary", class: "bg-primary"},
      %{label: "Secondary", token: "--secondary", class: "bg-secondary"},
      %{label: "Accent", token: "--accent", class: "bg-accent"},
      %{label: "Border", token: "--border", class: "bg-base-300"},
      %{label: "Destructive", token: "--destructive", class: "bg-destructive"}
    ]
  end

  @doc false
  def theme_panels, do: [{"Light", "shadcn"}, {"Dark", "shadcn-dark"}]

  @doc "Every 0.6.0 dark-mode / overlay change, with before and after values."
  def dark_mode_changes do
    [
      %{
        area: "Field fill (dark)",
        token: "--input-background",
        before: "var(--background) - oklch(0.145 0 0), darker than cards and popovers",
        after: "color-mix(in oklab, var(--input) 30%, transparent) - shadcn bg-input/30"
      },
      %{
        area: "Custom select / combobox / date-picker trigger",
        token: "border, dark hover",
        before: "border var(--border-color); hover var(--accent)",
        after: "border var(--input); dark hover color-mix(var(--input) 50%) - bg-input/50"
      },
      %{
        area: "OTP slot",
        token: ".otp-slot",
        before: "background transparent, no shadow",
        after: "var(--input-background), shadow-xs"
      },
      %{
        area: "Subtle fill (dark)",
        token: "--color-base-200",
        before: "oklch(0.205 0 0) - same as --card, invisible on cards and popovers",
        after: "var(--muted) - oklch(0.269 0 0)"
      },
      %{
        area: "Border (dark)",
        token: "--color-base-300",
        before: "oklch(0.269 0 0) - opaque grey",
        after: "var(--border-color) - oklch(1 0 0 / 10%)"
      },
      %{
        area: "Modal backdrop",
        token: ".modal, dialog.sheet/.drawer-bottom/.command-dialog",
        before: ".modal oklch(0 0 0 / 0.4); the others rgb(0 0 0 / 0.5)",
        after: "all oklch(0 0 0 / 0.5) - shadcn/ui bg-black/50"
      },
      %{
        area: "Menu, popover, select/combobox/date panels, context menu",
        token: "border + shadow",
        before: "1px border-color border, shadow-sm",
        after: "ring-1 ring-foreground/10, shadow-md"
      },
      %{
        area: "Dialog box and command dialog",
        token: ".modal-box, dialog.command-dialog",
        before: "rounded-lg, 1px border, shadow-sm",
        after: "rounded-xl, ring-1 ring-foreground/10, shadow-lg"
      },
      %{
        area: "Sheet and drawer",
        token: "dialog.sheet, dialog.drawer-bottom",
        before: "shadow-sm",
        after: "shadow-lg"
      },
      %{
        area: "Tooltip",
        token: ".tooltip",
        before: "bg primary, text primary-foreground",
        after: "bg foreground, text background"
      },
      %{
        area: "Overlay open / close",
        token: "<.dialog> <.sheet> <.drawer> <.command>",
        before: "inline onclick handlers (blocked by a strict CSP)",
        after: "phx-click JS dispatch + one delegated listener; open survives LiveView patches"
      }
    ]
  end

  @doc false
  def radii do
    [
      %{label: "sm", value: "calc(r - 4px)", class: "rounded-sm"},
      %{label: "md", value: "calc(r - 2px)", class: "rounded-md"},
      %{label: "lg", value: "0.625rem", class: "rounded-lg"},
      %{label: "xl", value: "calc(r + 4px)", class: "rounded-xl"}
    ]
  end
end
