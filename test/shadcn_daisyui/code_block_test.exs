defmodule ShadcnDaisyui.Components.CodeBlockTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.Components.CodeBlock

  defp render(template) do
    template |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  # the <code> element's lines: [{attributes, content}]
  defp lines(html) do
    ~r{<span data-slot="code-block-line"([^>]*)><span data-slot="code-block-line-content">(.*?)</span></span>(?=<span data-slot="code-block-line"|</code>)}
    |> Regex.scan(html, capture: :all_but_first)
    |> Enum.map(fn [attrs, content] -> {String.trim(attrs), content} end)
  end

  describe "code" do
    test "splits into lines, HTML-escaped, dropping one trailing newline" do
      assigns = %{}
      html = render(~H|<.code_block id="cb" code={"a <b> & \"c\"\n  indented\n"} />|)

      assert lines(html) == [
               {"", "a &lt;b&gt; &amp; &quot;c&quot;"},
               {"", "  indented"}
             ]

      refute html =~ "<b>"
    end

    test "an empty line holds a newline entity; CRLF counts as one break" do
      assigns = %{}
      html = render(~H|<.code_block id="cb" code={"one\r\n\r\nthree"} />|)
      assert lines(html) == [{"", "one"}, {"", "&#10;"}, {"", "three"}]
    end

    test "the <pre> holds no whitespace between its lines" do
      assigns = %{}
      html = render(~H|<.code_block id="cb" code={"a\nb"} />|)

      [pre] = Regex.run(~r{<pre[^>]*>.*</pre>}s, html)
      refute pre =~ "\n"
      assert pre =~ ~s(><code data-slot="code-block-code"><span data-slot="code-block-line">)
      assert pre =~ ~s(</span></span></code></pre>)
    end
  end

  describe "lines" do
    test "carry variants; strings are escaped, raw HTML is not" do
      assigns = %{
        lines: [
          "{",
          {:removed, ~s(  "a": 1,)},
          {"added", ~s(  "a": 2,)},
          {:highlighted, Phoenix.HTML.raw(~s(<span class="k">x</span>))},
          Phoenix.HTML.raw("<i>y</i>"),
          {:default, "<z>"},
          ""
        ]
      }

      html = render(~H|<.code_block id="diff" lines={@lines} />|)

      assert lines(html) == [
               {"", "{"},
               {~s(data-variant="removed"), "  &quot;a&quot;: 1,"},
               {~s(data-variant="added"), "  &quot;a&quot;: 2,"},
               {~s(data-variant="highlighted"), ~s(<span class="k">x</span>)},
               {"", "<i>y</i>"},
               {"", "&lt;z&gt;"},
               {"", "&#10;"}
             ]
    end

    test "an unknown variant or item raises" do
      assigns = %{}

      assert_raise ArgumentError, ~r/variant in/, fn ->
        render(~H|<.code_block id="x" lines={[{:changed, "a"}]} />|)
      end

      assert_raise ArgumentError, ~r/expected a string/, fn ->
        render(~H|<.code_block id="x" lines={[42]} />|)
      end
    end
  end

  describe "numbering and highlight" do
    test "line_numbers puts each line's number on it, from start_line" do
      assigns = %{}
      html = render(~H|<.code_block id="cb" code={"a\nb\nc"} line_numbers start_line={99} />|)

      assert html =~ ~s(data-numbered)

      assert Enum.map(lines(html), &elem(&1, 0)) ==
               ~w(data-line="99" data-line="100" data-line="101")
    end

    test "without line_numbers there is no gutter" do
      assigns = %{}
      html = render(~H|<.code_block id="cb" code={"a\nb"} />|)
      refute html =~ "data-numbered"
      refute html =~ "data-line"
    end

    test "highlight tints lines by their numbers, ranges included" do
      assigns = %{}

      html =
        render(
          ~H|<.code_block id="cb" code={"1\n2\n3\n4\n5"} start_line={10} highlight={[10, 12..13]} />|
        )

      assert Enum.map(lines(html), &elem(&1, 0)) == [
               ~s(data-variant="highlighted"),
               "",
               ~s(data-variant="highlighted"),
               ~s(data-variant="highlighted"),
               ""
             ]
    end

    test "an explicit line variant wins over highlight" do
      assigns = %{}
      html = render(~H|<.code_block id="cb" lines={[{:added, "a"}, "b"]} highlight={[1, 2]} />|)

      assert Enum.map(lines(html), &elem(&1, 0)) == [
               ~s(data-variant="added"),
               ~s(data-variant="highlighted")
             ]
    end
  end

  describe "parts and ARIA" do
    test "the scroll region is a focusable, labelled region, always left to right" do
      assigns = %{}
      html = render(~H|<.code_block id="log" code="x" />|)

      assert html =~ ~s(id="log" phx-hook="ShadcnCodeBlock" data-slot="code-block")
      assert html =~ ~s(data-variant="default" data-size="default")

      assert html =~
               ~s(<pre id="log-content" data-slot="code-block-content" role="region" aria-label="Code" tabindex="0" dir="ltr")

      refute html =~ "code-block-header"
    end

    test "a title makes a header that names the region; label overrides it" do
      assigns = %{}

      html =
        render(~H|<.code_block id="p" code="x" title="payload.json" icon="hero-document-text" />|)

      assert html =~ ~s(data-slot="code-block-header")
      assert html =~ ~s(id="p-title" data-slot="code-block-title")
      assert html =~ ~s(<span class="hero-document-text" aria-hidden="true"></span>payload.json)
      [pre] = Regex.run(~r{<pre[^>]*>}, html)
      assert pre =~ ~s(aria-labelledby="p-title")
      refute pre =~ "aria-label="

      html =
        render(~H|<.code_block id="p" code="x" title="payload.json" label="Webhook payload" />|)

      assert html =~ ~s(aria-label="Webhook payload")
      refute html =~ "aria-labelledby"
    end

    test "copy button: labelled, both icons decorative, a polite status, attrs kept on patches" do
      assigns = %{}
      html = render(~H|<.code_block id="cb" code="x" copy_label="Copier" copied_label="Copié" />|)

      [button] = Regex.run(~r{<button[^>]*data-slot="code-block-copy"[^>]*>.*?</button>}s, html)
      assert button =~ ~s(type="button")
      assert button =~ ~s(class="code-block-action")
      assert button =~ ~s(aria-label="Copier")
      assert button =~ ~s(data-copy-label="Copier" data-copied-label="Copié")
      assert button =~ "ignore_attrs"
      assert button =~ ~s(<span class="hero-square-2-stack" data-icon="copy" aria-hidden="true">)
      assert button =~ ~s(<span class="hero-check" data-icon="copied" aria-hidden="true">)

      assert html =~
               ~s(<span id="cb-status" class="sr-only" aria-live="polite" data-code-block-status phx-update="ignore"></span>)
    end

    test "without a header the actions float as a direct child of the block" do
      assigns = %{}
      html = render(~H|<.code_block id="cb" code="x" />|)
      assert html =~ ~r{data-size="default"[^>]*>\s*<div data-slot="code-block-actions">}
    end

    test "copy={false} renders no button and no status; copy_text goes on the root" do
      assigns = %{}
      html = render(~H|<.code_block id="cb" code="x" copy={false} />|)
      refute html =~ "code-block-copy"
      refute html =~ "code-block-actions"
      refute html =~ "cb-status"

      html = render(~H|<.code_block id="cb" code="x" copy_text="the token" />|)
      assert html =~ ~s(data-copy-text="the token")
    end

    test "actions render before Copy; footer below the code" do
      assigns = %{}

      html =
        render(~H"""
        <.code_block id="cb" code="x" title="Build log">
          <:actions><button type="button" class="code-block-action" aria-label="Wrap lines">W</button></:actions>
          <:footer>Showing the last 50 lines</:footer>
        </.code_block>
        """)

      assert html =~
               ~r{aria-label="Wrap lines">W</button>\s*<button[^>]*data-slot="code-block-copy"}

      assert html =~
               ~r{</pre>\s*<div data-slot="code-block-footer">Showing the last 50 lines</div>}
    end

    test "variant, size, wrap, content_class and rest" do
      assigns = %{}

      html =
        render(~H"""
        <.code_block
          id="err"
          code="boom"
          variant="destructive"
          size="sm"
          wrap
          content_class="max-h-72"
          class="mt-4"
          data-kind="trace"
        />
        """)

      assert html =~ ~s(data-variant="destructive" data-size="sm")
      assert html =~ ~s(class="mt-4" data-kind="trace")
      assert html =~ ~r{<pre [^>]*data-wrap[^>]*class="max-h-72"}
    end
  end
end
