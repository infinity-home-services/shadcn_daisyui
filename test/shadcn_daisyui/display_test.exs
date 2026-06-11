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

  describe "toast_host/1" do
    test "renders the polite status region with the default id" do
      assigns = %{}
      html = render(~H|<.toast_host />|)

      assert html =~ ~s(id="toast-host")
      assert html =~ ~s(role="status")
      assert html =~ ~s(aria-live="polite")
      assert html =~ "toast toast-end toast-bottom"
    end

    test "id is configurable" do
      assigns = %{}
      assert render(~H|<.toast_host id="my-toasts" />|) =~ ~s(id="my-toasts")
    end
  end
end
