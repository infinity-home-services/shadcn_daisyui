defmodule ShadcnDaisyuiDemoWeb.Guides do
  @moduledoc """
  Registry for the design-guideline pages (Foundations + Styles), mirroring
  `ShadcnDaisyuiDemoWeb.Catalog` for components.

  Each guide's source of truth is its markdown file in the package's
  `usage-rules/` directory - read at compile time so the `.md` routes and the
  `/design-guidelines.md` aggregate serve exactly what ships in the hex package.
  The HEEx page for each guide is a visual companion, not a rendering of the
  markdown.
  """

  @usage_rules_dir Path.expand("../../../usage-rules", __DIR__)

  # Order matters: it is the sidebar order AND the order of the
  # /design-guidelines.md aggregate (platforms first as the preamble).
  @specs [
    %{
      section: :foundations,
      slug: "platforms",
      title: "Platforms",
      description: "Dual units, HIG arbitration, and the token map between web and SwiftUI.",
      source: "foundations-platforms.md",
      template: :foundations_platforms
    },
    %{
      section: :foundations,
      slug: "accessibility",
      title: "Accessibility & content",
      description: "Contrast, focus, labels, reduced motion, and how to write UI text.",
      source: "foundations-accessibility.md",
      template: :foundations_accessibility
    },
    %{
      section: :foundations,
      slug: "layout",
      title: "Layout",
      description: "Breakpoints, window size classes, content widths, and the page scaffold.",
      source: "foundations-layout.md",
      template: :foundations_layout
    },
    %{
      section: :foundations,
      slug: "spacing",
      title: "Spacing",
      description: "The 4px grid, the blessed steps, and where each one is used.",
      source: "foundations-spacing.md",
      template: :foundations_spacing
    },
    %{
      section: :foundations,
      slug: "navigation",
      title: "Navigation",
      description: "Where navigation lives at each window size class.",
      source: "foundations-navigation.md",
      template: :foundations_navigation
    },
    %{
      section: :foundations,
      slug: "interaction",
      title: "Interaction",
      description: "The state ladder, touch targets, and input-method differences.",
      source: "foundations-interaction.md",
      template: :foundations_interaction
    },
    %{
      section: :styles,
      slug: "color",
      title: "Color",
      description: "Semantic token usage, the emphasis ladder, and brand splash rules.",
      source: "styles-color.md",
      template: :styles_color
    },
    %{
      section: :styles,
      slug: "typography",
      title: "Typography & icons",
      description: "The six-role type ramp and iconography rules.",
      source: "styles-typography.md",
      template: :styles_typography
    },
    %{
      section: :styles,
      slug: "shape-elevation",
      title: "Shape & elevation",
      description: "Radius roles and the (deliberately flat) elevation ladder.",
      source: "styles-shape-elevation.md",
      template: :styles_shape_elevation
    },
    %{
      section: :styles,
      slug: "motion",
      title: "Motion",
      description: "Three durations, standard easing, opacity and transform only.",
      source: "styles-motion.md",
      template: :styles_motion
    }
  ]

  for spec <- @specs do
    @external_resource Path.join(@usage_rules_dir, spec.source)
  end

  @guides Enum.map(@specs, fn spec ->
            Map.merge(spec, %{
              markdown: File.read!(Path.join(@usage_rules_dir, spec.source)),
              path: "/docs/#{spec.section}/#{spec.slug}"
            })
          end)

  @doc "All guides, in sidebar/aggregate order."
  def all, do: @guides

  @doc "Sidebar groups: Foundations then Styles, each with its guides in order."
  def groups do
    [
      %{id: :foundations, title: "Foundations", guides: section(:foundations)},
      %{id: :styles, title: "Styles", guides: section(:styles)}
    ]
  end

  @doc "Look up one guide by section + slug. Returns nil when unknown."
  def guide(section, slug) when section in ["foundations", "styles"] do
    Enum.find(@guides, &(Atom.to_string(&1.section) == section and &1.slug == slug))
  end

  def guide(_section, _slug), do: nil

  defp section(id), do: Enum.filter(@guides, &(&1.section == id))

  @doc """
  The one-file drop-in: every guideline file concatenated (platforms first),
  for `curl …/design-guidelines.md > DesignGuidelines.md` in any project.
  """
  def design_guidelines_md do
    body = @guides |> Enum.map(&String.trim_trailing(&1.markdown)) |> Enum.join("\n\n---\n\n")

    """
    <!--
    shadcn_daisyui design guidelines - single-file bundle.
    Source of truth: the usage-rules/*.md files shipped in the shadcn_daisyui
    hex package. Rules tagged [web]/[ios] are platform-scoped; untagged rules
    are universal.
    -->

    #{body}
    """
  end
end
