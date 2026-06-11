defmodule ShadcnDaisyuiDemoWeb.DocsHTML do
  @moduledoc """
  Templates for the documentation pages (component pages + themes guide).
  """
  use ShadcnDaisyuiDemoWeb, :html

  import ShadcnDaisyuiDemoWeb.DocsComponents

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
  def radii do
    [
      %{label: "sm", value: "calc(r - 4px)", class: "rounded-sm"},
      %{label: "md", value: "calc(r - 2px)", class: "rounded-md"},
      %{label: "lg", value: "0.625rem", class: "rounded-lg"},
      %{label: "xl", value: "calc(r + 4px)", class: "rounded-xl"}
    ]
  end
end
