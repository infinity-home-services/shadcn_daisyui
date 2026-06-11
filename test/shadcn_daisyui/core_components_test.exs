defmodule ShadcnDaisyui.CoreComponentsTest do
  # async: false because the MFA translation tests mutate global app config.
  use ExUnit.Case, async: false

  import Phoenix.Component
  import ShadcnDaisyui.CoreComponents

  alias Phoenix.LiveView.JS

  defmodule Translator do
    def translate({msg, _opts}), do: "T:" <> msg
  end

  defp render(template) do
    template |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  defp count(html, substring) do
    html |> String.split(substring) |> length() |> Kernel.-(1)
  end

  describe "button/1" do
    test "default renders a primary button" do
      assigns = %{}
      html = render(~H|<.button>Send!</.button>|)

      assert html =~ "<button"
      assert html =~ "btn btn-primary"
      assert html =~ "Send!"
    end

    test "primary is an alias for the default variant" do
      assigns = %{}
      assert render(~H|<.button variant="primary">Go</.button>|) =~ "btn btn-primary"
    end

    test "variant classes" do
      variants = %{
        "secondary" => "btn-secondary",
        "outline" => "btn-outline",
        "ghost" => "btn-ghost",
        "link" => "btn-link",
        "destructive" => "btn-error"
      }

      for {variant, class} <- variants do
        assigns = %{variant: variant}
        assert render(~H|<.button variant={@variant}>X</.button>|) =~ class
      end
    end

    test "size classes" do
      sizes = %{"sm" => "btn-sm", "lg" => "btn-lg", "icon" => "btn-square"}

      for {size, class} <- sizes do
        assigns = %{size: size}
        assert render(~H|<.button size={@size}>X</.button>|) =~ class
      end
    end

    test "navigate renders an anchor instead of a button" do
      assigns = %{}
      html = render(~H|<.button navigate="/home">Home</.button>|)

      assert html =~ "<a "
      assert html =~ ~s(href="/home")
      assert html =~ "btn btn-primary"
      refute html =~ "<button"
    end

    test "href and patch also render links" do
      assigns = %{}
      assert render(~H|<.button href="/x">X</.button>|) =~ ~s(<a href="/x")

      html = render(~H|<.button patch="/y">Y</.button>|)
      assert html =~ ~s(href="/y")
      assert html =~ ~s(data-phx-link="patch")
    end

    test "passes phx attributes and disabled through" do
      assigns = %{}
      html = render(~H|<.button phx-click="go" disabled>X</.button>|)

      assert html =~ ~s(phx-click="go")
      assert html =~ "disabled"
    end
  end

  describe "input/1 with a form field" do
    test "derives id, name, and value" do
      assigns = %{form: to_form(%{"email" => "hi"}, as: :user)}
      html = render(~H|<.input field={@form[:email]} type="email" label="Email" />|)

      assert html =~ ~s(type="email")
      assert html =~ ~s(id="user_email")
      assert html =~ ~s(name="user[email]")
      assert html =~ ~s(value="hi")
      assert html =~ "Email"
      assert html =~ "input w-full"
      refute html =~ "input-error"
    end

    test "renders translated errors and the error class when the input was used" do
      form =
        to_form(%{"email" => ""},
          as: :user,
          errors: [email: {"can't be blank", []}],
          action: :validate
        )

      assigns = %{form: form}
      html = render(~H|<.input field={@form[:email]} type="email" />|)

      assert html =~ "can&#39;t be blank"
      assert html =~ "input-error"
    end

    test "hides errors when the input was not used" do
      form =
        to_form(%{"email" => "", "_unused_email" => ""},
          as: :user,
          errors: [email: {"can't be blank", []}],
          action: :validate
        )

      assigns = %{form: form}
      html = render(~H|<.input field={@form[:email]} type="email" />|)

      refute html =~ "can&#39;t be blank"
      refute html =~ "input-error"
    end
  end

  describe "input/1 branches" do
    test "text default classes" do
      assigns = %{}
      html = render(~H|<.input name="q" value="abc" />|)

      assert html =~ ~s(type="text")
      assert html =~ "input w-full"
      assert html =~ ~s(value="abc")
      assert html =~ "fieldset"
    end

    test "custom class overrides the default" do
      assigns = %{}
      html = render(~H|<.input name="q" value="" class="input input-lg" />|)

      assert html =~ "input input-lg"
      refute html =~ "input w-full"
    end

    test "errors add the error class to a plain input" do
      assigns = %{}
      html = render(~H|<.input name="q" value="" errors={["too short"]} />|)

      assert html =~ "input w-full input-error"
      assert html =~ "too short"
    end

    test "hidden type renders a bare input" do
      assigns = %{}
      html = render(~H|<.input type="hidden" name="token" value="abc" />|)

      assert html =~ ~s(type="hidden")
      assert html =~ ~s(name="token")
      assert html =~ ~s(value="abc")
      refute html =~ "fieldset"
      refute html =~ "<label"
    end

    test "checkbox renders the hidden false input and checked state" do
      assigns = %{}
      html = render(~H|<.input type="checkbox" name="active" value="true" label="Active" />|)

      assert html =~ ~s(type="hidden")
      assert html =~ ~s(value="false")
      assert html =~ ~r/type="checkbox"[^>]*checked/
      assert html =~ "checkbox checkbox-sm"
      assert html =~ "Active"
    end

    test "checkbox without a truthy value is unchecked" do
      assigns = %{}
      html = render(~H|<.input type="checkbox" name="active" value="false" />|)

      refute html =~ ~r/type="checkbox"[^>]*checked/
    end

    test "select renders prompt and options with selection" do
      assigns = %{}

      html =
        render(
          ~H|<.input type="select" name="role" value="member" label="Role" prompt="Pick one" options={["admin", "member"]} />|
        )

      assert html =~ "<select"
      assert html =~ "select w-full"
      assert html =~ ~s(<option value="">Pick one</option>)
      assert html =~ ~s(value="admin")
      assert html =~ ~r/selected[^>]*value="member"|value="member"[^>]*selected/
      assert html =~ "Role"
    end

    test "select with errors gets select-error" do
      assigns = %{}

      html =
        render(
          ~H|<.input type="select" name="r" value="" options={["a"]} errors={["is required"]} />|
        )

      assert html =~ "select-error"
      assert html =~ "is required"
    end

    test "textarea renders the value in the body" do
      assigns = %{}
      html = render(~H|<.input type="textarea" name="bio" value="my bio" label="Bio" />|)

      assert html =~ "<textarea"
      assert html =~ "textarea w-full"
      assert html =~ "my bio"
      assert html =~ "Bio"
    end
  end

  describe "error/1" do
    test "renders the message with an icon" do
      assigns = %{}
      html = render(~H|<.error>oops</.error>|)

      assert html =~ "text-error"
      assert html =~ "hero-exclamation-circle"
      assert html =~ "oops"
    end
  end

  describe "header/1" do
    test "renders title, subtitle, and actions" do
      assigns = %{}

      html =
        render(~H"""
        <.header>
          Listing Users
          <:subtitle>All registered users</:subtitle>
          <:actions><button>New User</button></:actions>
        </.header>
        """)

      assert html =~ "<h1"
      assert html =~ "Listing Users"
      assert html =~ "All registered users"
      assert html =~ "New User"
      assert html =~ "flex items-center justify-between"
    end

    test "without actions there is no flex layout class" do
      assigns = %{}
      html = render(~H|<.header>Just a title</.header>|)

      refute html =~ "justify-between"
      refute html =~ "<p"
    end
  end

  describe "table/1" do
    test "renders column headers and one row per item" do
      assigns = %{rows: [%{id: 1, username: "jane"}, %{id: 2, username: "john"}]}

      html =
        render(~H"""
        <.table id="users" rows={@rows}>
          <:col :let={user} label="id">{user.id}</:col>
          <:col :let={user} label="username">{user.username}</:col>
        </.table>
        """)

      assert html =~ ~s(<table class="table">)
      assert html =~ ~s(<tbody id="users")
      assert html =~ "<th>id</th>"
      assert html =~ "<th>username</th>"
      assert html =~ "jane"
      assert html =~ "john"
      assert count(html, "<tr") == 3
      refute html =~ "phx-update"
    end

    test "renders the action column" do
      assigns = %{rows: [%{id: 1}]}

      html =
        render(~H"""
        <.table id="users" rows={@rows}>
          <:col :let={u} label="id">{u.id}</:col>
          <:action :let={u}><a href={"/users/#{u.id}/edit"}>Edit</a></:action>
        </.table>
        """)

      assert html =~ ~s(<span class="sr-only">Actions</span>)
      assert html =~ ~s(href="/users/1/edit")
      assert html =~ "Edit"
    end

    test "row_id and row_click wire up the rows" do
      assigns = %{rows: [%{id: 7}]}

      html =
        render(~H"""
        <.table id="t" rows={@rows} row_id={&"row-#{&1.id}"} row_click={&JS.navigate("/u/#{&1.id}")}>
          <:col :let={u} label="id">{u.id}</:col>
        </.table>
        """)

      assert html =~ ~s(id="row-7")
      assert html =~ "phx-click"
      assert html =~ "hover:cursor-pointer"
    end
  end

  describe "list/1" do
    test "renders a row per item with the title" do
      assigns = %{}

      html =
        render(~H"""
        <.list>
          <:item title="Title">My post</:item>
          <:item title="Views">42</:item>
        </.list>
        """)

      assert html =~ ~s(<ul class="list">)
      assert count(html, "list-row") == 2
      assert html =~ "Title"
      assert html =~ "My post"
      assert html =~ "Views"
      assert html =~ "42"
    end
  end

  describe "icon/1" do
    test "renders a heroicon span with the default size" do
      assigns = %{}
      html = render(~H|<.icon name="hero-x-mark" />|)

      assert html =~ "hero-x-mark size-4"
      assert html =~ ~s(aria-hidden="true")
    end

    test "custom class replaces the default" do
      assigns = %{}
      html = render(~H|<.icon name="hero-arrow-path" class="ml-1 size-3" />|)

      assert html =~ "hero-arrow-path ml-1 size-3"
      refute html =~ "size-4"
    end
  end

  describe "flash/1" do
    test "renders an info flash from the flash map" do
      assigns = %{flash: %{"info" => "Saved successfully"}}
      html = render(~H|<.flash kind={:info} flash={@flash} />|)

      assert html =~ ~s(id="flash-info")
      assert html =~ ~s(role="alert")
      assert html =~ "alert-info"
      assert html =~ "hero-information-circle"
      assert html =~ "Saved successfully"
      assert html =~ "lv:clear-flash"
    end

    test "renders an error flash with title" do
      assigns = %{flash: %{"error" => "Something went wrong"}}
      html = render(~H|<.flash kind={:error} title="Error!" flash={@flash} />|)

      assert html =~ ~s(id="flash-error")
      assert html =~ "alert-error"
      assert html =~ "hero-exclamation-circle"
      assert html =~ "Error!"
      assert html =~ "Something went wrong"
    end

    test "renders nothing when there is no message" do
      assigns = %{}
      html = render(~H|<.flash kind={:info} flash={%{}} />|)

      refute html =~ "alert"
    end

    test "renders the inner block regardless of the flash map" do
      assigns = %{}
      html = render(~H|<.flash kind={:info}>Direct message</.flash>|)

      assert html =~ "Direct message"
    end
  end

  describe "flash_group/1" do
    test "renders both flash kinds in a live region" do
      assigns = %{flash: %{"info" => "Up", "error" => "Down"}}
      html = render(~H|<.flash_group flash={@flash} />|)

      assert html =~ ~s(id="flash-group")
      assert html =~ ~s(aria-live="polite")
      assert html =~ "Up"
      assert html =~ "Down"
    end
  end

  describe "show/2 and hide/2" do
    test "show returns a JS show command targeting the selector" do
      assert %JS{ops: [["show", %{to: "#modal"}]]} = show("#modal")
    end

    test "hide returns a JS hide command targeting the selector" do
      assert %JS{ops: [["hide", %{to: "#modal"}]]} = hide("#modal")
    end
  end

  describe "translate_error/1" do
    test "interpolates bindings without configured translator" do
      assert translate_error({"should be at least %{count} characters", count: 3}) ==
               "should be at least 3 characters"
    end

    test "returns the message unchanged when there are no bindings" do
      assert translate_error({"is invalid", []}) == "is invalid"
    end

    test "uses the configured MFA translator" do
      Application.put_env(:shadcn_daisyui, :translate_error, {Translator, :translate})
      on_exit(fn -> Application.delete_env(:shadcn_daisyui, :translate_error) end)

      assert translate_error({"is invalid", []}) == "T:is invalid"
    end

    test "form components translate through the configured MFA" do
      Application.put_env(:shadcn_daisyui, :translate_error, {Translator, :translate})
      on_exit(fn -> Application.delete_env(:shadcn_daisyui, :translate_error) end)

      form =
        to_form(%{"email" => ""},
          as: :user,
          errors: [email: {"boom", []}],
          action: :validate
        )

      assigns = %{form: form}
      html = render(~H|<.input field={@form[:email]} type="email" />|)

      assert html =~ "T:boom"
    end
  end

  describe "translate_errors/2" do
    test "translates all errors for the given field" do
      errors = [email: {"can't be blank", []}, name: {"too long", []}, email: {"bad", []}]

      assert translate_errors(errors, :email) == ["can't be blank", "bad"]
      assert translate_errors(errors, :name) == ["too long"]
      assert translate_errors(errors, :missing) == []
    end
  end
end
