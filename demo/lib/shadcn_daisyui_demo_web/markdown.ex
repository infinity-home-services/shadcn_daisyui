defmodule ShadcnDaisyuiDemoWeb.Markdown do
  @moduledoc """
  AI-consumable plain-text renditions of the component catalog.

  Pure functions from `ShadcnDaisyuiDemoWeb.Catalog` data to markdown / index
  strings, used by the `/llms.txt`, `/llms-full.txt`, `/docs/search.json`, and
  `/docs/components/:slug.md` endpoints (and snapshotted by `mix site.export`).

  All link-producing functions take a `base` path prefix (e.g. `"/shadcn_daisyui"`
  when the site is hosted under a sub-path) which defaults to `""`.
  """

  alias ShadcnDaisyuiDemoWeb.Catalog
  alias ShadcnDaisyuiDemoWeb.Guides

  @summary """
  shadcn_daisyui is a daisyUI v5 theme + component kit that makes daisyUI \
  components look like shadcn/ui, built for Phoenix apps. Components are plain, \
  copy-pasteable HTML styled by the theme - no React required. Install it with \
  `mix shadcn_daisyui.install`. Usage rules for AI agents ship as \
  `usage-rules.md` and can be synced into your project with the `usage_rules` \
  package.\
  """

  @doc "The markdown document for a single component spec."
  def component_markdown(spec) do
    [
      "# #{spec.title}",
      spec.description,
      hook_note(spec),
      notes(spec),
      guidance(spec),
      do_dont_md(spec),
      specs_md(spec),
      accessibility_md(spec),
      swiftui_md(spec),
      props_table(spec),
      examples(spec)
    ]
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n\n")
    |> Kernel.<>("\n")
  end

  @doc "The llms.txt index document."
  def llms_txt(base \\ "") do
    """
    # shadcn_daisyui

    #{@summary}

    ## Components

    #{component_index(base)}

    ## Guides

    - [Installation](#{base}/docs/installation): how to add the theme and JS to a Phoenix app.
    - [Adopt the design system](#{base}/docs/adopt): add the guidelines to any project - Claude plugin, usage_rules sync, Swift package, or one-file bundle.
    - [Themes](#{base}/docs/themes): theming tokens and the interactive theme creator.

    ## Design guidelines

    Platform-portable rules (web + native iOS/iPadOS). One-file bundle:
    [design-guidelines.md](#{base}/design-guidelines.md).

    #{guide_index(base)}
    """
  end

  @doc """
  The llms-full.txt document: the index intro, the design guidelines, then every
  component's markdown.
  """
  def llms_full_txt(_base \\ "") do
    full =
      Catalog.slugs()
      |> Enum.map(&component_markdown(Catalog.component(&1)))
      |> Enum.join("\n---\n\n")

    """
    # shadcn_daisyui

    #{@summary}

    ---

    #{Guides.design_guidelines_md()}
    ---

    #{full}\
    """
  end

  @doc "The search index: guides then components, in sidebar order."
  def search_index(base \\ "") do
    guides =
      for group <- Guides.groups(), guide <- group.guides do
        %{
          slug: guide.slug,
          title: guide.title,
          description: guide.description,
          group: group.title,
          url: "#{base}#{guide.path}"
        }
      end

    components =
      for group <- Catalog.groups(), component <- group.components do
        %{
          slug: component.slug,
          title: component.title,
          description: component.description,
          group: group.title,
          url: "#{base}/docs/components/#{component.slug}"
        }
      end

    guides ++ components
  end

  # ---------------------------------------------------------------------------

  defp guide_index(base) do
    Guides.all()
    |> Enum.map(fn g -> "- [#{g.title}](#{base}#{g.path}.md): #{g.description}" end)
    |> Enum.join("\n")
  end

  defp component_index(base) do
    Catalog.slugs()
    |> Enum.map(fn slug ->
      c = Catalog.component(slug)
      "- [#{c.title}](#{base}/docs/components/#{c.slug}.md): #{c.description}"
    end)
    |> Enum.join("\n")
  end

  defp hook_note(spec) do
    if Map.get(spec, :hook) do
      "> Requires a JS hook: initialize with `initShadcnDaisyui()` (dead views) " <>
        "or the corresponding `Shadcn*` LiveView hook from `shadcn-daisyui.js`."
    end
  end

  defp notes(spec) do
    case Map.get(spec, :notes) do
      nil -> nil
      notes -> String.trim(notes)
    end
  end

  defp guidance(spec) do
    case Map.get(spec, :guidance) do
      nil ->
        nil

      g ->
        bullets = fn items -> Enum.map_join(items, "\n", &"- #{&1}") end

        [
          "## Usage guidance",
          g[:use_when] && "Use when:\n\n#{bullets.(g.use_when)}",
          g[:avoid_when] && "Don't use for:\n\n#{bullets.(g.avoid_when)}",
          g[:sizing] && "Sizing: #{g.sizing}",
          g[:responsive] && "Responsive: #{g.responsive}",
          g[:ios] && "iOS: #{g.ios}"
        ]
        |> Enum.reject(&(&1 in [nil, false]))
        |> Enum.join("\n\n")
    end
  end

  defp do_dont_md(spec) do
    case Map.get(spec, :do_dont) do
      nil ->
        nil

      dd ->
        [
          "## Do / Don't",
          "Do - #{dd.do.label}:\n\n" <> code_block("html", dd.do.code),
          "Don't - #{dd.dont.label}:\n\n" <> code_block("html", dd.dont.code)
        ]
        |> compact_join()
    end
  end

  defp specs_md(spec) do
    case Map.get(spec, :specs) do
      nil ->
        nil

      s ->
        [
          "## Specs",
          s[:anatomy] &&
            table(["Part", "Description"], Enum.map(s.anatomy, &[&1.part, &1.description])),
          s[:measurements] &&
            table(["Property", "Value"], Enum.map(s.measurements, &[&1.property, &1.value])),
          s[:tokens] && "Tokens used: #{Enum.map_join(s.tokens, ", ", &"`#{&1}`")}"
        ]
        |> compact_join()
    end
  end

  defp accessibility_md(spec) do
    case Map.get(spec, :accessibility) do
      nil ->
        nil

      a ->
        [
          "## Accessibility",
          a[:keyboard] && table(["Keys", "Action"], Enum.map(a.keyboard, &[&1.keys, &1.action])),
          a[:roles] && "Role / ARIA: #{a.roles}",
          a[:focus] && "Focus: #{a.focus}",
          a[:screen_reader] && "Screen reader: #{a.screen_reader}",
          a[:touch_target] && "Touch target: #{a.touch_target}",
          a[:reduced_motion] && "Reduced motion: #{a.reduced_motion}"
        ]
        |> compact_join()
    end
  end

  defp swiftui_md(spec) do
    case Map.get(spec, :swiftui) do
      nil ->
        nil

      sw ->
        [
          "## Native (SwiftUI)",
          ios_status_line(Map.get(spec, :ios_status)),
          code_block("swift", sw.code),
          sw[:notes]
        ]
        |> compact_join()
    end
  end

  defp ios_status_line(:parity), do: "Parity: native parity with the web component."
  defp ios_status_line(:partial), do: "Parity: partial - some web features are not yet native."
  defp ios_status_line(:guidance_only), do: "Parity: guidance only - no native component yet."
  defp ios_status_line(nil), do: nil

  defp compact_join(parts) do
    parts
    |> Enum.reject(&(&1 in [nil, false]))
    |> Enum.join("\n\n")
  end

  # A GitHub-flavored markdown table from a header row and a list of cell rows.
  defp table(headers, rows) do
    header = "| #{Enum.join(headers, " | ")} |"
    divider = "| #{Enum.map_join(headers, " | ", fn _ -> "---" end)} |"

    body =
      Enum.map_join(rows, "\n", fn cells -> "| #{Enum.map_join(cells, " | ", &cell/1)} |" end)

    Enum.join([header, divider, body], "\n")
  end

  defp props_table(spec) do
    case Map.get(spec, :props) do
      props when is_list(props) and props != [] ->
        rows =
          Enum.map(props, fn p ->
            "| #{cell(p.name)} | #{cell(p.type)} | #{cell(p.default)} |"
          end)

        Enum.join(
          ["## Props", "", "| Name | Type | Default |", "| --- | --- | --- |" | rows],
          "\n"
        )

      _ ->
        nil
    end
  end

  defp examples(spec) do
    Enum.map(spec.examples, fn example ->
      [
        "## #{example.title}",
        heex_block(example),
        code_block("html", Map.get(example, :code, ""))
      ]
      |> Enum.reject(&is_nil/1)
      |> Enum.join("\n\n")
    end)
  end

  defp heex_block(example) do
    case Map.get(example, :heex) do
      nil -> nil
      heex -> "HEEx:\n\n" <> code_block("heex", heex)
    end
  end

  defp code_block(lang, code) do
    "```#{lang}\n#{String.trim_trailing(code)}\n```"
  end

  # Prop types like "default | secondary | outline" contain literal pipes that
  # would break the markdown table - escape them.
  defp cell(value), do: String.replace(to_string(value), "|", "\\|")
end
