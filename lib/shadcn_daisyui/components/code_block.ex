defmodule ShadcnDaisyui.Components.CodeBlock do
  @moduledoc """
  The code block: code, logs, payloads and diffs, rendered on the server.

      <.code_block id="webhook-payload" code={@payload} title="payload.json" />

  Imported by `use ShadcnDaisyui.Components`.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  @line_variants ~w(default added removed highlighted)

  @doc """
  A block of code, a log, a payload or a diff: shadcn's Code Block. Needs the
  `ShadcnCodeBlock` hook (or `initShadcnDaisyui()` in a dead view) for the copy
  button.

      <.code_block id="webhook-payload" code={@payload} title="payload.json" icon="hero-document-text" />

  `code` is split into lines and HTML-escaped (one trailing newline is
  dropped). There is no syntax highlighting: the text renders in the theme's
  monospace font. `line_numbers` numbers the lines from `start_line`;
  `highlight` tints lines by those numbers (`highlight={[42]}`, ranges work:
  `[3, 7..9]`); `wrap` wraps long lines instead of scrolling sideways.

      <.code_block id="import-errors" code={@csv} line_numbers start_line={40} highlight={[42]} />

  Cap the height with `content_class` (`content_class="max-h-72"`): the block
  scrolls inside, its edges fade while there is more to scroll to (in browsers
  with scroll-driven animations; elsewhere it just scrolls). The scroll region
  is focusable (`tabindex="0"`) so it scrolls from the keyboard, and is named
  by the title (or `label`, default "Code").

  ## Lines with variants (diffs)

  `lines` instead of `code` gives each line a variant: `:added` and `:removed`
  get a `+` / `−` marker and a tint (never colour alone), `:highlighted` a tint.
  An item is a string, `{variant, text}`, or pre-highlighted HTML (see below).
  Build the list in Elixir (a literal `{` inside a HEEx attribute would open an
  expression):

      change = [
        ~s({),
        {:removed, ~s(  "status": "open",)},
        {:added, ~s(  "status": "paid",)},
        ~s(  "total": "1240.00"),
        ~s(})
      ]

      <.code_block id="status-change" title="Order #1042" lines={@change} />

  Line numbers, markers and the copy button's text never mix: numbers and
  markers are CSS generated content (not selectable, not copied; numbers are
  silent to screen readers, markers read as "Added" / "Removed" - set
  `--code-block-added-label` / `--code-block-removed-label` in your CSS to
  translate them).

  ## Pre-highlighted lines

  A line given as `Phoenix.HTML.safe` (`Phoenix.HTML.raw/1`) renders as-is, so
  an app can highlight on the server and pass one HTML fragment per line. With
  Makeup, highlight each line on its own (a token spanning lines, such as a
  heredoc, loses its colour after the first line, but the markup stays
  balanced):

      lines =
        code
        |> String.split("\\n")
        |> Enum.map(&Phoenix.HTML.raw(Makeup.highlight_inner_html(&1)))

      <.code_block id="snippet" lines={@lines} title="lib/app.ex" />

  Only pass HTML you produced from trusted output (the highlighter escapes the
  source); the token colours come from your own CSS (e.g. Makeup's stylesheet
  or rules on its token classes using theme tokens). Variants still apply:
  `{:added, Phoenix.HTML.raw(html)}`.

  ## Header, actions, footer

  `title` (a filename or a label; truncates) with an optional heroicon `icon`
  puts a header above the code with the copy button at its end. Without a
  title the copy button floats at the top end, showing on hover or focus (always
  on touch screens). `<:actions>` adds buttons before Copy - use the
  `code-block-action` class for a matching 24px icon button, `aria-pressed` for
  a toggle:

      <.code_block id="build-log" code={@log} title="Build log" wrap={@wrap}>
        <:actions>
          <button type="button" class="code-block-action" aria-label="Wrap lines"
            aria-pressed={to_string(@wrap)} phx-click="toggle_wrap">
            <span class="hero-arrow-uturn-left" aria-hidden="true"></span>
          </button>
        </:actions>
        <:footer><.link href={~p"/imports/42/log"} class="btn btn-ghost btn-xs">Download full log</.link></:footer>
      </.code_block>

  `variant="destructive"` for error output, `size="sm"` (12px text, tighter
  padding) for compact output inside a card, a sheet or a chat reply.

  The copy button copies every line's plain text joined with newlines (no
  numbers, no markers, highlighting stripped), or `copy_text` when given. It
  turns into a check for 2 seconds and a polite live region says "Copied"; the
  block then dispatches a bubbling `code-block:copied` DOM event (`detail.text`).
  `copy={false}` drops it.
  """
  attr(:id, :string, required: true)
  attr(:code, :string, default: nil, doc: "the text: split into lines, HTML-escaped")

  attr(:lines, :list,
    default: [],
    doc:
      "instead of code: strings, {variant, text} (:added, :removed, :highlighted) or Phoenix.HTML.raw/1 lines"
  )

  attr(:title, :string, default: nil, doc: "a filename or label in the header")

  attr(:icon, :string,
    default: nil,
    doc: "heroicon class before the title, e.g. hero-command-line"
  )

  attr(:label, :string,
    default: nil,
    doc: "names the scroll region (default: the title, or \"Code\")"
  )

  attr(:variant, :string, default: "default", values: ~w(default destructive))
  attr(:size, :string, default: "default", values: ~w(default sm))
  attr(:line_numbers, :boolean, default: false)
  attr(:start_line, :integer, default: 1, doc: "the first line's number")
  attr(:highlight, :list, default: [], doc: "line numbers (or ranges) to tint")
  attr(:wrap, :boolean, default: false, doc: "wrap long lines instead of scrolling sideways")
  attr(:copy, :boolean, default: true, doc: "show the copy button")
  attr(:copy_text, :string, default: nil, doc: "what Copy copies (default: the lines' text)")
  attr(:copy_label, :string, default: "Copy")
  attr(:copied_label, :string, default: "Copied")
  attr(:content_class, :any, default: nil, doc: "on the scroll region, e.g. max-h-72")
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:actions, doc: "buttons before Copy (class code-block-action)")
  slot(:footer, doc: "a row under the code, e.g. a Show more or Download button")

  def code_block(assigns) do
    assigns =
      assigns
      |> assign(:rows, rows(assigns))
      |> assign(:header?, assigns.title not in [nil, ""])
      |> assign(:actions?, assigns.copy or assigns.actions != [])

    ~H"""
    <div
      id={@id}
      phx-hook="ShadcnCodeBlock"
      data-slot="code-block"
      data-variant={@variant}
      data-size={@size}
      data-copy-text={@copy_text}
      class={@class}
      {@rest}
    >
      <div :if={@header?} data-slot="code-block-header">
        <div id={"#{@id}-title"} data-slot="code-block-title">
          <span :if={@icon} class={@icon} aria-hidden="true"></span>{@title}
        </div>
        <.code_block_actions
          :if={@actions?}
          actions={@actions}
          copy={@copy}
          copy_label={@copy_label}
          copied_label={@copied_label}
        />
      </div>
      <.code_block_actions
        :if={!@header? and @actions?}
        actions={@actions}
        copy={@copy}
        copy_label={@copy_label}
        copied_label={@copied_label}
      />
      <pre
        id={"#{@id}-content"}
        data-slot="code-block-content"
        data-wrap={@wrap}
        data-numbered={@line_numbers}
        role="region"
        aria-labelledby={@header? && !@label && "#{@id}-title"}
        aria-label={(!@header? || @label) && (@label || "Code")}
        tabindex="0"
        dir="ltr"
        class={@content_class}
      ><code data-slot="code-block-code"><span
          :for={row <- @rows}
          data-slot="code-block-line"
          data-variant={row.variant}
          data-line={row.number}
        ><span data-slot="code-block-line-content">{row.content}</span></span></code></pre>
      <div :if={@footer != []} data-slot="code-block-footer">{render_slot(@footer)}</div>
      <span
        :if={@copy}
        id={"#{@id}-status"}
        class="sr-only"
        aria-live="polite"
        data-code-block-status
        phx-update="ignore"
      ></span>
    </div>
    """
  end

  attr(:actions, :list, required: true)
  attr(:copy, :boolean, required: true)
  attr(:copy_label, :string, required: true)
  attr(:copied_label, :string, required: true)

  defp code_block_actions(assigns) do
    ~H"""
    <div data-slot="code-block-actions">
      {render_slot(@actions)}
      <button
        :if={@copy}
        type="button"
        class="code-block-action"
        data-slot="code-block-copy"
        aria-label={@copy_label}
        data-copy-label={@copy_label}
        data-copied-label={@copied_label}
        phx-mounted={JS.ignore_attributes(["data-copied", "aria-label"])}
      >
        <span class="hero-square-2-stack" data-icon="copy" aria-hidden="true"></span>
        <span class="hero-check" data-icon="copied" aria-hidden="true"></span>
      </button>
    </div>
    """
  end

  # One map per rendered line: its number (only with line numbers), its
  # variant (nil = default, so plain lines carry no attribute) and its content.
  # An empty line holds a newline (as an entity, so the markup stays on one
  # line) so a selection copied across it keeps the blank line.
  defp rows(assigns) do
    highlight = highlighted(assigns.highlight)

    assigns
    |> line_items()
    |> Enum.with_index(assigns.start_line)
    |> Enum.map(fn {{variant, content}, number} ->
      variant = variant || (MapSet.member?(highlight, number) && "highlighted") || "default"

      %{
        number: assigns.line_numbers && number,
        variant: variant != "default" && variant,
        content: if(blank?(content), do: {:safe, "&#10;"}, else: content)
      }
    end)
  end

  defp line_items(%{code: code}) when is_binary(code) do
    code
    |> String.replace(~r/\r\n?/, "\n")
    |> String.replace_suffix("\n", "")
    |> String.split("\n")
    |> Enum.map(&{nil, &1})
  end

  defp line_items(%{lines: lines}), do: Enum.map(lines, &line_item/1)

  defp line_item({:safe, _} = html), do: {nil, html}
  defp line_item(text) when is_binary(text), do: {nil, text}

  defp line_item({variant, content} = item) do
    variant = to_string(variant)

    if variant in @line_variants and (is_binary(content) or match?({:safe, _}, content)) do
      {variant, content}
    else
      raise ArgumentError,
            "code_block lines: expected a string, Phoenix.HTML.raw/1 or {variant, text} " <>
              "with a variant in #{inspect(@line_variants)}, got: #{inspect(item)}"
    end
  end

  defp line_item(other) do
    raise ArgumentError,
          "code_block lines: expected a string, Phoenix.HTML.raw/1 or {variant, text}, got: " <>
            inspect(other)
  end

  defp highlighted(list) do
    list
    |> Enum.flat_map(fn
      %Range{} = range -> Enum.to_list(range)
      n when is_integer(n) -> [n]
    end)
    |> MapSet.new()
  end

  defp blank?(""), do: true
  defp blank?({:safe, iodata}), do: IO.iodata_length(iodata) == 0
  defp blank?(_), do: false
end
