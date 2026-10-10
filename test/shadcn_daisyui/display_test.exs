defmodule ShadcnDaisyui.Components.DisplayTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.Components.Display

  defp render(template) do
    template |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  defp count(html, substring) do
    html |> String.split(substring) |> length() |> Kernel.-(1)
  end

  describe "accordion/1" do
    test "single mode renders radios named after the id" do
      assigns = %{}

      html =
        render(~H"""
        <.accordion id="faq">
          <:section title="Is it accessible?" open>Yes.</:section>
          <:section title="Is it styled?">Also yes.</:section>
        </.accordion>
        """)

      assert count(html, ~s(type="radio")) == 2
      assert count(html, ~s(name="faq")) == 2
      refute html =~ ~s(type="checkbox")
      assert html =~ "collapse collapse-arrow"
      assert html =~ "Is it accessible?"
      assert html =~ "collapse-title"
      assert html =~ "collapse-content"
      assert count(html, "checked") == 1
    end

    test "multiple mode renders checkboxes without a shared name" do
      assigns = %{}

      html =
        render(~H"""
        <.accordion id="faq" multiple>
          <:section title="One">1</:section>
          <:section title="Two">2</:section>
        </.accordion>
        """)

      assert count(html, ~s(type="checkbox")) == 2
      refute html =~ ~s(type="radio")
      refute html =~ ~s(name="faq")
    end

    # Other apps depend on this output: an accordion without <:header> or flush
    # must render byte-for-byte as it did before those opt-ins existed (0.16.1).
    test "without header or flush renders exactly the 0.16.1 markup" do
      assigns = %{}

      html =
        render(~H"""
        <.accordion id="faq" class="max-w-lg">
          <:section title="One" open>1</:section>
          <:section title="Two">2</:section>
        </.accordion>
        """)

      assert html ==
               ~s(<div class="card w-full max-w-lg">\n  <div class="card-body py-1">\n    ) <>
                 ~s(<div class="collapse collapse-arrow">\n      <input type="radio" name="faq" checked>\n      ) <>
                 ~s(<div class="collapse-title">One</div>\n      <div class="collapse-content">1</div>\n    ) <>
                 ~s(</div><div class="collapse collapse-arrow">\n      <input type="radio" name="faq">\n      ) <>
                 ~s(<div class="collapse-title">Two</div>\n      <div class="collapse-content">2</div>\n    ) <>
                 ~s(</div>\n  </div>\n</div>)

      html =
        render(~H"""
        <.accordion id="faq" multiple>
          <:section title="One">1</:section>
        </.accordion>
        """)

      assert html ==
               ~s(<div class="card w-full ">\n  <div class="card-body py-1">\n    ) <>
                 ~s(<div class="collapse collapse-arrow">\n      <input type="checkbox">\n      ) <>
                 ~s(<div class="collapse-title">One</div>\n      <div class="collapse-content">1</div>\n    ) <>
                 ~s(</div>\n  </div>\n</div>)
    end

    test "header renders above the rows inside the same card" do
      assigns = %{}

      html =
        render(~H"""
        <.accordion id="faq">
          <:header><h3>Timeline</h3></:header>
          <:section title="One">1</:section>
        </.accordion>
        """)

      assert html =~ ~s(<div class="card w-full )
      assert html =~ ~s(<div class="card-body accordion-header pb-2">)
      assert html =~ ~s(<div class="card-body pt-0 pb-1">)
      refute html =~ "accordion-flush"
      [header, rows] = String.split(html, "card-body pt-0")
      assert header =~ "<h3>Timeline</h3>"
      assert rows =~ "collapse-title"
    end

    test "flush runs the rows edge to edge, with or without a header" do
      assigns = %{}

      html =
        render(~H"""
        <.accordion id="tl" flush multiple>
          <:header><h3>Timeline</h3></:header>
          <:section title="Inquiry received" open>1</:section>
          <:section title="Estimate sent">2</:section>
        </.accordion>
        """)

      assert html =~ ~s(<div class="card w-full accordion-flush">)
      assert html =~ ~s(<div class="card-body accordion-header )
      refute html =~ "pb-2"
      assert html =~ ~s(<div class="accordion-rows">)
      refute html =~ "card-body py-1"
      refute html =~ "card-body pt-0"
      assert count(html, ~s(type="checkbox")) == 2
      assert count(html, "checked") == 1

      html =
        render(~H"""
        <.accordion id="tl" flush>
          <:section title="One">1</:section>
        </.accordion>
        """)

      assert html =~ ~s(<div class="card w-full accordion-flush">)
      refute html =~ "accordion-header"
      assert html =~ ~s(<div class="accordion-rows">)
      assert count(html, ~s(name="tl")) == 1
    end
  end

  describe "avatar/1" do
    test "with src renders an image" do
      assigns = %{}
      html = render(~H|<.avatar src="/u.png" alt="Jane" fallback="JD" />|)

      assert html =~ ~s(<img src="/u.png" alt="Jane">)
      refute html =~ "avatar-placeholder"
      refute html =~ "JD"
    end

    test "without src renders the placeholder fallback" do
      assigns = %{}
      html = render(~H|<.avatar fallback="JD" />|)

      assert html =~ "avatar avatar-placeholder"
      assert html =~ "JD"
      refute html =~ "<img"
      assert html =~ "rounded-full"
      assert html =~ "w-10"
    end

    test "shape and class are configurable" do
      assigns = %{}
      html = render(~H|<.avatar fallback="UI" shape="rounded-lg" class="w-16" />|)

      assert html =~ "rounded-lg w-16"
    end
  end

  describe "avatar_group/1" do
    test "stacks its children" do
      assigns = %{}

      html =
        render(~H"""
        <.avatar_group>
          <.avatar fallback="AB" />
          <.avatar fallback="CD" />
        </.avatar_group>
        """)

      assert html =~ "avatar-group -space-x-3"
      assert count(html, "avatar-placeholder") == 2
    end
  end

  describe "progress/1" do
    test "renders value and max" do
      assigns = %{}
      html = render(~H|<.progress value={60} />|)

      assert html =~ ~s(<progress class="progress w-full" value="60" max="100">)
    end

    test "custom max" do
      assigns = %{}
      assert render(~H|<.progress value={3} max={5} />|) =~ ~s(value="3" max="5")
    end

    test "omitting value renders an indeterminate bar" do
      assigns = %{}
      refute render(~H|<.progress />|) =~ "value="
    end
  end

  describe "skeleton/1" do
    test "renders with sizing classes" do
      assigns = %{}
      assert render(~H|<.skeleton class="h-4 w-48" />|) =~ ~s(class="skeleton h-4 w-48")
    end

    test "defaults to a full-width line" do
      assigns = %{}
      assert render(~H|<.skeleton />|) =~ "skeleton h-4 w-full"
    end
  end

  describe "spinner/1" do
    test "default has no size class" do
      assigns = %{}
      html = render(~H|<.spinner />|)

      assert html =~ ~s(class="loading loading-spinner )
      refute html =~ "loading-sm"
    end

    test "sizes" do
      for size <- ~w(loading-xs loading-sm loading-lg) do
        assigns = %{size: size}
        assert render(~H|<.spinner size={@size} />|) =~ "loading loading-spinner #{size}"
      end
    end
  end

  describe "toaster/1" do
    test "renders the hidden options section wired to the ShadcnToaster hook" do
      assigns = %{}
      html = render(~H|<.toaster />|)

      assert html =~ ~s(id="toaster")
      assert html =~ ~s(phx-hook="ShadcnToaster")
      assert html =~ ~s(phx-update="ignore")
      assert html =~ "data-sonner-section"
      assert html =~ ~s(data-position="bottom-right")
      # the JS-built top-layer toast region carries the label and live region
      assert html =~ ~r/<section[^>]* hidden/
      refute html =~ "aria-live"
    end

    test "options become data attributes the JS reads" do
      assigns = %{}

      html =
        render(~H"""
        <.toaster position="top-center" rich_colors close_button expand duration={6000} />
        """)

      assert html =~ ~s(data-position="top-center")
      assert html =~ ~s(data-rich-colors="true")
      assert html =~ ~s(data-close-button="true")
      assert html =~ ~s(data-expand="true")
      assert html =~ ~s(data-duration="6000")
    end

    test "toast_host/1 (deprecated) still renders a toaster with the old id" do
      assigns = %{}
      html = render(~H|<.toast_host />|)
      assert html =~ ~s(id="toast-host")
      assert html =~ "data-sonner-section"
    end
  end

  describe "push_toast/3" do
    defp pushed(socket) do
      [[event, payload]] = socket.private.live_temp.push_events
      {event, payload}
    end

    defp socket do
      %Phoenix.LiveView.Socket{private: %{live_temp: %{}}}
    end

    test "pushes a shadcn:toast event with message, type, and options" do
      {event, payload} =
        socket()
        |> push_toast("Saved",
          type: :success,
          description: "All changes stored",
          action: %{label: "Undo", event: "undo", value: %{id: 1}, extra: :dropped}
        )
        |> pushed()

      assert event == "shadcn:toast"
      assert payload.message == "Saved"
      assert payload.type == "success"
      assert payload.description == "All changes stored"
      assert payload.action == %{label: "Undo", event: "undo", value: %{id: 1}}
      refute Map.has_key?(payload, :cancel)
    end

    test "type defaults to default" do
      {_, payload} = socket() |> push_toast("Hello") |> pushed()
      assert payload.type == "default"
    end

    test "dismiss one or all" do
      assert {_, %{dismiss: true, id: 7}} = socket() |> push_toast(nil, dismiss: 7) |> pushed()
      assert {_, %{dismiss: true} = all} = socket() |> push_toast(nil, dismiss: true) |> pushed()
      refute Map.has_key?(all, :id)
    end
  end

  describe "item/1" do
    test "renders slots into shadcn data-slot parts" do
      assigns = %{}

      html =
        render(~H"""
        <.item variant="outline" size="sm">
          <:media variant="icon"><span class="hero-shield-check"></span></:media>
          <:title>Two-factor authentication</:title>
          <:description>Verify via email.</:description>
          <:actions><button>Enable</button></:actions>
        </.item>
        """)

      assert html =~ ~s(<div data-slot="item" data-variant="outline" data-size="sm")
      assert html =~ ~s(data-slot="item-media" data-variant="icon")
      assert html =~ ~s(data-slot="item-content")
      assert html =~ ~s(data-slot="item-title">Two-factor authentication)
      assert html =~ ~s(<p data-slot="item-description">Verify via email.)
      assert html =~ ~s(data-slot="item-actions")
      refute html =~ "item-header"
      refute html =~ "item-footer"
    end

    test "defaults to the default variant and size, and omits empty parts" do
      assigns = %{}
      html = render(~H|<.item><:title>Only a title</:title></.item>|)

      assert html =~ ~s(data-variant="default" data-size="default")
      refute html =~ "item-media"
      refute html =~ "item-description"
      refute html =~ "item-actions"
    end

    test "becomes a link with href/navigate/patch" do
      assigns = %{}
      html = render(~H|<.item navigate="/settings"><:title>Settings</:title></.item>|)

      assert html =~ ~s(<a href="/settings")
      assert html =~ ~s(data-phx-link="redirect")
      assert html =~ ~s(data-slot="item")
    end

    test "header and footer render full-width rows" do
      assigns = %{}

      html =
        render(~H"""
        <.item>
          <:header>Header</:header>
          <:title>T</:title>
          <:footer>Footer</:footer>
        </.item>
        """)

      assert html =~ ~s(data-slot="item-header">Header)
      assert html =~ ~s(data-slot="item-footer">Footer)
    end

    test "item_group is a list and item_separator a separator" do
      assigns = %{}

      html =
        render(~H"""
        <.item_group>
          <.item role="listitem"><:title>A</:title></.item>
          <.item_separator />
          <.item role="listitem"><:title>B</:title></.item>
        </.item_group>
        """)

      assert html =~ ~s(role="list" data-slot="item-group")
      assert count(html, ~s(role="listitem")) == 2
      assert html =~ ~s(role="separator")
      assert html =~ ~s(data-slot="item-separator")
    end
  end

  describe "attachment/1" do
    test "renders state, size, orientation and parts" do
      assigns = %{}

      html =
        render(~H"""
        <.attachment state="uploading" size="sm">
          <:media><span class="loading loading-spinner"></span></:media>
          <:title>design-system.zip</:title>
          <:description>Uploading · 64%</:description>
          <:actions>
            <.attachment_action label="Cancel upload">x</.attachment_action>
          </:actions>
        </.attachment>
        """)

      assert html =~
               ~s(data-slot="attachment" data-state="uploading" data-size="sm" data-orientation="horizontal")

      assert html =~ ~s(data-slot="attachment-media" data-variant="icon")
      assert html =~ ~s(data-slot="attachment-title">design-system.zip)
      assert html =~ ~s(data-slot="attachment-description")
      assert html =~ ~s(data-slot="attachment-actions")
      assert html =~ ~s(data-slot="attachment-action")
      assert html =~ ~s(aria-label="Cancel upload")
      assert html =~ ~s(title="Cancel upload")
      assert html =~ ~s(type="button")
    end

    test "defaults to a done, horizontal, default-size tile" do
      assigns = %{}
      html = render(~H|<.attachment><:title>a.pdf</:title></.attachment>|)

      assert html =~ ~s(data-state="done" data-size="default" data-orientation="horizontal")
      refute html =~ "attachment-actions"
      refute html =~ "attachment-trigger"
    end

    test "image media and a labeled full-tile trigger" do
      assigns = %{}

      html =
        render(~H"""
        <.attachment orientation="vertical">
          <:media variant="image"><img src="/a.png" alt="Workspace" /></:media>
          <:trigger label="Preview workspace.png" phx-click="preview" />
        </.attachment>
        """)

      assert html =~ ~s(data-orientation="vertical")
      assert html =~ ~s(data-slot="attachment-media" data-variant="image")
      assert html =~ ~s(data-slot="attachment-trigger")
      assert html =~ ~s(aria-label="Preview workspace.png")
      assert html =~ ~s(phx-click="preview")
      refute html =~ ~s( label="Preview)
    end

    test "attachment_group wraps tiles" do
      assigns = %{}

      html =
        render(
          ~H|<.attachment_group><.attachment><:title>a</:title></.attachment></.attachment_group>|
        )

      assert html =~ ~s(data-slot="attachment-group")
    end
  end

  describe "chip_row/1" do
    test "renders removable chips with the hook and a hidden copy each" do
      assigns = %{}

      html =
        render(~H"""
        <.chip_row id="filters" aria_label="Active filters">
          <:chip value="status:todo" on_remove="remove">Status: Todo</:chip>
          <:chip value="label:bug">Label: Bug</:chip>
        </.chip_row>
        """)

      assert html =~ ~s(phx-hook="ShadcnChipRow")
      assert html =~ ~s(role="group")
      assert html =~ ~s(aria-label="Active filters")
      assert length(Regex.scan(~r/data-chip[\s>]/, html)) == 2
      assert count(html, "data-chip-copy") == 2
      assert count(html, "badge chip badge-secondary") == 4
      assert html =~ ~s(data-value="status:todo")
      assert html =~ ~s(phx-click="remove")
      assert count(html, "data-chip-remove") == 4
      # the remove button is named "Remove" + the chip label
      assert html =~ ~r/aria-labelledby="(filters-chip-v-status-todo-\w+)-remove \1-label"/
      assert html =~ ~r/id="filters-chip-v-status-todo-\w+-label"/
      assert html =~ ~s(aria-controls="filters-overflow")
      assert html =~ ~s(data-more-label="Show {count} more")
    end

    test "remove_label, removable and variant" do
      assigns = %{}

      html =
        render(~H"""
        <.chip_row id="r" variant="outline">
          <:chip remove_label="Remove Olivia">olivia@example.com</:chip>
          <:chip removable={false}>Locked</:chip>
        </.chip_row>
        """)

      assert html =~ ~s(aria-label="Remove Olivia")
      refute html =~ ~s(aria-labelledby="r-chip-0-remove)
      # chip 1 has no remove button in the row or the copy
      refute html =~ "r-chip-1-remove"
      refute html =~ "r-copy-1-remove"
      assert html =~ "badge chip badge-outline"
    end

    test "actions render in a trailing container" do
      assigns = %{}

      html =
        render(~H"""
        <.chip_row id="f">
          <:chip>A</:chip>
          <:action><button type="button" data-chip-row-clear>Clear all</button></:action>
        </.chip_row>
        """)

      assert html =~ "data-chip-row-actions"
      assert html =~ "Clear all"
    end

    test "chips are keyed by value and animate out through phx-remove" do
      assigns = %{}

      html =
        render(~H"""
        <.chip_row id="k">
          <:chip value="bug">Bug</:chip>
          <:chip value="status:open">Open</:chip>
          <:chip value="status-open">Open too</:chip>
          <:chip>No value</:chip>
          <:action><button type="button">Clear all</button></:action>
        </.chip_row>
        """)

      # id-safe values are used as-is; others get a hash so slugs can't collide
      assert html =~ ~s(id="k-chip-v-bug-label")
      assert html =~ ~s(id="k-copy-v-bug-label")
      assert html =~ ~s(id="k-chip-v-status-open-label")
      assert [_] = Regex.scan(~r/id="k-chip-v-status-open-\w+-label"/, html)
      # no value: index key
      assert html =~ ~s(id="k-chip-3-label")
      # every chip, copy and the actions dispatch chip-exit and hold 180ms
      assert count(html, "chip-exit") == 2 * 9
      assert html =~ "&quot;time&quot;:180"
    end
  end

  describe "reveal/1" do
    test "closed by default, data-open when open, content in the track" do
      assigns = %{}
      closed = render(~H|<.reveal>Row</.reveal>|)
      open = render(~H|<.reveal open class="pt-3">Row</.reveal>|)

      assert closed =~ ~s(class="reveal")
      refute closed =~ "data-open"
      assert closed =~ ~s(class="reveal-track")
      refute closed =~ "phx-mounted"
      assert open =~ "data-open"
      assert open =~ ~s(<div class="pt-3">Row</div>)
    end

    test "client reveals keep the browser-owned data-open across patches" do
      assigns = %{}
      html = render(~H|<.reveal id="more" client>Row</.reveal>|)

      assert html =~ ~s(id="more")
      assert html =~ "phx-mounted"
      assert html =~ "ignore_attrs"
      assert html =~ "data-open"
    end
  end
end
