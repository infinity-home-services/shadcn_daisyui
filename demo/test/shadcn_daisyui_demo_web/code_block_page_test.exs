defmodule ShadcnDaisyuiDemoWeb.CodeBlockPageTest do
  @moduledoc """
  The Code Block gallery page: every example renders from the real component,
  in the Data display group, with its specs, accessibility and iOS guidance.
  """
  use ShadcnDaisyuiDemoWeb.ConnCase, async: true

  alias ShadcnDaisyuiDemoWeb.Catalog

  test "the page shows every example, rendered from the component", %{conn: conn} do
    html = conn |> get(~p"/docs/components/code-block") |> html_response(200)

    for title <- [
          "Payload with a filename",
          "Line numbers",
          "Diff",
          "Wrapped log output",
          "Error output",
          "Small, inside a card"
        ] do
      assert html =~ ~r{>\s*#{title}\s*</h[23]>}, "missing example #{title}"
    end

    # the live previews: real component markup, escaped text, one line per <pre>
    assert html =~ ~s(data-slot="code-block")
    assert html =~ ~s(id="webhook-payload-content" data-slot="code-block-content" role="region")

    assert html =~ ~s(data-variant="highlighted" data-line="42")
    assert html =~ ~s(data-variant="removed")
    assert html =~ ~s(data-variant="added")
    assert html =~ ~s(data-variant="destructive")
    assert html =~ ~s(data-size="sm")
    assert html =~ ~s(data-wrap)
    assert html =~ "Maple &amp; Co."
    assert html =~ "&lt;title&gt;502 Bad Gateway&lt;/title&gt;"

    # the previews carry no LiveView-only wiring
    refute html =~ ~s(phx-hook="ShadcnCodeBlock")
    refute html =~ ~s(data-code-block-status phx-update)

    # a <pre>'s lines stay back to back (re-indenting the recipe leaves them alone)
    [pre] = Regex.run(~r{<pre id="import-rows-content".*?</pre>}s, html)
    refute pre =~ "\n"

    assert pre =~
             ~s(<span data-slot="code-block-line-content">jordan.diaz@summit,Jordan,Diaz,Sales</span>)

    # design guidance
    assert html =~ ".textSelection(.enabled)"
    assert html =~ "UIPasteboard"
    assert html =~ "--code-block-added-label"
  end

  test "it sits in the Data display group" do
    group = Enum.find(Catalog.groups(), &(&1.title == "Data display"))
    assert "code-block" in Enum.map(group.components, & &1.slug)
    assert Catalog.component("code-block").hook == true
  end

  test "its markdown export renders", %{conn: conn} do
    md = conn |> get("/docs/components/code-block.md") |> response(200)
    assert md =~ "Code Block"
    assert md =~ "code_block"
  end
end
