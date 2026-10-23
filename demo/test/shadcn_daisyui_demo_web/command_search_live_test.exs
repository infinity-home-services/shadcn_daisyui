defmodule ShadcnDaisyuiDemoWeb.CommandSearchLiveTest do
  @moduledoc """
  `/lab/command-search`: `<.command on_search>` owned by a LiveComponent. The
  hook's pushes are `render_hook/3` on the palette (its `phx-target` sends them
  to the component); answers arrive through `start_async`, so `render_async/1`
  waits for them (each search takes 400ms).
  """
  use ShadcnDaisyuiDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  defp search(view, query) do
    view
    |> element("#find-person")
    |> render_hook("search", %{"id" => "find-person", "query" => query})
  end

  defp answered(view), do: view |> element("#find-person") |> render() |> data_query()

  defp data_query(html) do
    case Regex.run(~r/<dialog id="find-person"[^>]*\sdata-query="([^"]*)"/, html) do
      [_, query] -> query
      nil -> nil
    end
  end

  test "renders a server search palette owned by the component", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/lab/command-search")

    assert html =~ ~s(data-on-search="search")
    assert html =~ ~s(data-search-debounce="250")
    assert html =~ ~r/<dialog id="find-person"[^>]*phx-target="\d+"/
    assert has_element?(view, "#find-person [data-command-hint]", "Type a name or email.")

    assert has_element?(
             view,
             "#find-person [data-command-status][role=status][phx-update=ignore]"
           )

    # nothing searched yet: no answer, no items
    assert answered(view) == nil
    refute has_element?(view, "#find-person [data-command-item]")
  end

  test "an answer echoes the text and is the results", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/lab/command-search")

    search(view, "pat r")
    # the answer is still on its way
    assert answered(view) == nil
    render_async(view, 2_000)

    assert answered(view) == "pat r"
    assert has_element?(view, ~s(#person-1[phx-click="add"][phx-value-id="1"]), "Pat Rivera")
    assert has_element?(view, "#person-1 .command-item-description", "pat.rivera@example.test")
    assert view |> element("#find-person") |> render() |> String.contains?("data-command-item")
  end

  test "each result offers one action, by where the person stands", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/lab/command-search")

    # in the team: their row
    search(view, "jordan")
    render_async(view, 2_000)
    assert has_element?(view, ~s(a#person-2[href="/lab/command-search?person=2"]), "Open")

    # removed: Add back, after a confirm
    search(view, "alex")
    render_async(view, 2_000)

    assert has_element?(
             view,
             ~s(#person-4[phx-click="add"][data-confirm="Add Alex Morgan back? They start with no roles."]),
             "Add back"
           )

    # removal scheduled: nothing to do
    search(view, "riley")
    render_async(view, 2_000)
    assert has_element?(view, ~s(button#person-6[aria-disabled="true"]), "Removal scheduled")
    refute has_element?(view, "#person-6[phx-click]")
  end

  test "only the latest text's answer lands", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/lab/command-search")

    search(view, "pa")
    search(view, "pat")
    render_async(view, 2_000)

    assert answered(view) == "pat"
    assert has_element?(view, "#person-12", "Patricia Hale")
    # "pa" also matched Robin Park
    refute has_element?(view, "#person-11")
  end

  test "opening (an empty search) drops the last results at once", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/lab/command-search")

    search(view, "pat")
    render_async(view, 2_000)
    assert has_element?(view, "#person-1")

    search(view, "")
    assert answered(view) == ""
    refute has_element?(view, "#find-person [data-command-item]")

    # a search still running when the palette reopened doesn't land later
    search(view, "sam")
    search(view, "")
    render_async(view, 2_000)
    assert answered(view) == ""
    refute has_element?(view, "#person-3")
  end

  test "no match shows the empty text for that text", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/lab/command-search")

    search(view, "zz")
    render_async(view, 2_000)

    assert answered(view) == "zz"
    assert has_element?(view, "#find-person [data-command-empty]", ~s(No one matches "zz".))
    refute has_element?(view, "#find-person [data-command-item]")
  end

  test "adding someone puts them in the team", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/lab/command-search")
    refute has_element?(view, "#member-1")

    search(view, "pat r")
    render_async(view, 2_000)
    view |> element("#person-1") |> render_click()

    assert has_element?(view, "#member-1", "Pat Rivera")
    assert has_element?(view, "#member-1", "Active")
  end

  test "adding someone back makes them active again", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/lab/command-search")
    assert has_element?(view, "#member-4", "Removed")

    search(view, "alex")
    render_async(view, 2_000)
    view |> element("#person-4") |> render_click()

    assert has_element?(view, "#member-4", "Active")
  end

  test "is served under the strict CSP with no inline handlers", %{conn: conn} do
    conn = get(conn, ~p"/lab/command-search")
    html = html_response(conn, 200)

    assert conn |> get_resp_header("content-security-policy") |> Enum.join() =~ "'nonce-"
    assert Regex.scan(~r/<[a-z][^>]*\son[a-z]+\s*=/i, html) == []
  end
end
