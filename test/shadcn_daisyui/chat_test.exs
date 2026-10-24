defmodule ShadcnDaisyui.Components.ChatTest do
  # The AI chat parts of ShadcnDaisyui.Components.Conversation:
  # <.message_scroller>, <.trace> / <.trace_line> and <.prompt_input>. The
  # behaviour is covered in headless Chrome (js/message_scroller_browser_test,
  # js/prompt_input_browser_test); these pin the markup the hooks and the CSS
  # rely on, and the ARIA.
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.Components.Conversation

  defp render(template), do: template |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()

  # every opening tag carrying `needle`, in document order
  defp tags(html, needle) do
    ~r/<[a-z][^>]*>/
    |> Regex.scan(html)
    |> List.flatten()
    |> Enum.filter(&String.contains?(&1, needle))
  end

  defp tag(html, needle) do
    case tags(html, needle) do
      [first | _] -> first
      [] -> flunk("no tag with #{needle} in:\n#{html}")
    end
  end

  # an attribute's value on each tag carrying `needle` (nil where absent)
  defp values(html, needle, name) do
    for t <- tags(html, needle) do
      case Regex.run(~r/\s#{name}(?:="([^"]*)")?[\s>]/, t) do
        [_, value] -> value
        [_] -> ""
        nil -> nil
      end
    end
  end

  @messages [
    %{id: 1, role: :user, text: "Which orders are overdue?"},
    %{id: 2, role: :assistant, text: "Three: #1040, #1034 and #1025."},
    %{id: 3, role: :user, text: "Email Summit Outfitters."}
  ]

  describe "message_scroller/1" do
    test "a labelled, focusable viewport around a log of keyed rows" do
      assigns = %{messages: @messages}

      html =
        render(~H"""
        <.message_scroller id="chat" items={@messages} anchor={&(&1.role == :user)} busy :let={m}>
          <p>{m.text}</p>
        </.message_scroller>
        """)

      root = tag(html, ~s(id="chat"))
      assert root =~ ~s(data-slot="message-scroller")
      assert root =~ ~s(phx-hook="ShadcnMessageScroller")
      assert root =~ ~s(data-default-position="end")
      assert root =~ ~s(data-follow="true")
      assert root =~ ~s(data-peek="64")
      # the hook owns these once mounted: LiveView patches leave them alone
      assert root =~ "ignore_attrs"

      viewport = tag(html, ~s(id="chat-viewport"))
      assert viewport =~ ~s(data-slot="message-scroller-viewport")
      assert viewport =~ ~s(role="region")
      assert viewport =~ ~s(aria-label="Messages")
      assert viewport =~ ~s(tabindex="0")

      log = tag(html, ~s(data-slot="message-scroller-content"))
      assert log =~ ~s(role="log")
      assert log =~ ~s(aria-relevant="additions")
      assert log =~ ~s(aria-busy="true")

      assert values(html, ~s(data-slot="message-scroller-item"), "id") ==
               ["chat-1", "chat-2", "chat-3"]

      assert values(html, ~s(data-slot="message-scroller-item"), "data-scroll-anchor") ==
               ["true", "false", "true"]

      assert html =~ "Three: #1040, #1034 and #1025."
      # a list isn't a stream
      refute tag(html, ~s(id="chat-items")) =~ "phx-update"
      # the order: viewport > log > items > rows, then the spacer under the log
      assert html =~
               ~r/id="chat-viewport".*data-slot="message-scroller-content".*id="chat-items".*data-slot="message-scroller-item"/s

      assert tag(html, ~s(data-slot="message-scroller-spacer")) =~ ~s(aria-hidden="true")

      assert html =~
               ~r{</div>\s*</div>\s*<div data-slot="message-scroller-spacer"}
    end

    test "not busy: aria-busy=false" do
      assigns = %{messages: @messages}

      html =
        render(
          ~H|<.message_scroller id="c" items={@messages} :let={m}>{m.text}</.message_scroller>|
        )

      assert tag(html, ~s(role="log")) =~ ~s(aria-busy="false")
    end

    test "hidden until positioned, except when it opens at the start" do
      assigns = %{messages: @messages}

      html =
        render(
          ~H|<.message_scroller id="c" items={@messages} :let={m}>{m.text}</.message_scroller>|
        )

      assert tag(html, ~s(id="c")) =~ "data-pending-scroll"
      assert tag(html, ~s(id="c-viewport")) =~ "data-pending-scroll"

      html =
        render(~H"""
        <.message_scroller id="c" items={@messages} default_position="start" :let={m}>
          {m.text}
        </.message_scroller>
        """)

      refute html =~ ~r/\sdata-pending-scroll[\s>]/

      html =
        render(~H"""
        <.message_scroller id="c" items={@messages} default_position="last-anchor" :let={m}>
          {m.text}
        </.message_scroller>
        """)

      assert tag(html, ~s(id="c")) =~ ~s(data-default-position="last-anchor")
      assert tag(html, ~s(id="c-viewport")) =~ "data-pending-scroll"
    end

    test "the scroll-to-latest button starts inert, out of the tab order" do
      assigns = %{messages: @messages}

      html =
        render(
          ~H|<.message_scroller id="c" items={@messages} :let={m}>{m.text}</.message_scroller>|
        )

      button = tag(html, ~s(data-slot="message-scroller-button"))
      assert button =~ ~r/^<button /
      assert button =~ ~s(id="c-to-end")
      assert button =~ ~s(type="button")
      assert button =~ ~s(data-direction="end")
      assert button =~ ~s(data-active="false")
      assert button =~ ~r/\sinert[\s>]/
      assert button =~ ~s(tabindex="-1")
      assert button =~ ~s(aria-controls="c-viewport")
      assert button =~ "ignore_attrs"
      assert html =~ ~s(<span class="sr-only">Scroll to latest message</span>)

      html =
        render(~H"""
        <.message_scroller id="c" items={@messages} button="both" start_label="Back to top" :let={m}>
          {m.text}
        </.message_scroller>
        """)

      assert values(html, ~s(data-slot="message-scroller-button"), "data-direction") ==
               ["start", "end"]

      assert html =~ "Back to top"

      html =
        render(~H"""
        <.message_scroller id="c" items={@messages} button="none" :let={m}>{m.text}</.message_scroller>
        """)

      refute html =~ "message-scroller-button"
    end

    test "above and below render inside the log, around the rows" do
      assigns = %{messages: @messages}

      html =
        render(~H"""
        <.message_scroller
          id="c"
          items={@messages}
          follow={false}
          peek={32}
          label="Chat with Pat"
          :let={m}
        >
          <:above><button>Load earlier messages</button></:above>
          {m.text}
          <:below><span>Pat is typing…</span></:below>
        </.message_scroller>
        """)

      assert html =~
               ~r/role="log"[^>]*>\s*<div data-slot="message-scroller-above"><button>Load earlier messages<\/button><\/div>\s*<div id="c-items".*<div data-slot="message-scroller-below"><span>Pat is typing…<\/span><\/div>\s*<\/div>/s

      assert tag(html, ~s(id="c")) =~ ~s(data-follow="false")
      assert tag(html, ~s(id="c")) =~ ~s(data-peek="32")
      assert tag(html, ~s(id="c-viewport")) =~ ~s(aria-label="Chat with Pat")
    end

    test "a stream: phx-update=stream, keyed by the stream's dom ids" do
      stream =
        Phoenix.LiveView.LiveStream.new(:messages, "ref", @messages, [])
        |> Phoenix.LiveView.LiveStream.mark_consumable()

      assigns = %{stream: stream}

      html =
        render(~H"""
        <.message_scroller
          id="c"
          items={@stream}
          anchor={fn {_id, m} -> m.role == :user end}
          :let={{_id, m}}
        >
          {m.text}
        </.message_scroller>
        """)

      assert tag(html, ~s(id="c-items")) =~ ~s(phx-update="stream")

      assert values(html, ~s(data-slot="message-scroller-item"), "id") ==
               ["messages-1", "messages-2", "messages-3"]

      assert values(html, ~s(data-slot="message-scroller-item"), "data-scroll-anchor") ==
               ["true", "false", "true"]
    end

    test "item_id keys rows without an id; a list row without one raises" do
      assigns = %{rows: [%{key: "a", text: "Hi"}]}

      html =
        render(~H"""
        <.message_scroller id="c" items={@rows} item_id={&"c-#{&1.key}"} :let={r}>
          {r.text}
        </.message_scroller>
        """)

      assert values(html, ~s(data-slot="message-scroller-item"), "id") == ["c-a"]

      assert_raise ArgumentError, ~r/pass `item_id`/, fn ->
        render(~H|<.message_scroller id="c" items={@rows} :let={r}>{r.text}</.message_scroller>|)
      end
    end
  end

  describe "trace/1" do
    test "lines: a list of rows with status, icon, title and description" do
      assigns = %{}

      html =
        render(~H"""
        <.trace>
          <:line icon="hero-check">Searched 240 orders</:line>
          <:line icon="hero-check" description="3 files">Read the customer file</:line>
          <:line status="running" icon="hero-sparkles">Checking the invoices</:line>
          <:line status="pending">Write the summary</:line>
          <:line status="error" icon="hero-x-circle">Failed to send the email</:line>
        </.trace>
        """)

      assert tag(html, ~s(data-slot="trace")) =~ ~s(role="list")
      assert values(html, ~s(data-slot="trace-item"), "role") == List.duplicate("listitem", 5)

      assert values(html, ~s(data-slot="trace-line"), "data-status") ==
               [nil, nil, "running", "pending", "error"]

      # icons are decoration; the title is the name
      assert values(html, ~s(data-slot="trace-icon"), "aria-hidden") == List.duplicate("true", 4)
      assert html =~ ~r/data-slot="trace-icon" aria-hidden="true"><span class="hero-sparkles">/
      assert html =~ ~s(<span data-slot="trace-description">3 files</span>)
      # only the running title shimmers
      assert values(html, ~s(data-slot="trace-title"), "class") ==
               ["", "", "shimmer", "", ""]

      assert html =~ ~r/class="shimmer">\s*Checking the invoices/
      # plain rows are text, not tab stops
      refute html =~ ~r/<(button|a)[\s>]/
    end

    test "a source line is a link; a new tab says so" do
      assigns = %{}

      html =
        render(~H"""
        <.trace>
          <:line icon="hero-document-text" navigate="/orders/1040">Order #1040</:line>
          <:line icon="hero-globe-alt" href="https://example.test/terms" target="_blank">
            Payment terms
          </:line>
        </.trace>
        """)

      assert values(html, ~s(data-slot="trace-link"), "href") ==
               ["/orders/1040", "https://example.test/terms"]

      assert values(html, ~s(data-slot="trace-link"), "target") == [nil, "_blank"]
      assert html =~ ~r/<a [^>]*data-slot="trace-link"[^>]*>\s*<span data-slot="trace-line"/
      assert html =~ ~s{<span class="sr-only"> (opens in a new tab)</span>}
    end

    test "a row with detail is a disclosure button that controls it" do
      assigns = %{}

      html =
        render(~H"""
        <.trace>
          <.trace_line id="steps" status="running">
            <:icon><span class="hero-list-bullet"></span></:icon>
            Working
            <:description>3 steps</:description>
            <:detail>
              <.trace>
                <.trace_line id="steps-search" open>
                  Searched 240 orders
                  <:detail>12 overdue</:detail>
                </.trace_line>
              </.trace>
            </:detail>
          </.trace_line>
        </.trace>
        """)

      assert tag(html, ~s(id="steps")) =~ ~s(data-slot="trace-collapsible")
      trigger = tag(html, ~s(id="steps-trigger"))
      assert trigger =~ ~r/^<button /
      assert trigger =~ ~s(type="button")
      assert trigger =~ ~s(data-slot="trace-collapsible-trigger")
      assert trigger =~ ~s(aria-expanded="false")
      assert trigger =~ ~s(aria-controls="steps-detail")
      # the reader's choice survives LiveView patches
      assert trigger =~ "ignore_attrs"
      assert trigger =~ "aria-expanded"

      assert html =~
               ~r/id="steps-trigger"[^>]*>\s*<span data-slot="trace-line" data-status="running">.*<span data-slot="trace-icon" data-chevron aria-hidden="true">\s*<span class="hero-chevron-right">/s

      assert tag(html, ~s(id="steps-detail")) =~ ~s(data-slot="trace-collapsible-content")

      assert html =~
               ~r/id="steps-detail"[^>]*>\s*<div data-slot="trace-collapsible-clip">\s*<div data-slot="trace-collapsible-content-inner">/

      # nested, starting open
      assert tag(html, ~s(id="steps-search-trigger")) =~ ~s(aria-expanded="true")
      assert html =~ "12 overdue"
    end

    test "extra attributes go on the button, the link, or a plain row's item" do
      assigns = %{}

      html =
        render(~H"""
        <.trace>
          <.trace_line data-step="plain">Searched</.trace_line>
          <.trace_line href="/orders" data-step="link">Orders</.trace_line>
          <.trace_line id="d" data-step="button">Ran <:detail>ok</:detail></.trace_line>
        </.trace>
        """)

      assert tag(html, ~s(data-step="plain")) =~ ~s(data-slot="trace-item")
      assert tag(html, ~s(data-step="link")) =~ ~s(data-slot="trace-link")
      assert tag(html, ~s(data-step="button")) =~ ~s(data-slot="trace-collapsible-trigger")
    end

    test "a row with detail needs an id" do
      assigns = %{}

      assert_raise ArgumentError, ~r/needs an `id`/, fn ->
        render(~H"""
        <.trace_line>
          Searched
          <:detail>…</:detail>
        </.trace_line>
        """)
      end
    end
  end

  describe "prompt_input/1" do
    defp prompt_form(params \\ %{"text" => ""}),
      do: Phoenix.Component.to_form(params, as: :prompt)

    test "a labelled field bound to the form, with Send" do
      assigns = %{form: prompt_form()}

      html =
        render(~H"""
        <.prompt_input id="composer" field={@form[:text]} placeholder="Ask anything…" />
        """)

      root = tag(html, ~s(id="composer"))
      assert root =~ ~s(phx-hook="ShadcnPromptInput")
      assert root =~ ~s(data-slot="prompt-input")
      refute root =~ "data-dropzone"
      refute root =~ "data-busy"

      field = tag(html, ~s(data-slot="prompt-input-textarea"))
      assert field =~ ~r/^<textarea /
      assert field =~ ~s(id="prompt_text")
      assert field =~ ~s(name="prompt[text]")
      assert field =~ ~s(aria-label="Message")
      assert field =~ ~s(placeholder="Ask anything…")
      assert field =~ ~s(enterkeyhint="send")
      assert field =~ ~s(rows="1")
      assert html =~ ~r/data-slot="prompt-input-box"[^>]*>\s*<textarea/

      submit = tag(html, ~s(id="composer-submit"))
      assert submit =~ ~s(data-slot="prompt-input-submit")
      assert submit =~ ~s(type="submit")
      assert submit =~ ~s(aria-label="Send")
      assert submit =~ ~s(data-state="idle")
      assert submit =~ "btn-primary"
      # nothing to send yet
      assert submit =~ ~s(aria-disabled="true")
      refute submit =~ "phx-click"
      assert html =~ ~r/id="composer-submit"[^>]*>\s*<span class="hero-arrow-up size-4"/
      # no upload: no attach button, no tiles; no inline handlers
      refute html =~ "prompt-input-attach"
      refute html =~ ~r/\son[a-z]+=/
    end

    test "with text it can send; busy makes the button Stop" do
      assigns = %{form: prompt_form(%{"text" => "Hello"})}

      html = render(~H|<.prompt_input id="c" field={@form[:text]} />|)
      refute tag(html, ~s(id="c-submit")) =~ ~s(aria-disabled="true")
      assert html =~ ~r{>\s*Hello</textarea>}

      html = render(~H|<.prompt_input id="c" field={@form[:text]} busy on_stop="chat:stop" />|)
      assert tag(html, ~s(id="c")) =~ "data-busy"
      submit = tag(html, ~s(id="c-submit"))
      assert submit =~ ~s(type="button")
      assert submit =~ ~s(aria-label="Stop")
      assert submit =~ ~s(data-state="busy")
      assert submit =~ ~s(phx-click="chat:stop")
      assert submit =~ "btn-secondary"
      assert html =~ ~r/id="c-submit"[^>]*>\s*<span class="hero-stop-solid size-4"/

      # Stop is never disabled, even with an empty field
      assigns = %{form: prompt_form()}
      html = render(~H|<.prompt_input id="c" field={@form[:text]} busy />|)
      submit = tag(html, ~s(id="c-submit"))
      refute submit =~ ~s(aria-disabled="true")
      assert submit =~ ~s(phx-click="stop")
    end

    test "suggestions are outline bubble buttons that fill and send" do
      assigns = %{form: prompt_form()}

      html =
        render(~H"""
        <.prompt_input id="c" field={@form[:text]}>
          <:suggestion value="Which orders are overdue?">Overdue orders</:suggestion>
          <:suggestion value="Draft a reminder" send={false} variant="tinted">Draft</:suggestion>
          <:suggestion phx-click="summarize">Summarize</:suggestion>
        </.prompt_input>
        """)

      group = tag(html, ~s(data-slot="prompt-input-suggestions"))
      assert group =~ ~s(role="group")
      assert group =~ ~s(aria-label="Suggestions")

      assert values(html, ~s(data-slot="bubble" ), "data-variant") ==
               ["outline", "tinted", "outline"]

      chips = ~s(data-slot="bubble-content")
      assert values(html, chips, "type") == ["button", "button", "button"]

      assert values(html, chips, "data-prompt-suggestion") ==
               ["Which orders are overdue?", "Draft a reminder", nil]

      assert values(html, chips, "data-send") == [nil, "false", nil]
      assert values(html, chips, "phx-click") == [nil, nil, "summarize"]
      # above the box
      assert html =~ ~r/prompt-input-suggestions.*prompt-input-box/s
    end

    test "an upload adds the attach button, the drop target and the tiles" do
      entry =
        struct!(Phoenix.LiveView.UploadEntry,
          ref: "0",
          upload_ref: "phx-files",
          client_name: "roof.pdf",
          client_size: 2_400_000,
          client_type: "application/pdf",
          progress: 40,
          preflighted?: true,
          valid?: true
        )

      upload = %Phoenix.LiveView.UploadConfig{
        name: :files,
        ref: "phx-files",
        accept: ".pdf",
        max_entries: 3,
        max_file_size: 8_000_000,
        entries: [entry]
      }

      assigns = %{form: prompt_form(), upload: upload}

      html =
        render(~H"""
        <.prompt_input id="c" field={@form[:text]} upload={@upload} on_cancel="cancel-upload" />
        """)

      assert tag(html, ~s(id="c")) =~ ~s(data-dropzone="upload")
      box = tag(html, ~s(data-slot="prompt-input-box"))
      assert box =~ ~s(phx-drop-target="phx-files")
      assert box =~ "data-dropzone-area"

      assert html =~
               ~r/<label data-slot="prompt-input-attach"[^>]*>\s*<input[^>]*id="phx-files"[^>]*type="file"/

      assert html =~ ~s(<span class="sr-only">Attach files</span>)

      # tiles above the text, one list item each
      assert html =~
               ~r/data-slot="prompt-input-attachments" role="list" aria-label="Attached files">\s*<div role="listitem">\s*<div[^>]*data-slot="attachment" data-state="uploading"/

      assert html =~ ~r/prompt-input-attachments.*<textarea/s
      assert html =~ "Uploading · 40%"
      assert html =~ ~s(aria-label="Cancel roof.pdf")
      # with a file attached there is something to send
      refute tag(html, ~s(id="c-submit")) =~ ~s(aria-disabled="true")
      assert tag(html, ~s(id="c-errors")) =~ ~s(aria-live="polite")
    end

    test "upload errors read under the box and describe the field" do
      entries =
        for n <- 1..4 do
          struct!(Phoenix.LiveView.UploadEntry,
            ref: "#{n}",
            upload_ref: "phx-files",
            client_name: "f#{n}.pdf",
            client_size: 10,
            client_type: "application/pdf",
            valid?: true
          )
        end

      upload = %Phoenix.LiveView.UploadConfig{
        name: :files,
        ref: "phx-files",
        accept: ".pdf",
        max_entries: 3,
        max_file_size: 8_000_000,
        entries: entries,
        errors: [{"phx-files", :too_many_files}]
      }

      assigns = %{upload: upload}
      html = render(~H|<.prompt_input id="c" name="text" upload={@upload} />|)

      assert html =~ "Too many files. Choose up to 3."
      assert tag(html, ~s(id="c-input")) =~ ~s(aria-describedby="c-errors")
    end

    test "disabled, and a name instead of a field" do
      assigns = %{}

      html =
        render(~H"""
        <.prompt_input id="c" name="text" value="Hi" disabled label="Ask the assistant" />
        """)

      assert tag(html, ~s(id="c")) =~ "data-disabled"
      field = tag(html, ~s(id="c-input"))
      assert field =~ ~s(name="text")
      assert field =~ ~r/\sdisabled[\s>]/
      assert field =~ ~s(aria-label="Ask the assistant")
      assert tag(html, ~s(id="c-submit")) =~ ~r/\sdisabled[\s>]/
    end
  end
end
