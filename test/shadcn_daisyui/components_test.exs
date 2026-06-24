defmodule ShadcnDaisyui.ComponentsTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.Components

  defp render(template) do
    template |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  defp count(html, substring) do
    html |> String.split(substring) |> length() |> Kernel.-(1)
  end

  describe "badge/1" do
    test "default variant renders badge-primary" do
      assigns = %{}
      html = render(~H|<.badge>New</.badge>|)

      assert html =~ ~s(class="badge badge-primary")
      assert html =~ "New"
    end

    test "secondary variant" do
      assigns = %{}
      html = render(~H|<.badge variant="secondary">Paid</.badge>|)

      assert html =~ "badge-secondary"
      assert html =~ "Paid"
    end

    test "outline variant" do
      assigns = %{}
      assert render(~H|<.badge variant="outline">O</.badge>|) =~ "badge-outline"
    end

    test "destructive variant maps to badge-error" do
      assigns = %{}
      assert render(~H|<.badge variant="destructive">D</.badge>|) =~ "badge-error"
    end

    test "passes custom class and global attributes" do
      assigns = %{}
      html = render(~H|<.badge class="ml-2" data-test="b">X</.badge>|)

      assert html =~ "badge badge-primary ml-2"
      assert html =~ ~s(data-test="b")
    end
  end

  describe "alert/1" do
    test "default variant has no alert-error class" do
      assigns = %{}
      html = render(~H|<.alert>Heads up</.alert>|)

      assert html =~ ~s(role="alert")
      assert html =~ "Heads up"
      refute html =~ "alert-error"
    end

    test "destructive variant adds alert-error" do
      assigns = %{}

      html =
        render(~H"""
        <.alert variant="destructive">
          <:title>Error</:title>
          Your session has expired.
        </.alert>
        """)

      assert html =~ "alert-error"
      assert html =~ "Error"
      assert html =~ "Your session has expired."
      assert html =~ "<h3"
    end

    test "omits title heading when no title slot given" do
      assigns = %{}
      refute render(~H|<.alert>Body only</.alert>|) =~ "<h3"
    end
  end

  describe "card composition" do
    test "card + card_body + card_title + card_description" do
      assigns = %{}

      html =
        render(~H"""
        <.card class="w-96">
          <.card_body>
            <.card_title>Login</.card_title>
            <.card_description>Enter your email below.</.card_description>
            content
          </.card_body>
        </.card>
        """)

      assert html =~ ~s(class="card w-96")
      assert html =~ "card-body"
      assert html =~ ~r/<h3 class="card-title\s*">Login<\/h3>/
      assert html =~ "text-sm text-muted-foreground"
      assert html =~ "Enter your email below."
      assert html =~ "content"
    end
  end

  describe "separator/1" do
    test "horizontal (default) renders only divider" do
      assigns = %{}
      html = render(~H|<.separator />|)

      assert html =~ ~s(class="divider )
      refute html =~ "divider-horizontal"
    end

    test "vertical adds divider-horizontal (daisyUI naming)" do
      assigns = %{}
      assert render(~H|<.separator orientation="vertical" />|) =~ "divider divider-horizontal"
    end
  end

  describe "calendar/1 and date pickers" do
    test "calendar renders the hook and data attribute" do
      assigns = %{}
      html = render(~H|<.calendar id="cal" />|)

      assert html =~ ~s(id="cal")
      assert html =~ ~s(phx-hook="ShadcnCalendar")
      assert html =~ "data-calendar"
    end

    test "date_picker renders hook, trigger, panel, and placeholder" do
      assigns = %{}
      html = render(~H|<.date_picker id="dp" />|)

      assert html =~ ~s(id="dp")
      assert html =~ ~s(phx-hook="ShadcnDatePicker")
      assert html =~ "data-datepicker-trigger"
      assert html =~ "data-datepicker-panel"
      assert html =~ "Pick a date"
    end

    test "date_picker custom placeholder" do
      assigns = %{}
      assert render(~H|<.date_picker id="dp" placeholder="Birthday" />|) =~ "Birthday"
    end

    test "date_range renders hook and range calendar" do
      assigns = %{}
      html = render(~H|<.date_range id="dr" />|)

      assert html =~ ~s(phx-hook="ShadcnDateRange")
      assert html =~ "data-daterange-trigger"
      assert html =~ "data-calendar-range"
      assert html =~ "Pick a date range"
    end
  end

  describe "combobox/1" do
    test "renders id, hook, search input, and options with data-value" do
      assigns = %{}

      html =
        render(~H"""
        <.combobox id="fw" placeholder="Select framework…">
          <:option value="Next.js">Next.js</:option>
          <:option value="Phoenix">Phoenix</:option>
        </.combobox>
        """)

      assert html =~ ~s(id="fw")
      assert html =~ ~s(phx-hook="ShadcnCombobox")
      assert html =~ "data-combobox-search"
      assert html =~ ~s(data-value="Next.js")
      assert html =~ ~s(data-value="Phoenix")
      assert html =~ "Select framework…"
      assert html =~ "data-combobox-empty"
      assert count(html, "combo-item") == 2
    end

    test "emits no hidden input without a name" do
      assigns = %{}

      html =
        render(~H"""
        <.combobox id="fw"><:option value="Next.js">Next.js</:option></.combobox>
        """)

      refute html =~ "data-combobox-input"
    end

    test "form binding emits a hidden input carrying name and value" do
      assigns = %{}

      html =
        render(~H"""
        <.combobox id="fw" name="user[framework]" value="Phoenix">
          <:option value="Next.js">Next.js</:option>
          <:option value="Phoenix">Phoenix</:option>
        </.combobox>
        """)

      assert html =~ ~s(type="hidden")
      assert html =~ "data-combobox-input"
      assert html =~ ~s(name="user[framework]")
      assert html =~ ~s(value="Phoenix")
    end
  end

  describe "select/1" do
    test "renders hook trigger and listbox items" do
      assigns = %{}

      html =
        render(~H"""
        <.select id="fruit" placeholder="Select a fruit">
          <:option value="Apple">Apple</:option>
          <:option value="Banana">Banana</:option>
        </.select>
        """)

      assert html =~ ~s(id="fruit")
      assert html =~ ~s(phx-hook="ShadcnSelect")
      assert html =~ "data-select-trigger"
      assert html =~ "Select a fruit"
      assert count(html, "data-select-item") == 2
      assert html =~ ~s(data-value="Apple")
      assert html =~ ~s(data-value="Banana")
    end

    test "emits no hidden input without a name" do
      assigns = %{}

      html =
        render(~H"""
        <.select id="fruit"><:option value="Apple">Apple</:option></.select>
        """)

      refute html =~ "data-select-input"
    end

    test "form binding emits a hidden input carrying name and value" do
      assigns = %{}

      html =
        render(~H"""
        <.select id="fruit" name="order[fruit]" value="Banana">
          <:option value="Apple">Apple</:option>
          <:option value="Banana">Banana</:option>
        </.select>
        """)

      assert html =~ ~s(type="hidden")
      assert html =~ "data-select-input"
      assert html =~ ~s(name="order[fruit]")
      assert html =~ ~s(value="Banana")
    end
  end

  describe "input_otp/1" do
    test "renders default 6 slots with a separator every 3" do
      assigns = %{}
      html = render(~H|<.input_otp id="otp" />|)

      assert html =~ ~s(phx-hook="ShadcnOtp")
      assert count(html, "otp-slot") == 6
      assert count(html, ">-</span>") == 1
    end

    test "custom length and group" do
      assigns = %{}
      html = render(~H|<.input_otp id="otp" length={4} group={2} />|)

      assert count(html, "otp-slot") == 4
      assert count(html, ">-</span>") == 1
    end

    test "group of 0 renders no separators" do
      assigns = %{}
      html = render(~H|<.input_otp id="otp" length={6} group={0} />|)

      assert count(html, "otp-slot") == 6
      assert count(html, ">-</span>") == 0
    end
  end

  describe "carousel/1" do
    test "renders one carousel-item per slide plus prev/next controls" do
      assigns = %{}

      html =
        render(~H"""
        <.carousel id="c">
          <:slide>one</:slide>
          <:slide>two</:slide>
          <:slide>three</:slide>
        </.carousel>
        """)

      assert html =~ ~s(id="c")
      assert html =~ ~s(phx-hook="ShadcnCarousel")
      assert count(html, "carousel-item") == 3
      assert html =~ "data-carousel-prev"
      assert html =~ "data-carousel-next"
      assert html =~ "one" and html =~ "two" and html =~ "three"
    end
  end

  describe "resizable/1" do
    test "renders both panes and a draggable handle" do
      assigns = %{}

      html =
        render(~H"""
        <.resizable id="rz">
          <:start>Left</:start>
          <:end_pane>Right</:end_pane>
        </.resizable>
        """)

      assert html =~ ~s(id="rz")
      assert html =~ ~s(phx-hook="ShadcnResizable")
      assert html =~ "Left"
      assert html =~ "Right"
      assert html =~ "resizable-handle"
      assert html =~ ~s(role="separator")
      assert html =~ ~s(aria-orientation="vertical")
      assert count(html, "resizable-panel") == 2
    end
  end

  describe "__using__/1" do
    test "imports all component modules" do
      defmodule UsingComponents do
        use Phoenix.Component
        use ShadcnDaisyui.Components

        def sample(assigns) do
          ~H"""
          <.badge>b</.badge>
          <.tooltip tip="t">x</.tooltip>
          <.tabs id="t"><:tab label="A">a</:tab></.tabs>
          <.spinner />
          <.label>L</.label>
          """
        end
      end

      html =
        UsingComponents.sample(%{__changed__: nil})
        |> Phoenix.HTML.Safe.to_iodata()
        |> IO.iodata_to_binary()

      assert html =~ "badge"
      assert html =~ "tooltip"
      assert html =~ "tabs tabs-box"
      assert html =~ "loading-spinner"
      assert html =~ "<label"
    end
  end
end
