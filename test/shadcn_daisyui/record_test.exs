defmodule ShadcnDaisyui.Components.RecordTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.Components.Record

  defp render(template), do: template |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()

  defp count(html, substring), do: html |> String.split(substring) |> length() |> Kernel.-(1)

  describe "record_tabs/1" do
    test "a tablist of tab buttons; the active one selected and the one tab stop" do
      assigns = %{}

      html =
        render(~H"""
        <.record_tabs id="t" tabs={[{"details", "Details"}, {"activity", "Activity", 12}]} active="activity" />
        """)

      assert html =~ ~s(id="t" role="tablist")
      assert html =~ "data-record-tabs"
      assert count(html, ~s(role="tab")) == 2
      assert html =~ ~r/id="t-details" class="record-tab" aria-selected="false" tabindex="-1"/
      assert html =~ ~r/id="t-activity" class="record-tab" aria-selected="true" tabindex="0"/
      assert html =~ ~s(<span class="tab-count">12</span>)
    end

    test "each tab sends tab with its key" do
      assigns = %{}
      html = render(~H|<.record_tabs id="t" tabs={[{:files, "Files"}]} active={:files} />|)

      assert html =~ "&quot;push&quot;"
      assert html =~ "&quot;event&quot;:&quot;tab&quot;"
      assert html =~ "&quot;tab&quot;:&quot;files&quot;"
    end

    test "event and target change where it goes" do
      assigns = %{}

      html =
        render(~H|<.record_tabs id="t" tabs={[{"a", "A"}]} event="pick" target="#owner" />|)

      assert html =~ "&quot;event&quot;:&quot;pick&quot;"
      assert html =~ "&quot;target&quot;:&quot;#owner&quot;"
    end

    test "no active (or an unknown one): the first tab is the tab stop" do
      assigns = %{}
      html = render(~H|<.record_tabs id="t" tabs={[{"a", "A"}, {"b", "B"}]} active="zz" />|)

      assert html =~ ~r/id="t-a" class="record-tab" aria-selected="true" tabindex="0"/
    end
  end

  describe "table_card/1" do
    @events [%{id: 1, text: "Paid", at: "Today"}, %{id: 2, text: "Sent", at: "Yesterday"}]

    test "a card with a header and a role=table of rows, labels as the header row" do
      assigns = %{rows: @events}

      html =
        render(~H"""
        <.table_card id="activity" title="Activity" description="What happened" rows={@rows} row_id={&"ev-#{&1.id}"}>
          <:col :let={e} label="Event">{e.text}</:col>
          <:col :let={e} label="When">{e.at}</:col>
          <:actions><a href="/all">View all</a></:actions>
        </.table_card>
        """)

      assert html =~ ~s(<section id="activity" class="card table-card " data-layout="stack">)
      assert html =~ ~s(<h3 class="card-title">Activity</h3>)
      assert html =~ "What happened"
      assert html =~ ~s(<div class="table-card-actions"><a href="/all">View all</a></div>)
      assert html =~ ~s(role="table" aria-label="Activity")
      assert count(html, ~s(role="columnheader")) == 2
      assert html =~ ~s(id="ev-1" role="row")
      assert count(html, ~s(role="cell")) == 4
      # stacked on phones, two equal columns from sm
      assert count(html, ~s(data-cols="2")) == 3
    end

    test "the rightmost column is right-aligned unless align=left" do
      assigns = %{rows: @events}

      html =
        render(~H"""
        <.table_card id="a" rows={@rows}>
          <:col :let={e} label="Event">{e.text}</:col>
          <:col :let={e} label="When">{e.at}</:col>
        </.table_card>
        """)

      assert count(html, ~s(data-align="right")) == 3

      html =
        render(~H"""
        <.table_card id="a" rows={@rows}>
          <:col :let={e} label="Event">{e.text}</:col>
          <:col :let={e} label="When" align="left">{e.at}</:col>
        </.table_card>
        """)

      refute html =~ ~s(data-align="right")
    end

    test "grid keeps the columns side by side at every width; no default columns" do
      assigns = %{rows: @events}

      html =
        render(~H"""
        <.table_card id="a" rows={@rows} grid="grid-cols-[minmax(0,1fr)_auto]" row_class={&(&1.id == 1 && "font-medium")}>
          <:col :let={e} label="Event">{e.text}</:col>
          <:col :let={e}>{e.at}</:col>
        </.table_card>
        """)

      assert html =~ ~s(data-layout="grid")
      refute html =~ "data-cols"
      assert count(html, "grid-cols-[minmax(0,1fr)_auto]") == 3
      assert html =~ ~r/class="table-card-row grid-cols-\[minmax\(0,1fr\)_auto\] font-medium"/
    end

    test "no labels: no header row; no rows: the :empty row" do
      assigns = %{}

      html =
        render(~H"""
        <.table_card id="a" rows={[]}>
          <:col :let={e}>{e.text}</:col>
          <:empty>Nothing yet.</:empty>
        </.table_card>
        """)

      refute html =~ "table-card-head"
      refute html =~ "table-card-header"
      assert html =~ ~r/class="table-card-empty">\s*<div role="cell">Nothing yet.<\/div>/
    end
  end

  describe "section_nav/1" do
    @sections [
      {"customer", "Customer"},
      {"items", "Items", "Order"},
      {"payment", "Payment", "Order"}
    ]

    test "side: the hook, links to each section, groups, the first one current" do
      assigns = %{sections: @sections}
      html = render(~H|<.section_nav id="s" sections={@sections} />|)

      assert html =~ ~s(<nav id="s" phx-hook="ShadcnSectionNav")
      assert html =~ ~s(data-variant="side")
      assert html =~ ~s(aria-label="Sections")

      assert html =~
               ~r/href="#customer" class="section-nav-item" aria-current="true" data-section="customer"/

      assert html =~ ~r/href="#items" class="section-nav-item" data-section="items"/
      assert count(html, ~s(<div class="section-nav-group-label">Order</div>)) == 1
      refute html =~ "data-section-filter"
      # no inner block: just the list
      refute html =~ "section-nav-layout"
    end

    test "side with the sections as its inner block: the two-column layout" do
      assigns = %{sections: @sections}

      html =
        render(~H"""
        <.section_nav id="s" sections={@sections}>
          <div id="customer">C</div>
        </.section_nav>
        """)

      assert html =~ ~s(<div class="section-nav-layout">)
      assert html =~ ~r/<div class="section-nav-content">\s*<div id="customer">C<\/div>/
    end

    test "side over 10 sections: a filter input and the no-match line" do
      assigns = %{sections: for(i <- 1..11, do: {"s#{i}", "Section #{i}"})}
      html = render(~H|<.section_nav id="s" sections={@sections} />|)

      assert html =~ ~s(placeholder="Filter sections")
      assert html =~ "data-section-filter"
      assert html =~ ~r/data-section-none hidden>No sections match.</
    end

    test "select: a trigger naming the current section, 44px options with a tick" do
      assigns = %{sections: @sections}
      html = render(~H|<.section_nav id="s" sections={@sections} variant="select" />|)

      assert html =~ ~s(data-variant="select")
      assert html =~ ~s(aria-haspopup="listbox")
      assert html =~ ~r/data-section-current>Customer</
      assert html =~ ~s(role="listbox")
      assert count(html, ~s(role="option")) == 3
      assert html =~ ~r/aria-selected="true" data-section="customer" data-label="Customer"/
      # grouped: the label reads "Group, Section"
      assert html =~ ~s(data-label="Order, Items")
      # a section named like its group reads once
      single =
        render(
          ~H|<.section_nav id="s" variant="select" sections={[{"a", "Billing", "Billing"}]} />|
        )

      assert single =~ ~s(data-label="Billing")
      assert html =~ ~s(<div id="s-group-1" class="command-group-label">Order</div>)
      assert count(html, "section-nav-tick") == 3
    end
  end

  describe "time_field/1" do
    defp form(params \\ %{}, errors \\ []) do
      %{"opens_at" => "09:30"}
      |> Map.merge(params)
      |> to_form(as: :store, errors: errors)
    end

    test "a label above a full-width time picker with Not set" do
      assigns = %{form: form()}
      html = render(~H|<.time_field id="opens" field={@form[:opens_at]} label="Opens at" />|)

      assert html =~ ~s(<div class="time-field ">)
      assert html =~ ~s(<label for="store_opens_at" class="time-field-label">Opens at</label>)
      assert html =~ ~s(phx-hook="ShadcnTimePicker")
      assert html =~ ~s(data-full-width)
      assert html =~ ~s(data-placeholder="Not set")
      assert html =~ ~s(name="store[opens_at]" value="09:30")
      # 15-minute steps by default
      [minutes] = Regex.run(~r/aria-label="Minutes".*?<\/div>/s, html)
      assert count(minutes, ~s(role="option")) == 4
    end

    test "errors show once the field was used" do
      unused = form(%{"_unused_opens_at" => ""}, opens_at: {"can't be blank", []})
      assigns = %{form: unused}
      refute render(~H|<.time_field id="o" field={@form[:opens_at]} label="Opens" />|) =~ "blank"

      used = form(%{}, opens_at: {"can't be blank", []})
      assigns = %{form: used}
      html = render(~H|<.time_field id="o" field={@form[:opens_at]} label="Opens" />|)
      assert html =~ "can&#39;t be blank"
      assert html =~ ~s(aria-invalid="true")
    end
  end
end
