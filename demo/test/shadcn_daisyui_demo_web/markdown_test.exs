defmodule ShadcnDaisyuiDemoWeb.MarkdownTest do
  use ExUnit.Case, async: true

  alias ShadcnDaisyuiDemoWeb.Markdown

  @spec_fixture %{
    slug: "widget",
    title: "Widget",
    description: "A test widget.",
    hook: true,
    props: [%{name: "variant", type: "a | b", default: "a"}],
    examples: [
      %{title: "Default", code: "<div class=\"widget\"></div>\n"}
    ]
  }

  test "component_markdown renders title, description, hook note, props, and examples" do
    md = Markdown.component_markdown(@spec_fixture)

    assert md =~ "# Widget"
    assert md =~ "A test widget."
    assert md =~ "Requires a JS hook"
    assert md =~ "| Name | Type | Default |"
    assert md =~ "| variant | a \\| b | a |"
    assert md =~ "## Default"
    assert md =~ "```html\n<div class=\"widget\"></div>\n```"
  end

  test "component_markdown includes a HEEx block when an example has :heex" do
    spec =
      put_in(@spec_fixture.examples, [
        %{title: "Default", code: "<div></div>", heex: "<.widget variant=\"a\" />"}
      ])

    md = Markdown.component_markdown(spec)

    assert md =~ "```heex\n<.widget variant=\"a\" />\n```"
    assert md =~ "```html\n<div></div>\n```"
  end

  test "component_markdown omits hook note and props when absent" do
    spec = @spec_fixture |> Map.drop([:hook, :props])
    md = Markdown.component_markdown(spec)

    refute md =~ "Requires a JS hook"
    refute md =~ "| Name | Type | Default |"
  end

  test "component_markdown renders specs, accessibility, and native sections when present" do
    spec =
      Map.merge(@spec_fixture, %{
        specs: %{
          anatomy: [%{part: "Container", description: "The surface."}],
          measurements: [%{property: "Height", value: "2.25rem"}],
          tokens: ["primary", "ring"]
        },
        accessibility: %{
          keyboard: [%{keys: "Enter / Space", action: "Activate"}],
          roles: "Native button."
        },
        swiftui: %{code: "Button(\"Go\") {}", notes: "Use .borderedProminent."},
        ios_status: :parity
      })

    md = Markdown.component_markdown(spec)

    assert md =~ "## Specs"
    assert md =~ "| Part | Description |"
    assert md =~ "| Height | 2.25rem |"
    assert md =~ "Tokens used: `primary`, `ring`"
    assert md =~ "## Accessibility"
    assert md =~ "| Keys | Action |"
    assert md =~ "Role / ARIA: Native button."
    assert md =~ "## Native (SwiftUI)"
    assert md =~ "Parity: native parity"
    assert md =~ "```swift\nButton(\"Go\") {}\n```"
    assert md =~ "Use .borderedProminent."
  end

  test "component_markdown omits the new sections when absent" do
    md = Markdown.component_markdown(@spec_fixture)

    refute md =~ "## Specs"
    refute md =~ "## Accessibility"
    refute md =~ "## Native (SwiftUI)"
    refute md =~ "## Do / Don't"
  end

  test "component_markdown renders the do/don't pair when present" do
    spec =
      Map.put(@spec_fixture, :do_dont, %{
        do: %{label: "Label fields", code: "<label>Email</label>"},
        dont: %{label: "Placeholder only", code: "<input placeholder=Email>"}
      })

    md = Markdown.component_markdown(spec)

    assert md =~ "## Do / Don't"
    assert md =~ "Do - Label fields:"
    assert md =~ "Don't - Placeholder only:"
    assert md =~ "<label>Email</label>"
  end

  test "llms_txt links every component markdown file under the base path" do
    txt = Markdown.llms_txt("/base")

    assert txt =~ "# shadcn_daisyui"
    assert txt =~ "- [Button](/base/docs/components/button.md):"
    assert txt =~ "(/base/docs/installation)"
    assert txt =~ "(/base/docs/themes)"
  end

  test "llms_txt links every design guideline under the base path" do
    txt = Markdown.llms_txt("/base")

    assert txt =~ "[design-guidelines.md](/base/design-guidelines.md)"

    for guide <- ShadcnDaisyuiDemoWeb.Guides.all() do
      assert txt =~ "- [#{guide.title}](/base#{guide.path}.md):"
    end
  end

  test "llms_full_txt contains every component title and the design guidelines" do
    full = Markdown.llms_full_txt()

    for slug <- ShadcnDaisyuiDemoWeb.Catalog.slugs() do
      title = ShadcnDaisyuiDemoWeb.Catalog.component(slug).title
      assert full =~ "# #{title}"
    end

    assert full =~ "# shadcn_daisyui - spacing"
    assert full =~ "# shadcn_daisyui - motion"
  end

  test "search_index lists guides then components with group and url" do
    index = Markdown.search_index("/base")

    guide_slugs = Enum.map(ShadcnDaisyuiDemoWeb.Guides.all(), & &1.slug)
    assert Enum.map(index, & &1.slug) == guide_slugs ++ ShadcnDaisyuiDemoWeb.Catalog.slugs()

    entry = Enum.find(index, &(&1.slug == "button"))
    assert entry.title == "Button"
    assert entry.group == "Actions"
    assert entry.url == "/base/docs/components/button"
    assert is_binary(entry.description)

    guide = Enum.find(index, &(&1.url == "/base/docs/foundations/spacing"))
    assert guide.title == "Spacing"
    assert guide.group == "Foundations"
  end
end
