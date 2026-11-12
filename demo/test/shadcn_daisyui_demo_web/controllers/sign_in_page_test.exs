defmodule ShadcnDaisyuiDemoWeb.SignInPageTest do
  use ShadcnDaisyuiDemoWeb.ConnCase

  alias ShadcnDaisyuiDemoWeb.SignInPreview

  describe "/docs/sign-in" do
    test "shows the page at each size, every state, the usage and the notices", %{conn: conn} do
      html = conn |> get(~p"/docs/sign-in") |> html_response(200)

      assert html =~ "Sign-in page"

      for size <- ~w(desktop tablet phone) do
        assert html =~ ~s(class="preview-frame" data-size="#{size}")
      end

      # every state, at every size (the tabs pick which shows)
      for state <- SignInPreview.states() do
        assert html =~ state.title |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
        assert html =~ ~s(src="/docs/sign-in/preview/#{state.slug}")
      end

      assert html =~ "&lt;.sign_in_page"
      assert html =~ "put_flash(:sign_in"
      assert html =~ "--sign-in-accent"
      assert html =~ ~s(data-brand=&quot;acme&quot;)
      # the notices table comes from the component, so it can't drift
      assert html =~ "You don&#39;t have access to Atlas yet. Your manager gives access."
      # listed with the other guides in the sidebar
      assert html =~ ~s(href="/docs/sign-in")
    end
  end

  describe "/docs/sign-in/preview/:state" do
    test "every state renders the page on its own, with its notice", %{conn: conn} do
      for state <- SignInPreview.states() do
        html = conn |> get(~p"/docs/sign-in/preview/#{state.slug}") |> html_response(200)

        assert html =~ ~s(<main id="sign-in" class="sign-in)
        assert html =~ "Sign in to Atlas"
        assert html =~ ~s(<img class="sign-in-aside-image" src="/images/sign-in-background.svg")
        # no docs search inside the iframe
        refute html =~ "docs-search-palette"

        cond do
          state.notice -> assert html =~ ~s(data-notice="#{state.notice}")
          not state.configured -> assert html =~ ~s(data-notice="not_configured")
          true -> refute html =~ "sign-in-notice"
        end

        assert html =~ "sign-in-development" == state.development
      end
    end

    test "the development state has sections people can hide", %{conn: conn} do
      html = conn |> get(~p"/docs/sign-in/preview/development") |> html_response(200)

      assert html =~ ~s(data-sign-in-section="sign-in-as-a-role")
      assert html =~ ~s(data-sign-in-section="sign-in-as-someone-already-here")
    end

    test "?theme pins a theme for screenshots; anything else is ignored", %{conn: conn} do
      html =
        conn |> get(~p"/docs/sign-in/preview/signed-out?theme=shadcn-dark") |> html_response(200)

      assert html =~ ~s(<html lang="en" data-theme="shadcn-dark">)

      html = conn |> get(~p"/docs/sign-in/preview/signed-out?theme=cupcake") |> html_response(200)
      assert html =~ ~s(<html lang="en">)
    end

    test "an unknown state is a 404", %{conn: conn} do
      assert conn |> get(~p"/docs/sign-in/preview/nope") |> html_response(404)
    end
  end
end
