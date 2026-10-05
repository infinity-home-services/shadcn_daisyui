defmodule ShadcnDaisyui.Components.ConversationTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.Components.Conversation

  defp render(template) do
    template |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  describe "message/1" do
    test "renders avatar, header, content, and footer with alignment" do
      assigns = %{}

      html =
        render(~H"""
        <.message align="end">
          <:avatar><span>ME</span></:avatar>
          <:header>Olivia</:header>
          Hello
          <:footer>Delivered</:footer>
        </.message>
        """)

      assert html =~ ~s(data-slot="message" data-align="end")
      assert html =~ ~s(data-slot="message-avatar")
      assert html =~ ~s(data-slot="message-content")
      assert html =~ ~s(data-slot="message-header">Olivia)
      assert html =~ ~s(data-slot="message-footer">Delivered)
      assert html =~ "Hello"
    end

    test "defaults to start and omits empty parts" do
      assigns = %{}
      html = render(~H|<.message>Hi</.message>|)

      assert html =~ ~s(data-align="start")
      refute html =~ "message-avatar"
      refute html =~ "message-header"
      refute html =~ "message-footer"
    end

    test "message_group passes through role/aria for live transcripts" do
      assigns = %{}
      html = render(~H|<.message_group role="log" aria-label="Conversation">x</.message_group>|)
      assert html =~ ~s(data-slot="message-group")
      assert html =~ ~s(role="log")
      assert html =~ ~s(aria-label="Conversation")
    end
  end

  describe "bubble/1" do
    test "renders variant, alignment, and a content surface" do
      assigns = %{}
      html = render(~H|<.bubble variant="muted" align="end">Sure</.bubble>|)

      assert html =~ ~s(data-slot="bubble" data-variant="muted" data-align="end")
      assert html =~ ~s(<div data-slot="bubble-content")
      assert html =~ "Sure"
    end

    test "defaults to the primary (default) variant at start" do
      assigns = %{}
      html = render(~H|<.bubble>Hi</.bubble>|)
      assert html =~ ~s(data-variant="default" data-align="start")
    end

    test "as=button puts rest attrs and type=button on the content" do
      assigns = %{}

      html =
        render(~H"""
        <.bubble variant="tinted" as="button" phx-click="reply">I forgot my password</.bubble>
        """)

      assert html =~ ~r/<button[^>]*data-slot="bubble-content"/
      assert html =~ ~s(phx-click="reply")
      assert html =~ ~s(type="button")
    end

    test "as=a renders a link content element" do
      assigns = %{}
      html = render(~H|<.bubble as="a" href="/docs">Docs</.bubble>|)
      assert html =~ ~r/<a[^>]*data-slot="bubble-content"/
      assert html =~ ~s(href="/docs")
    end

    test "reactions render with side, align, and an accessible label" do
      assigns = %{}

      html =
        render(~H"""
        <.bubble variant="muted">
          Tests passed.
          <:reactions label="Reactions: party popper" side="top" align="start">🎉</:reactions>
        </.bubble>
        """)

      assert html =~ ~s(data-slot="bubble-reactions" data-side="top" data-align="start")
      assert html =~ ~s(role="img")
      assert html =~ ~s(aria-label="Reactions: party popper")
    end

    test "reactions default to bottom/end" do
      assigns = %{}
      html = render(~H|<.bubble>x<:reactions>👍</:reactions></.bubble>|)
      assert html =~ ~s(data-side="bottom" data-align="end")
      refute html =~ ~s(role="img")
    end

    test "bubble_group" do
      assigns = %{}

      assert render(~H|<.bubble_group><.bubble>a</.bubble></.bubble_group>|) =~
               ~s(data-slot="bubble-group")
    end
  end

  describe "marker/1" do
    test "default marker with an icon" do
      assigns = %{}

      html =
        render(~H"""
        <.marker>
          <:icon><span class="hero-magnifying-glass"></span></:icon>
          Explored 4 files
        </.marker>
        """)

      assert html =~ ~r/<div[^>]*data-slot="marker"/
      assert html =~ ~s(data-variant="default")
      assert html =~ ~s(data-slot="marker-icon" aria-hidden="true")
      assert html =~ ~s(data-slot="marker-content")
      assert html =~ "Explored 4 files"
      refute html =~ ~s(role="status")
    end

    test "status + shimmer announce and animate the content" do
      assigns = %{}
      html = render(~H|<.marker status shimmer>Thinking...</.marker>|)

      assert html =~ ~s(role="status")
      assert html =~ ~s(data-slot="marker-content" class="shimmer")
      refute html =~ "marker-icon"
    end

    test "separator and border variants" do
      assigns = %{}

      assert render(~H|<.marker variant="separator">Today</.marker>|) =~
               ~s(data-variant="separator")

      assert render(~H|<.marker variant="border">Row</.marker>|) =~ ~s(data-variant="border")
    end

    test "link and button markers" do
      assigns = %{}
      link = render(~H|<.marker href="/pr/1">View the pull request</.marker>|)
      assert link =~ ~s(<a href="/pr/1")
      assert link =~ ~s(data-slot="marker")

      button = render(~H|<.marker as="button" phx-click="revert">Revert</.marker>|)
      assert button =~ ~r/<button[^>]*data-slot="marker"/
      assert button =~ ~s(type="button")
      assert button =~ ~s(phx-click="revert")
    end
  end
end
