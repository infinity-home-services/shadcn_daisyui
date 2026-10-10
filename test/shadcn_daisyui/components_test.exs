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

    test "range_calendar renders the hook, an ignored grid mount, and months" do
      assigns = %{}
      html = render(~H|<.range_calendar id="stay" months={2} />|)

      assert html =~ ~s(id="stay")
      assert html =~ ~s(phx-hook="ShadcnRangeCalendar")
      assert html =~ "data-range-calendar"
      assert html =~ ~s(data-months="2")
      assert html =~ ~s(id="stay-grid" phx-update="ignore" data-range-calendar-grid)
      refute html =~ ~s(type="hidden")
    end

    test "range_calendar emits named hidden inputs with ISO dates when form-bound" do
      assigns = %{}

      html =
        render(~H"""
        <.range_calendar
          id="booking"
          start_name="booking[check_in]"
          end_name="booking[check_out]"
          start={~D[2026-10-04]}
          end="2026-10-11"
        />
        """)

      assert html =~ ~s(name="booking[check_in]" value="2026-10-04" data-range-start)
      assert html =~ ~s(name="booking[check_out]" value="2026-10-11" data-range-end)
      assert html =~ ~s(data-start="2026-10-04")
      assert html =~ ~s(data-end="2026-10-11")
    end

    test "range_calendar ignores blank preselected values" do
      assigns = %{}
      html = render(~H|<.range_calendar id="r" start_name="s" start="" />|)
      assert html =~ ~s(name="s" data-range-start)
      refute html =~ "data-start="
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

  describe "select/1 and combobox/1 with multiple" do
    defp form_field(name, value, errors \\ []) do
      form = Phoenix.Component.to_form(%{name => value}, as: :filters, errors: errors)
      form[String.to_atom(name)]
    end

    test "renders checkbox rows, counts, a hidden Clear row and the multiselect listbox" do
      assigns = %{}

      html =
        render(~H"""
        <.select id="status" multiple placeholder="Status">
          <:option value="todo" count={12}>Todo</:option>
          <:option value="done">Done</:option>
        </.select>
        """)

      assert html =~ "data-multiple"
      assert html =~ ~s(aria-multiselectable="true")
      assert count(html, ~s(class="facet-check")) == 2
      assert html =~ ~s(<span class="ml-auto font-mono text-xs text-muted-foreground">12</span>)
      assert html =~ "data-select-clear-btn"

      assert html =~
               ~r/class="-mx-1 mt-1 border-t border-border px-1 pt-1 hidden" data-select-clear/

      assert html =~ "Status"
      refute html =~ "data-select-sentinel"
    end

    test "emits a sentinel plus one name[] input per selected value" do
      assigns = %{}

      html =
        render(~H"""
        <.select id="status" name="filters[status]" value={["todo", :done]} multiple>
          <:option value="todo">Todo</:option>
          <:option value="done">Done</:option>
          <:option value="canceled">Canceled</:option>
        </.select>
        """)

      assert html =~ ~s(type="hidden" name="filters[status]" value="" data-select-sentinel)
      assert html =~ ~s(name="filters[status][]" value="todo" data-select-value)
      assert html =~ ~s(name="filters[status][]" value="done" data-select-value)
      refute html =~ ~s(value="canceled" data-select-value)
      assert count(html, "data-selected") == 2
      assert count(html, ~s(aria-selected="true")) == 2
      # server-rendered trigger label: both labels, no "+N"
      assert html =~ ~s(<span class="truncate">Todo, Done</span>)
      refute html =~ "sr-only"
    end

    test "trigger shows two labels then +N" do
      assigns = %{}

      html =
        render(~H"""
        <.select id="s" value={~w(a b c d)} multiple>
          <:option value="a">A</:option>
          <:option value="b">B</:option>
          <:option value="c">C</:option>
          <:option value="d">D</:option>
        </.select>
        """)

      assert html =~ ~s(<span class="truncate">A, B</span>)
      assert html =~ ~r/\+2<span class="sr-only"> more<\/span>/
    end

    test "a trailing [] in name is normalised" do
      assigns = %{}

      html =
        render(
          ~H|<.select id="s" name="tags[]" multiple><:option value="a">A</:option></.select>|
        )

      assert html =~ ~s(name="tags" value="" data-select-sentinel)
    end

    test "field derives name, value and the trigger id" do
      assigns = %{field: form_field("status", ["done"])}

      html =
        render(~H"""
        <.select id="status-select" field={@field} multiple>
          <:option value="todo">Todo</:option>
          <:option value="done">Done</:option>
        </.select>
        """)

      assert html =~ ~s(name="filters[status]" value="" data-select-sentinel)
      assert html =~ ~s(name="filters[status][]" value="done" data-select-value)
      assert html =~ ~s(id="filters_status")
    end

    test "a field with errors marks the trigger aria-invalid once used" do
      form =
        Phoenix.Component.to_form(%{"status" => []},
          as: :f,
          errors: [status: {"can't be blank", []}],
          action: :validate
        )

      assigns = %{field: form[:status]}

      html =
        render(
          ~H|<.select id="s" field={@field} multiple><:option value="a">A</:option></.select>|
        )

      assert html =~ ~s(aria-invalid="true")
    end

    test "single-value field binding" do
      assigns = %{field: form_field("fruit", "Banana")}

      html =
        render(~H"""
        <.select id="fruit" field={@field}>
          <:option value="Apple">Apple</:option>
          <:option value="Banana">Banana</:option>
        </.select>
        """)

      assert html =~ ~s(name="filters[fruit]" value="Banana" data-select-input)
      assert html =~ ~s(<span class="truncate">Banana</span>)
      refute html =~ "data-multiple"
    end

    test "combobox multiple keeps the search box and renders checkbox rows" do
      assigns = %{}

      html =
        render(~H"""
        <.combobox id="labels" name="labels" multiple value={["bug"]} search_placeholder="Filter labels…">
          <:option value="bug" count={3}>Bug</:option>
          <:option value="docs">Docs</:option>
        </.combobox>
        """)

      assert html =~ ~s(phx-hook="ShadcnCombobox")
      assert html =~ ~s(placeholder="Filter labels…")
      assert html =~ "data-combobox-sentinel"
      assert html =~ ~s(name="labels[]" value="bug" data-combobox-value)
      assert html =~ "data-combobox-clear-btn"
      assert count(html, ~s(class="facet-check")) == 2
    end

    test "full_width replaces the default width" do
      assigns = %{}
      html = render(~H|<.select id="s" full_width><:option value="a">A</:option></.select>|)
      assert html =~ ~s(class="relative w-full")
      assert html =~ "data-full-width"
      html = render(~H|<.select id="s"><:option value="a">A</:option></.select>|)
      assert html =~ ~s(class="relative w-60")
    end
  end

  describe "date_range/1 form binding" do
    test "emits ISO hidden inputs, data-start/end and a server-rendered label" do
      assigns = %{}

      html =
        render(~H"""
        <.date_range
          id="period"
          start_name="report[from]"
          end_name="report[to]"
          start={~D[2026-10-04]}
          end="2026-10-11"
        />
        """)

      assert html =~ ~s(name="report[from]" value="2026-10-04" data-range-start)
      assert html =~ ~s(name="report[to]" value="2026-10-11" data-range-end)
      assert html =~ ~s(data-start="2026-10-04")
      assert html =~ "Oct 4 – Oct 11, 2026"
      assert html =~ ~s(id="period-calendar" phx-update="ignore" data-calendar-range)
    end

    test "renders presets with ISO data attributes" do
      assigns = %{}

      html =
        render(~H"""
        <.date_range id="period">
          <:preset label="Last 7 days" start={~D[2026-10-03]} end={~D[2026-10-09]} />
          <:preset label="Last 30 days" days={30} />
        </.date_range>
        """)

      assert html =~ ~s(data-days="30")

      assert html =~ "data-daterange-preset"
      assert html =~ ~s(data-start="2026-10-03")
      assert html =~ ~s(data-end="2026-10-09")
      assert html =~ "Last 7 days"
      refute html =~ "data-range-start"
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

  describe "time_picker/1" do
    test "renders hook, trigger, placeholder and 12-hour columns" do
      assigns = %{}
      html = render(~H|<.time_picker id="tp" />|)

      assert html =~ ~s(phx-hook="ShadcnTimePicker")
      assert html =~ ~s(data-hour-cycle="12")
      assert html =~ "data-timepicker-trigger"
      assert html =~ ~s(id="tp-trigger")
      assert html =~ "Pick a time"
      assert html =~ "text-muted-foreground"
      assert html =~ ~s(aria-label="Hours")
      assert html =~ ~s(aria-label="AM/PM")
      refute html =~ ~s(aria-label="Seconds")
      refute html =~ "data-timepicker-input"
      assert count(html, ~s(class="time-option")) == 12 + 60 + 2
      refute html =~ ~s(aria-selected="true")
    end

    test "a value renders the label, the hidden input and the selected options" do
      assigns = %{}
      html = render(~H|<.time_picker id="tp" name="shift[start]" value={~T[14:05:30]} />|)

      assert html =~ ~s(data-value="14:05")

      assert html =~
               ~s(<input type="hidden" name="shift[start]" value="14:05" data-timepicker-input>)

      assert html =~ "2:05 PM"
      assert html =~ ~r/aria-selected="true"[^>]*data-value="2"/
      assert html =~ ~r/aria-selected="true"[^>]*data-value="5"/
      assert html =~ ~r/aria-selected="true"[^>]*data-value="PM"/
    end

    test "24-hour cycle, seconds and minute_step" do
      assigns = %{}

      html =
        render(
          ~H|<.time_picker id="tp" value="09:30" hour_cycle={24} seconds minute_step={15} />|
        )

      assert html =~ ~s(data-value="09:30:00")
      assert html =~ "09:30:00"
      refute html =~ ~s(aria-label="AM/PM")
      assert html =~ ~s(aria-label="Seconds")
      assert count(html, ~s(class="time-option")) == 24 + 4 + 60
    end

    test "midnight and noon in 12-hour time" do
      assigns = %{}
      assert render(~H|<.time_picker id="a" value="00:15" />|) =~ "12:15 AM"
      assert render(~H|<.time_picker id="b" value="12:00" />|) =~ "12:00 PM"
    end

    test "field binding derives name, value, trigger id and invalid state" do
      assigns = %{
        form:
          Phoenix.Component.to_form(%{"opens_at" => "08:00"},
            as: :store,
            errors: [opens_at: {"is invalid", []}]
          )
      }

      html = render(~H|<.time_picker id="opens" field={@form[:opens_at]} />|)

      assert html =~ ~s(name="store[opens_at]")
      assert html =~ ~s(value="08:00")
      assert html =~ ~s(id="store_opens_at")
      assert html =~ "8:00 AM"
    end

    test "an unparseable value shows the placeholder" do
      assigns = %{}
      html = render(~H|<.time_picker id="tp" name="t" value="soon" />|)

      assert html =~ "Pick a time"
      assert html =~ ~s(value="")
    end
  end
end
