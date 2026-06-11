defmodule ShadcnDaisyui.Install.PatcherTest do
  use ExUnit.Case, async: true

  alias ShadcnDaisyui.Install.Patcher

  @app_css """
  @import "tailwindcss" source(none);
  @source "../css";
  @source "../js";
  @source "../../lib/my_app_web";
  @plugin "../vendor/heroicons";
  @plugin "../vendor/daisyui" {
    themes: ["light --default", "dark --prefersdark"];
  }
  """

  @app_js """
  import "phoenix_html"
  import {Socket} from "phoenix"
  import {LiveSocket} from "phoenix_live_view"
  import topbar from "../vendor/topbar"
  import {hooks as colocatedHooks} from "phoenix-colocated/my_app"

  const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
  const liveSocket = new LiveSocket("/live", Socket, {
    longPollFallbackMs: 2500,
    params: {_csrf_token: csrfToken},
    hooks: {...colocatedHooks},
  })
  """

  describe "patch_app_css/2" do
    test "deps mode: themes off, deps import, @source, dark variant" do
      css = Patcher.patch_app_css(@app_css, :deps)

      assert css =~ "themes: false;"
      refute css =~ "--prefersdark"
      assert css =~ ~s(@import "../../deps/shadcn_daisyui/priv/static/shadcn-daisyui.css";)
      assert css =~ ~s(@source "../../deps/shadcn_daisyui/lib";)
      assert css =~ "@custom-variant dark (&:where([data-theme=shadcn-dark]"
    end

    test "copy mode: local import, no deps @source" do
      css = Patcher.patch_app_css(@app_css, :copy)

      assert css =~ ~s(@import "./shadcn-daisyui.css";)
      refute css =~ "deps/shadcn_daisyui/lib"
    end

    test "import lands right after the daisyui plugin block" do
      css = Patcher.patch_app_css(@app_css, :deps)
      [before_import, _] = String.split(css, "shadcn-daisyui.css", parts: 2)
      assert before_import =~ "daisyui"
    end

    test "is idempotent" do
      once = Patcher.patch_app_css(@app_css, :deps)
      assert Patcher.patch_app_css(once, :deps) == once
    end

    test "replaces an existing dark @custom-variant" do
      css = @app_css <> "@custom-variant dark (&:where(.dark, .dark *));\n"
      patched = Patcher.patch_app_css(css, :deps)

      assert patched =~ "[data-theme=shadcn-dark]"
      refute patched =~ "@custom-variant dark (&:where(.dark, .dark *));"
    end
  end

  describe "patch_app_js/2" do
    test "adds the import after the last import and merges into existing hooks" do
      assert {:ok, js} = Patcher.patch_app_js(@app_js, :deps)

      assert js =~ ~s(import { Hooks as ShadcnHooks } from "shadcn_daisyui")
      assert js =~ "hooks: { ...ShadcnHooks, ...colocatedHooks},"

      # import comes after the existing imports, before the LiveSocket
      {import_pos, _} = :binary.match(js, "ShadcnHooks } from")
      {socket_pos, _} = :binary.match(js, "new LiveSocket")
      {topbar_pos, _} = :binary.match(js, "topbar from")
      assert import_pos > topbar_pos
      assert import_pos < socket_pos
    end

    test "copy mode imports from the local file" do
      assert {:ok, js} = Patcher.patch_app_js(@app_js, :copy)
      assert js =~ ~s(import { Hooks as ShadcnHooks } from "./shadcn-daisyui")
    end

    test "adds a hooks option when none exists" do
      no_hooks = Regex.replace(~r/^\s*hooks:.*\n/m, @app_js, "")
      refute no_hooks =~ "hooks:"
      assert {:ok, js} = Patcher.patch_app_js(no_hooks, :deps)
      assert js =~ "hooks: { ...ShadcnHooks },"
    end

    test "errors when no LiveSocket is found" do
      assert {:error, :livesocket_not_found} =
               Patcher.patch_app_js("import \"phoenix_html\"\nconsole.log(1)\n", :deps)
    end

    test "is idempotent" do
      {:ok, once} = Patcher.patch_app_js(@app_js, :deps)
      assert {:ok, ^once} = Patcher.patch_app_js(once, :deps)
    end
  end

  describe "patch_root_layout/1" do
    test "adds data-theme to <html>" do
      heex = ~s(<html lang="en" class={[@theme]}>\n<body></body>\n</html>)
      assert Patcher.patch_root_layout(heex) =~ ~s(<html data-theme="shadcn" lang="en")
    end

    test "leaves an existing data-theme alone" do
      heex = ~s(<html lang="en" data-theme="custom">)
      assert Patcher.patch_root_layout(heex) == heex
    end

    test "leaves Phoenix 1.8 stock layouts alone (client-side theme script)" do
      heex = """
      <html lang="en">
        <script>
          window.addEventListener("phx:set-theme", (e) => setTheme(e.target.dataset.phxTheme));
        </script>
      </html>
      """

      assert Patcher.patch_root_layout(heex) == heex
    end
  end

  describe "patch_web_module/1" do
    test "adds use ShadcnDaisyui.Components after the CoreComponents import" do
      source = """
      defp html_helpers do
        quote do
          use Gettext, backend: MyAppWeb.Gettext
          import Phoenix.HTML
          import MyAppWeb.CoreComponents
          import Phoenix.LiveView.Helpers
        end
      end
      """

      patched = Patcher.patch_web_module(source)
      assert patched =~ "import MyAppWeb.CoreComponents\n      use ShadcnDaisyui.Components"
      assert Patcher.patch_web_module(patched) == patched
    end
  end

  describe "core_components_source/1" do
    @original """
    defmodule MyAppWeb.CoreComponents do
      use Phoenix.Component
      use Gettext, backend: MyAppWeb.Gettext

      def input(assigns), do: nil
    end
    """

    test "builds a thin module preserving the gettext backend" do
      assert {:ok, "MyAppWeb.CoreComponents", source} =
               Patcher.core_components_source(@original)

      assert source =~ "defmodule MyAppWeb.CoreComponents do"
      assert source =~ "use ShadcnDaisyui.CoreComponents"
      assert source =~ "use Gettext, backend: MyAppWeb.Gettext"
      assert source =~ "Gettext.dngettext(MyAppWeb.Gettext"

      # the generated module must be valid Elixir
      assert {_quoted, []} = Code.string_to_quoted_with_comments!(source) |> then(&{&1, []})
    end

    test "builds a plain thin module without gettext" do
      original = "defmodule MyAppWeb.CoreComponents do\n  use Phoenix.Component\nend\n"
      assert {:ok, _, source} = Patcher.core_components_source(original)
      refute source =~ "Gettext"
    end

    test "errors on unparseable source" do
      assert {:error, :module_not_found} = Patcher.core_components_source("not elixir")
    end
  end

  describe "patch_config/2" do
    test "inserts before import_config and is idempotent" do
      config = """
      import Config

      config :my_app, ecto_repos: [MyApp.Repo]

      import_config "\#{config_env()}.exs"
      """

      patched = Patcher.patch_config(config, "MyAppWeb.CoreComponents")

      assert patched =~
               "config :shadcn_daisyui, :translate_error, {MyAppWeb.CoreComponents, :translate_error}"

      [before_import, _] = String.split(patched, "import_config", parts: 2)
      assert before_import =~ ":shadcn_daisyui"
      assert Patcher.patch_config(patched, "MyAppWeb.CoreComponents") == patched
    end
  end

  describe "theme helpers" do
    test "ensure_theme_import places the import after the base theme" do
      css = ~s(@import "../../deps/shadcn_daisyui/priv/static/shadcn-daisyui.css";\n)
      patched = Patcher.ensure_theme_import(css, "ihs")
      assert patched =~ ~s(shadcn-daisyui.css";\n@import "./themes/ihs.css";)
      assert Patcher.ensure_theme_import(patched, "ihs") == patched
    end

    test "add_theme_to_dark_variant extends the variant" do
      css =
        "@custom-variant dark (&:where([data-theme=shadcn-dark], [data-theme=shadcn-dark] *, .dark, .dark *));\n"

      patched = Patcher.add_theme_to_dark_variant(css, "ihs")
      assert patched =~ "[data-theme=ihs-dark], [data-theme=ihs-dark] *, [data-theme=shadcn-dark]"
      assert Patcher.add_theme_to_dark_variant(patched, "ihs") == patched
    end

    test "set_root_theme replaces an existing theme" do
      heex = ~s(<html lang="en" data-theme="shadcn">)
      assert Patcher.set_root_theme(heex, "ihs") == ~s(<html lang="en" data-theme="ihs">)
      assert Patcher.set_root_theme(~s(<html lang="en">), "ihs") =~ ~s(data-theme="ihs")
    end
  end
end
