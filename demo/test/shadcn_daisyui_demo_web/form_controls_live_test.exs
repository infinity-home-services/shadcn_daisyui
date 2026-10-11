defmodule ShadcnDaisyuiDemoWeb.FormControlsLiveTest do
  @moduledoc """
  `<.switch>`, `<.checkbox>`, `<.radio_group>` (and the other field-bound
  `FormComponents`) must follow the server's value
  on every LiveView re-render, not keep their first-render state. Each change
  below goes through `phx-change`, the server stores the new params and
  re-renders the form, and the control has to be patched to match.
  """
  use ShadcnDaisyuiDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  defmodule FormLive do
    use Phoenix.LiveView
    use ShadcnDaisyui.Components

    @initial %{
      "notify" => "false",
      "agree" => "false",
      "plan" => "free",
      "role" => "member",
      "bio" => "Hi"
    }

    def mount(_params, _session, socket), do: {:ok, assign(socket, form: to_form(@initial))}

    def handle_event("validate", params, socket) do
      params = Map.take(params, Map.keys(@initial))
      {:noreply, assign(socket, form: to_form(Map.merge(socket.assigns.form.params, params)))}
    end

    def render(assigns) do
      ~H"""
      <.form for={@form} id="f" phx-change="validate">
        <.switch field={@form[:notify]} id="notify" label="Notify" />
        <.checkbox field={@form[:agree]} id="agree" label="Agree" />
        <.switch field={@form[:notify]} id="forced" name="forced" label="Forced on" checked />
        <.radio_group field={@form[:plan]} id="plan" label="Plan">
          <:radio value="free">Free</:radio>
          <:radio value="pro">Pro</:radio>
        </.radio_group>
        <.radio_group field={@form[:plan]} id="pinned" name="pinned" label="Pinned" value="pro">
          <:radio value="free">Free</:radio>
          <:radio value="pro">Pro</:radio>
        </.radio_group>
        <.native_select field={@form[:role]} id="role" options={["admin", "member"]} />
        <.textarea field={@form[:bio]} id="bio" />
      </.form>
      """
    end
  end

  defp change(view, params), do: view |> form("#f") |> render_change(params)

  test "a switch and a checkbox follow the server's value on re-render", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, FormLive)

    refute has_element?(view, "#notify[checked]")
    refute has_element?(view, "#agree[checked]")

    change(view, %{"notify" => "true", "agree" => "true"})
    assert has_element?(view, "#notify[checked]")
    assert has_element?(view, "#agree[checked]")

    change(view, %{"notify" => "false", "agree" => "false"})
    refute has_element?(view, "#notify[checked]")
    refute has_element?(view, "#agree[checked]")
  end

  test "an explicit checked attr wins over the field", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, FormLive)

    assert has_element?(view, "#forced[checked]")
    change(view, %{"notify" => "true"})
    assert has_element?(view, "#forced[checked]")
    change(view, %{"notify" => "false"})
    assert has_element?(view, "#forced[checked]")
  end

  test "a radio group follows the server's pick on re-render", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, FormLive)

    assert has_element?(view, "#plan-0[checked]")
    refute has_element?(view, "#plan-1[checked]")

    change(view, %{"plan" => "pro"})
    refute has_element?(view, "#plan-0[checked]")
    assert has_element?(view, "#plan-1[checked]")

    change(view, %{"plan" => "free"})
    assert has_element?(view, "#plan-0[checked]")
    refute has_element?(view, "#plan-1[checked]")
  end

  test "a native select and a textarea follow the server's value", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, FormLive)

    assert has_element?(view, ~s(#role option[value="member"][selected]))
    assert has_element?(view, "#bio", "Hi")

    change(view, %{"role" => "admin", "bio" => "Hello"})
    assert has_element?(view, ~s(#role option[value="admin"][selected]))
    refute has_element?(view, ~s(#role option[value="member"][selected]))
    assert has_element?(view, "#bio", "Hello")
  end

  test "an explicit value attr wins over the field on a radio group", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, FormLive)

    assert has_element?(view, "#pinned-1[checked]")
    change(view, %{"plan" => "free"})
    assert has_element?(view, "#pinned-1[checked]")
    refute has_element?(view, "#pinned-0[checked]")
  end
end
