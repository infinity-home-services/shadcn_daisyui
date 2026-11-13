defmodule ShadcnDaisyui.Components.SignInTest do
  use ExUnit.Case, async: true

  doctest ShadcnDaisyui.Components.SignIn

  import Phoenix.Component
  import ShadcnDaisyui.Components.SignIn

  defp render(template), do: template |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()

  defp count(html, substring), do: html |> String.split(substring) |> length() |> Kernel.-(1)

  defp page(attrs) do
    assigns = Map.merge(%{app_name: "Acme", href: "/auth/entra"}, Map.new(attrs))

    render(~H"""
    <.sign_in_page {assigns} />
    """)
  end

  describe "sign_in_page/1" do
    test "the whole page: a main landmark, the app's name, Sign in with Microsoft" do
      html = page(org: "Acme Inc.")

      assert html =~ ~s(<main id="sign-in" class="sign-in)
      assert html =~ ~s(<h1 class="sign-in-title">Sign in to Acme</h1>)
      assert html =~ "With your Microsoft work account."

      assert html =~
               ~r/<a id="sign-in-microsoft" href="\/auth\/entra" class="btn sign-in-microsoft">/

      assert html =~ "Sign in with Microsoft"
      assert html =~ ~s(class="sign-in-microsoft-logo")
      refute html =~ "sign-in-notice"
      refute html =~ "sign-in-development"
    end

    test "the desktop panel names the org, the application and its tagline" do
      html = page(org: "Acme Inc.", tagline: "Orders in one place.")

      assert html =~ ~s(<aside class="sign-in-aside">)
      assert html =~ ~s(<p class="sign-in-org">Acme Inc.</p>)
      assert html =~ ~s(<p class="sign-in-app-name">Acme</p>)
      assert html =~ ~s(<span class="sign-in-rule" aria-hidden="true"></span>)
      assert html =~ ~s(<p class="sign-in-tagline">Orders in one place.</p>)
      # and the org under the form (phones and tablets; the panel has it on desktops)
      assert html =~ ~s(<span class="sign-in-footer-org">Acme Inc.</span>)
    end

    test "no org or tagline: the panel is the app's name alone, and no footer" do
      html = page([])

      assert html =~ ~s(<p class="sign-in-app-name">Acme</p>)
      refute html =~ "sign-in-org"
      refute html =~ "sign-in-rule"
      refute html =~ "sign-in-tagline"
      refute html =~ "sign-in-footer"
    end

    test "a picture behind the panel" do
      html = page(image: "/images/bg.jpg")

      assert html =~ ~s(<aside class="sign-in-aside" data-image="true">)
      assert html =~ ~s(<img class="sign-in-aside-image" src="/images/bg.jpg" alt="">)
      refute page([]) =~ "sign-in-aside-image"
    end

    test "the app's name and copy are escaped" do
      html = page(app_name: "<b>Acme</b>", tagline: "<i>x</i>")

      assert html =~ "Sign in to &lt;b&gt;Acme&lt;/b&gt;"
      assert html =~ "&lt;i&gt;x&lt;/i&gt;"
      refute html =~ "<b>Acme</b>"
    end

    test "description and id override the defaults" do
      html = page(id: "login", description: "With your Acme account.")

      assert html =~ ~s(<main id="login")
      assert html =~ "With your Acme account."
      refute html =~ "With your Microsoft work account."
    end

    test "the icon tile is the mark unless there's a logo" do
      assigns = %{}

      assert page(icon: "hero-bolt") =~ ~s(<span class="hero-bolt" aria-hidden="true">)

      html =
        render(~H"""
        <.sign_in_page app_name="Acme">
          <:logo><img src="/mark.svg" alt="" /></:logo>
        </.sign_in_page>
        """)

      assert html =~ ~s(<img src="/mark.svg" alt="">)
      refute html =~ "sign-in-tile"
      refute html =~ "hero-cube"
    end

    test "a panel of the app's own replaces the org, name, rule and tagline" do
      assigns = %{}

      html =
        render(~H"""
        <.sign_in_page app_name="Acme" org="Acme Inc." tagline="Hidden">
          <:panel><p class="sign-in-app-name">Acme <span>Ops</span></p></:panel>
        </.sign_in_page>
        """)

      assert html =~ ~s(<p class="sign-in-app-name">Acme <span>Ops</span></p>)
      refute html =~ ~s(<p class="sign-in-org">)
      refute html =~ "Hidden"
    end
  end

  describe "notices" do
    test "the keys it words" do
      assert notices() ==
               ~w(signed_out unavailable canceled failed no_access ended not_configured)
    end

    test "each key's wording, and red for a refusal or a failure" do
      for {key, title, description, destructive?} <- [
            {"signed_out", "You're signed out.", "Microsoft asks which account to use next time.",
             false},
            {"unavailable", "Microsoft can't be reached right now.", nil, true},
            {"canceled", "Microsoft didn't complete the sign-in.", nil, true},
            {"failed", "The sign-in didn't complete.", nil, true},
            {"no_access", "You don't have access to Acme yet.", "Your manager gives access.",
             true},
            {"ended", "Your access to Acme has ended.", nil, true},
            {"not_configured", "Microsoft sign-in isn't set up on this server.", nil, false}
          ] do
        html = page(notice: key)

        assert html =~ ~s(data-notice="#{key}"), key
        assert html =~ ~s(id="sign-in-notice"), key
        assert html =~ ~s(role="alert"), key
        assert html =~ title |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string(), key
        if description, do: assert(html =~ description, key)
        assert String.contains?(html, "alert-error") == destructive?, key
        assert count(html, ~s(id="sign-in-notice")) == 1, key
      end
    end

    test "notice/2 gives the wording, for the docs and for apps that draw it themselves" do
      assert notice("no_access", "Atlas") == %{
               variant: "destructive",
               icon: "hero-exclamation-circle",
               title: "You don't have access to Atlas yet.",
               description: "Your manager gives access."
             }

      assert notice(:signed_out, "Atlas").variant == "default"
      assert notice("zoho_inactive", "Atlas") == nil
    end

    test "an atom works as well as a string" do
      assert page(notice: :ended) =~ ~s(data-notice="ended")
    end

    test "an unknown key or nil shows nothing" do
      refute page(notice: "zoho_inactive") =~ "sign-in-notice"
      refute page(notice: :whatever) =~ "sign-in-notice"
      refute page(notice: nil) =~ "sign-in-notice"
      refute page(notice: 42) =~ "sign-in-notice"
    end

    test "an alert of the app's own can be self-closing: a title alone" do
      assigns = %{}

      html =
        render(~H"""
        <.sign_in_page app_name="Acme">
          <:alert title="Enter a name and an email." variant="destructive" />
        </.sign_in_page>
        """)

      assert html =~ ~s(data-notice="custom")
      assert html =~ "Enter a name and an email."
      assert html =~ "alert-error"
    end

    test "not set up: the button is disabled and the notice says why, whatever else came" do
      html = page(configured: false, notice: "no_access")

      assert html =~ ~s(data-notice="not_configured")
      refute html =~ "You don&#39;t have access"

      assert html =~
               ~r/<button id="sign-in-microsoft" type="button" class="btn sign-in-microsoft" disabled>/

      refute html =~ ~s(<a id="sign-in-microsoft")
    end

    test "an alert of the app's own replaces the notice" do
      assigns = %{}

      html =
        render(~H"""
        <.sign_in_page app_name="Acme" notice="ended">
          <:alert title="Your Zoho user is inactive." variant="destructive">Your brand admin reactivates it.</:alert>
        </.sign_in_page>
        """)

      assert html =~ ~s(data-notice="custom")
      assert html =~ "Your Zoho user is inactive."
      assert html =~ "Your brand admin reactivates it."
      assert html =~ "alert-error"
      refute html =~ "has ended"
      assert count(html, ~s(id="sign-in-notice")) == 1
    end
  end

  describe "development sign-in" do
    test "a section people can hide, under a divider, with the build note" do
      assigns = %{}

      html =
        render(~H"""
        <.sign_in_page app_name="Acme">
          <:development label="Sign in as a role"><button id="role-admin">Admin</button></:development>
          <:development label="Sign in as someone already here" id="people"><select id="person"></select></:development>
          <:development><p id="plain">No heading</p></:development>
        </.sign_in_page>
        """)

      assert html =~
               ~s(<details id="sign-in-development" class="sign-in-development" data-sign-in-section="development" open>)

      assert html =~ ~s(<summary class="sign-in-divider">)
      assert html =~ "Development sign-in"
      assert html =~ "Shown in development and test builds only."

      # a labelled entry is its own section, keyed by its id or its label
      assert html =~
               ~s(<details id="sign-in-development-sign-in-as-a-role" class="sign-in-section" data-sign-in-section="sign-in-as-a-role" open>)

      assert html =~
               ~s(<details id="sign-in-development-people" class="sign-in-section" data-sign-in-section="people" open>)

      assert html =~ ~s(<span>Sign in as a role</span>)
      assert html =~ ~s(<button id="role-admin">Admin</button>)
      # an unlabelled one renders as it is
      assert html =~ ~s(<div><p id="plain">No heading</p></div>)
      assert count(html, "class=\"sign-in-section\"") == 2
    end

    test "only when the app renders the slot" do
      # what an app passes: true only in development and test builds
      assigns = %{dev?: Process.get(:development_sign_in?, false)}

      html =
        render(~H"""
        <.sign_in_page app_name="Acme">
          <:development :if={@dev?}>Dev only</:development>
        </.sign_in_page>
        """)

      refute html =~ "sign-in-development"
      refute html =~ "Dev only"
    end
  end

  test "imported by use ShadcnDaisyui.Components" do
    assert {:sign_in_page, 1} in ShadcnDaisyui.Components.SignIn.__info__(:functions)

    {:ok, ast} =
      Code.string_to_quoted("""
      defmodule ShadcnDaisyui.Components.SignInTest.Using do
        use Phoenix.Component
        use ShadcnDaisyui.Components
        def page(assigns), do: ~H|<.sign_in_page app_name="Acme" />|
      end
      """)

    [{mod, _}] = Code.compile_quoted(ast)
    assert render(mod.page(%{})) =~ "Sign in to Acme"
  end
end
