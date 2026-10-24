defmodule ShadcnDaisyuiDemoWeb.ChatLiveTest do
  @moduledoc """
  `/lab/chat`, driven through LiveViewTest: the transcript is a stream in
  `<.message_scroller>` (older messages prepended, a reset for a new chat),
  a question goes in as an anchor with the reply after it, the reply streams
  in from `start_async/3` (busy, its steps, then the summary rows and the
  sources), Stop cancels it, and files attached in the composer show on the
  question. Plus the three gallery pages.

  Not async: the Stop test slows the made-up assistant down through the
  application env.
  """
  use ShadcnDaisyuiDemoWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  defp rows(html),
    do:
      ~r/id="(messages-\d+)" data-slot="message-scroller-item"/
      |> Regex.scan(html)
      |> Enum.map(&List.last/1)

  defp ask(view, text),
    do: view |> form("#chat-form", prompt: %{text: text}) |> render_submit()

  defp slow_assistant(_context) do
    previous = Application.get_env(:shadcn_daisyui_demo, :chat_delay)
    Application.put_env(:shadcn_daisyui_demo, :chat_delay, %{step: 5_000, chunk: 5_000})
    on_exit(fn -> Application.put_env(:shadcn_daisyui_demo, :chat_delay, previous) end)
  end

  describe "the page" do
    test "the app shell, the scroller over the last messages, the composer", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/lab/chat")

      assert html =~ ~s(class="app-shell-page" data-fill)

      assert has_element?(
               view,
               "#chat[phx-hook=ShadcnMessageScroller][data-default-position=last-anchor]"
             )

      assert has_element?(
               view,
               "#chat-viewport[role=region][aria-label='Conversation with the assistant']"
             )

      assert has_element?(view, "#chat-items[phx-update=stream]")
      assert has_element?(view, "#chat [role=log][aria-busy=false]")

      # the last three turns of the earlier conversation; questions are anchors
      assert rows(html) == Enum.map(7..12, &"messages-#{&1}")
      assert has_element?(view, "#messages-11[data-scroll-anchor=true]")
      assert has_element?(view, "#messages-12[data-scroll-anchor=false]")
      assert has_element?(view, "#messages-12", "Start with Copper Kettle")
      assert has_element?(view, "#load-earlier", "Load earlier messages")

      assert has_element?(view, "#composer[phx-hook=ShadcnPromptInput]")

      assert has_element?(
               view,
               "#composer textarea[name='prompt[text]'][aria-label='Ask the assistant']"
             )

      assert has_element?(view, "#composer-submit[type=submit][aria-label=Send]")
      assert has_element?(view, "#composer [data-prompt-suggestion='Which orders are overdue?']")
      assert has_element?(view, "#composer label[data-slot=prompt-input-attach]")
    end

    test "Load earlier messages prepends the older ones", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/lab/chat")

      html = view |> element("#load-earlier") |> render_click()
      assert rows(html) == Enum.map(1..12, &"messages-#{&1}")
      assert has_element?(view, "#messages-1", "How many orders came in this week?")
      # nothing older left
      refute has_element?(view, "#load-earlier")
    end

    test "New chat empties the transcript", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/lab/chat")

      html = view |> element("#new-chat") |> render_click()
      assert rows(html) == []
      refute has_element?(view, "#load-earlier")
    end
  end

  describe "asking" do
    test "the question is an anchor; the reply streams in, then shows its steps and sources",
         %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/lab/chat")

      html = ask(view, "Which orders are overdue?")
      assert rows(html) |> Enum.take(-2) == ["messages-13", "messages-14"]

      assert has_element?(
               view,
               "#messages-13[data-scroll-anchor=true]",
               "Which orders are overdue?"
             )

      html = render_async(view)
      assert has_element?(view, "#chat [role=log][aria-busy=false]")
      assert has_element?(view, "#composer-submit[type=submit][aria-label=Send]")
      assert has_element?(view, "#messages-14", "orders are overdue")
      assert has_element?(view, "#messages-14", "Want me to draft reminders for them?")

      # the steps fold into one row; the sources are another, linking to the orders
      assert has_element?(
               view,
               "#msg-14-steps-trigger[aria-expanded=false]",
               "Worked through 2 steps"
             )

      assert has_element?(view, "#msg-14-steps-detail", "Searched 240 orders")
      assert has_element?(view, "#msg-14-steps-detail", "overdue invoices")
      assert has_element?(view, "#msg-14-sources-trigger", "Used 3 sources")

      assert has_element?(
               view,
               "#msg-14-sources-detail a[data-slot=trace-link][href^='/lab/data-table/']"
             )

      assert html =~ ~r/From order #\d+, order #\d+ and order #\d+\./
      # the field was reset for the next question
      assert has_element?(view, "#composer textarea", "")
      refute view |> element("#composer textarea") |> render() =~ "overdue"
    end

    test "an empty question isn't sent", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/lab/chat")
      before = rows(html)
      assert rows(ask(view, "   ")) == before
    end

    test "a file attached in the composer shows on the question", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/lab/chat")

      pdf = %{
        name: "invoice-1040.pdf",
        content: String.duplicate("x", 2_000),
        type: "application/pdf"
      }

      input = file_input(view, "#chat-form", :files, [pdf])
      render_upload(input, "invoice-1040.pdf")

      assert has_element?(
               view,
               "#composer [data-slot=prompt-input-attachments] [data-slot=attachment]",
               "invoice-1040.pdf"
             )

      assert has_element?(view, "#composer [aria-label='Remove invoice-1040.pdf']")

      ask(view, "Is this one paid?")
      render_async(view)

      assert has_element?(view, "#messages-13 [data-slot=attachment]", "invoice-1040.pdf")
      assert has_element?(view, "#messages-13 [data-slot=attachment]", "2 KB")
      refute has_element?(view, "#composer [data-slot=prompt-input-attachments]")
    end
  end

  test "a file still uploading stays in the composer for the next question", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/lab/chat")

    pdf = %{name: "big.pdf", content: String.duplicate("x", 4_000), type: "application/pdf"}
    input = file_input(view, "#chat-form", :files, [pdf])
    render_upload(input, "big.pdf", 50)

    ask(view, "Which orders are overdue?")
    render_async(view)

    assert has_element?(view, "#messages-13", "Which orders are overdue?")
    refute has_element?(view, "#messages-13 [data-slot=attachment]")
    assert has_element?(view, "#composer [data-slot=attachment][data-state=uploading]", "big.pdf")
  end

  describe "while the reply streams" do
    setup :slow_assistant

    test "busy until it's done: aria-busy, Stop instead of Send, no suggestions", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/lab/chat")

      ask(view, "Who are our biggest customers?")

      assert has_element?(view, "#chat [role=log][aria-busy=true]")
      assert has_element?(view, "#messages-14 [data-slot=marker][role=status]", "Thinking…")
      assert has_element?(view, "#composer[data-busy]")
      assert has_element?(view, "#composer-submit[type=button][aria-label=Stop][phx-click=stop]")
      refute has_element?(view, "#composer [data-prompt-suggestion]")

      # a second question waits for this one
      html = ask(view, "And the smallest?")
      assert rows(html) |> Enum.take(-2) == ["messages-13", "messages-14"]
    end

    test "Stop cancels the reply", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/lab/chat")

      ask(view, "Summarize Summit Outfitters")
      view |> element("#composer-submit") |> render_click()

      assert has_element?(view, "#chat [role=log][aria-busy=false]")
      assert has_element?(view, "#messages-14 [data-slot=message-footer]", "Stopped")
      assert has_element?(view, "#composer-submit[type=submit][aria-label=Send]")
      # a step arriving after Stop is dropped
      send(view.pid, {:reply, 14, {:text, "late words"}})
      refute render(view) =~ "late words"
    end
  end

  describe "the gallery pages" do
    test "message scroller", %{conn: conn} do
      html = conn |> get(~p"/docs/components/message-scroller") |> html_response(200)

      assert html =~ "Message Scroller"
      assert html =~ ~s(data-slot="message-scroller")
      assert html =~ "Requires JavaScript"
      assert html =~ ".defaultScrollAnchor(.bottom)"

      for title <- ["Default", "Opening at the last turn", "Streaming"] do
        assert html =~ ~r{>\s*#{title}\s*</h[23]>}
      end
    end

    test "trace", %{conn: conn} do
      html = conn |> get(~p"/docs/components/trace") |> html_response(200)

      assert html =~ ~s(data-slot="trace")
      assert html =~ ~s(data-slot="trace-collapsible-trigger")
      assert html =~ "symbolEffect"

      for title <- ["Steps", "Tool calls", "Sources", "Plan", "Whole turn"] do
        assert html =~ ~r{>\s*#{title}\s*</h[23]>}
      end

      # the code tab is plain HTML: no LiveView wiring
      refute html =~ "ignore_attrs"
    end

    test "prompt input", %{conn: conn} do
      html = conn |> get(~p"/docs/components/prompt-input") |> html_response(200)

      assert html =~ ~s(data-slot="prompt-input")
      assert html =~ "Requires JavaScript"
      assert html =~ ".onSubmit"

      for title <- ["Default", "Suggestions", "Busy", "Attachments", "Disabled"] do
        assert html =~ ~r{>\s*#{title}\s*</h[23]>}
      end
    end

    test "they sit in the Conversation group", %{conn: _conn} do
      group = Enum.find(ShadcnDaisyuiDemoWeb.Catalog.groups(), &(&1.title == "Conversation"))
      slugs = Enum.map(group.components, & &1.slug)
      assert "message-scroller" in slugs
      assert "trace" in slugs
      assert "prompt-input" in slugs
    end
  end
end
