defmodule ShadcnDaisyuiDemoWeb.LabDataTableLiveTest do
  @moduledoc """
  `/lab/data-table` and its record page, driven through LiveViewTest: the
  events `<.data_table>` and `<.table_toolbar>` send, the URL that
  `ShadcnDaisyui.DataTable.State` keeps, and the modals the record page opens
  from the server (`push_show_modal/2`, and `show` + `on_close`).
  """
  use ShadcnDaisyuiDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  defp rows(view),
    do:
      view
      |> render()
      |> then(&Regex.scan(~r/id="orders-row-(\d+)"/, &1))
      |> Enum.map(&List.last/1)

  describe "the list" do
    test "renders the toolbar and 40 rows, more to load", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/lab/data-table")

      assert html =~ ~s(id="orders-toolbar")
      assert html =~ ~s(phx-hook="ShadcnDataTable")
      assert length(rows(view)) == 40
      assert has_element?(view, "#orders[data-more]")
    end

    test "a header sort goes in the URL, ascending then descending then default", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/lab/data-table")

      render_hook(view, "dt:sort", %{"key" => "total", "table" => "orders"})
      assert_patch(view, ~p"/lab/data-table?sort=total")
      assert has_element?(view, ~s(th[aria-sort="ascending"]))

      render_hook(view, "dt:sort", %{"key" => "total", "table" => "orders"})
      assert_patch(view, ~p"/lab/data-table?dir=desc&sort=total")
      assert has_element?(view, ~s(th[aria-sort="descending"]))

      render_hook(view, "dt:sort", %{"key" => "total", "table" => "orders"})
      assert_patch(view, ~p"/lab/data-table")
    end

    test "the filter form: search, filters and the phone's sort select", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/lab/data-table")

      view
      |> element("#orders-toolbar-form")
      |> render_change(%{
        "q" => "harbor",
        "status" => ["open", "overdue"],
        "owner" => "",
        "sort" => ""
      })

      assert_patch(view, ~p"/lab/data-table?q=harbor&status=open%2Coverdue")
      html = render(view)
      assert html =~ "Status: Open or Overdue"
      assert has_element?(view, "#orders-toolbar .reveal[data-open]")
      assert html =~ ~r/table-toolbar-filters-count">\s*1/

      # the chip's remove button
      render_hook(view, "dt:unfilter", %{"key" => "status", "table" => "orders-toolbar"})
      assert_patch(view, ~p"/lab/data-table?q=harbor")

      render_hook(view, "dt:reset", %{"table" => "orders-toolbar"})
      assert_patch(view, ~p"/lab/data-table")
    end

    test "Back restores a view from the URL", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/lab/data-table?status=refunded&sort=customer")

      assert has_element?(view, ~s(th[aria-sort="ascending"]))
      assert render(view) =~ "Status: Refunded"
      refute render(view) =~ ~r/class="badge badge-secondary">Paid/
    end

    test "ticking rows: one, a shift range, all shown, all matching, clear", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/lab/data-table")
      [first, second, third | _] = rows(view)

      render_hook(view, "dt:select", %{"id" => first, "shift" => false, "table" => "orders"})
      assert has_element?(view, "#orders-row-#{first}[data-selected]")
      assert render(view) =~ ~r/1 selected/

      render_hook(view, "dt:select", %{"id" => third, "shift" => true, "table" => "orders"})
      assert has_element?(view, "#orders-row-#{second}[data-selected]")
      assert render(view) =~ ~r/3 selected/

      render_hook(view, "dt:select_all", %{"table" => "orders"})
      assert render(view) =~ ~r/40 selected/
      assert render(view) =~ "Select all 240 orders"

      render_hook(view, "dt:select_matching", %{"table" => "orders"})
      assert render(view) =~ "All 240 selected"

      render_hook(view, "dt:clear", %{"table" => "orders"})
      assert has_element?(view, "#orders [data-dt-bulk][hidden]")
    end

    test "more rows as the end comes into view", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/lab/data-table")
      render_hook(view, "dt:more", %{"table" => "orders"})
      assert length(rows(view)) == 80
    end

    test "opening a row goes to the record, carrying the list's view back", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/lab/data-table?status=open")

      assert {:error, {:live_redirect, %{to: to}}} =
               render_hook(view, "dt:open", %{"id" => "237", "table" => "orders"})

      assert to =~ "/lab/data-table/237?back="

      {:ok, record, _html} = live(conn, to)
      assert has_element?(record, ~s(a[href="/lab/data-table?opened=237&status=open"]), "Orders")

      {:ok, list, _html} = live(conn, ~p"/lab/data-table?opened=237&status=open")
      assert has_element?(list, "#orders-row-237[data-active]")
    end

    test "no match: the in-table empty state with its action", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/lab/data-table?q=zzzz")
      html = render(view)

      assert html =~ "No orders match"
      assert html =~ "Clear filters"
      assert html =~ ~s(data-variant="plain")
    end
  end

  describe "the record" do
    test "tabs, the section nav (both), time fields and the items", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/lab/data-table/12")

      assert html =~ ~s(role="tablist")
      assert has_element?(view, "#order-sections[data-variant=side]")
      assert has_element?(view, "#order-sections-select[data-variant=select]")
      assert has_element?(view, "#order-sections [data-section-filter]")
      assert has_element?(view, "#opens[phx-hook=ShadcnTimePicker]")
      assert has_element?(view, "#items[role=table], #items [role=table]")

      render_hook(view, "tab", %{"tab" => "activity"})
      assert has_element?(view, "#activity")
      refute has_element?(view, "#order-form")
    end

    test "Cancel without changes goes back; with changes the server asks first", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/lab/data-table/12")

      view
      |> element("#order-form")
      |> render_change(%{"order" => %{"notes" => "Leave at the back"}})

      render_click(view, "cancel")
      assert_push_event(view, "shadcn:show-modal", %{id: "discard"})

      # asked again after "Keep editing" closed it
      render_click(view, "cancel")
      assert_push_event(view, "shadcn:show-modal", %{id: "discard"})

      assert {:error, {:live_redirect, %{to: "/lab/data-table?opened=12"}}} =
               render_click(view, "discard")
    end

    test "Delete opens its confirm with show; on_close turns it off; Delete again reopens", %{
      conn: conn
    } do
      {:ok, view, _html} = live(conn, ~p"/lab/data-table/12")

      refute has_element?(view, "#delete-order[data-show]")
      render_click(view, "delete")
      assert has_element?(view, "#delete-order[data-show]")
      assert has_element?(view, ~s(#delete-order [data-on-close][phx-click="keep_order"]))

      # the person pressed Esc: the dialog's hidden on_close button runs
      view |> element("#delete-order [data-on-close]") |> render_click()
      refute has_element?(view, "#delete-order[data-show]")

      render_click(view, "delete")
      assert has_element?(view, "#delete-order[data-show]")
    end

    test "the delivery window is validated once used", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/lab/data-table/12")

      html =
        view
        |> element("#order-form")
        |> render_change(%{"order" => %{"opens" => "17:00", "closes" => "09:00"}})

      assert html =~ "must be after the window opens"
    end
  end
end
