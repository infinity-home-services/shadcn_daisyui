defmodule ShadcnDaisyui.UsingMacroTest.Delegating do
  use ShadcnDaisyui.CoreComponents
end

defmodule ShadcnDaisyui.UsingMacroTest.Overriding do
  use ShadcnDaisyui.CoreComponents

  def header(assigns) do
    ~H"""
    <header class="my-custom-header">{render_slot(@inner_block)}</header>
    """
  end
end

# Phoenix 1.8 generates theme_toggle/1 in every app's Layouts, and templates
# there `use ShadcnDaisyui.Components`: the import must leave it out, or this
# module wouldn't compile ("imported ... conflicts with local function").
defmodule ShadcnDaisyui.UsingMacroTest.Layouts do
  use Phoenix.Component
  use ShadcnDaisyui.Components

  def theme_toggle(assigns), do: ~H|<div id="my-theme-toggle"></div>|

  def app(assigns) do
    ~H"""
    <.app_shell nav={[]} person={%{name: "A B"}}>
      <.theme_toggle />
    </.app_shell>
    """
  end
end

# The usual app setup: an app's CoreComponents keeps its own page_header
# (computing the crumbs) over the wrapped one.
defmodule ShadcnDaisyui.UsingMacroTest.CrumbsHeader do
  use ShadcnDaisyui.CoreComponents

  attr(:page, :string, required: true)
  slot(:inner_block, required: true)

  def page_header(assigns) do
    assigns = assign(assigns, :crumbs, [%{label: "Group"}, %{label: assigns.page}])
    ShadcnDaisyui.CoreComponents.page_header(assigns)
  end
end

defmodule ShadcnDaisyui.UsingMacroTest do
  use ExUnit.Case, async: true

  import Phoenix.Component

  alias Phoenix.LiveView.JS
  alias ShadcnDaisyui.UsingMacroTest.Delegating
  alias ShadcnDaisyui.UsingMacroTest.Overriding

  defp render(template) do
    template |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  test "the using module exports all wrapped components" do
    for fun <- [
          :flash,
          :button,
          :input,
          :error,
          :header,
          :page_header,
          :sticky_top,
          :table,
          :list,
          :icon
        ] do
      assert function_exported?(Delegating, fun, 1), "expected #{fun}/1 to be exported"
    end
  end

  test "flash_group is deliberately not wrapped" do
    refute function_exported?(Delegating, :flash_group, 1)
  end

  describe "delegation" do
    test "button renders through the wrapper with variants and defaults" do
      assigns = %{}
      html = render(~H|<Delegating.button variant="outline" size="sm">Hi</Delegating.button>|)

      assert html =~ "btn btn-outline btn-sm"
      assert html =~ "Hi"
    end

    test "button defaults are applied even without compile-time attr metadata" do
      assigns = %{}
      assert render(~H|<Delegating.button>Go</Delegating.button>|) =~ "btn btn-primary"
    end

    test "icon renders through the wrapper" do
      assigns = %{}
      html = render(~H|<Delegating.icon name="hero-x-mark" />|)

      assert html =~ "hero-x-mark size-4"
    end

    test "input renders through the wrapper with a form field" do
      assigns = %{form: to_form(%{"email" => "hi"}, as: :user)}
      html = render(~H|<Delegating.input field={@form[:email]} type="email" />|)

      assert html =~ ~s(id="user_email")
      assert html =~ ~s(name="user[email]")
      assert html =~ ~s(value="hi")
    end

    test "header renders the default markup" do
      assigns = %{}
      html = render(~H|<Delegating.header>Title</Delegating.header>|)

      assert html =~ "<h1"
      assert html =~ "Title"
    end

    test "error renders through the wrapper" do
      assigns = %{}
      assert render(~H|<Delegating.error>oops</Delegating.error>|) =~ "text-error"
    end

    test "show and hide delegate to the JS commands" do
      assert %JS{ops: [["show", %{to: "#x"}]]} = Delegating.show("#x")
      assert %JS{ops: [["hide", %{to: "#x"}]]} = Delegating.hide("#x")
    end

    test "translate_error and translate_errors delegate" do
      assert Delegating.translate_error({"at least %{count}", count: 2}) == "at least 2"
      assert Delegating.translate_errors([email: {"boom", []}], :email) == ["boom"]
    end
  end

  describe "use ShadcnDaisyui.Components" do
    alias ShadcnDaisyui.UsingMacroTest.Layouts

    test "imports app_shell but leaves theme_toggle to the app's Layouts" do
      assigns = %{}
      html = render(~H|<Layouts.app />|)

      assert html =~ ~s(id="shell")
      assert html =~ ~s(<div id="my-theme-toggle"></div>)
    end
  end

  describe "overriding" do
    test "an app's page_header wrapper computes the crumbs and calls the package's" do
      assigns = %{}

      html =
        render(~H"""
        <ShadcnDaisyui.UsingMacroTest.CrumbsHeader.page_header page="Orders">
          Orders
        </ShadcnDaisyui.UsingMacroTest.CrumbsHeader.page_header>
        """)

      assert html =~ "<span>Group</span>"
      assert html =~ ~s(<span aria-current="page">Orders</span>)
      assert html =~ "page-header-title"
    end

    test "a locally redefined component replaces the wrapper" do
      assigns = %{}
      html = render(~H|<Overriding.header>Custom</Overriding.header>|)

      assert html =~ "my-custom-header"
      assert html =~ "Custom"
      refute html =~ "<h1"
    end

    test "other components still delegate in the overriding module" do
      assigns = %{}
      html = render(~H|<Overriding.button variant="destructive">Del</Overriding.button>|)

      assert html =~ "btn btn-error"
      assert html =~ "Del"
    end
  end
end
