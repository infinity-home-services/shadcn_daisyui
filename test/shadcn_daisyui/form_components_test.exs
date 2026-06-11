defmodule ShadcnDaisyui.FormComponentsTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.FormComponents

  defp render(template) do
    template |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  defp count(html, substring) do
    html |> String.split(substring) |> length() |> Kernel.-(1)
  end

  defp error_form(params) do
    to_form(params,
      as: :user,
      errors: [email: {"can't be blank", []}],
      action: :validate
    )
  end

  describe "label/1" do
    test "renders a label with the for attribute" do
      assigns = %{}
      html = render(~H|<.label for="user_email">Email</.label>|)

      assert html =~ ~r/<label for="user_email" class="text-sm font-medium\s*">Email<\/label>/
    end
  end

  describe "field derivation" do
    test "textarea derives id, name, and value from the form field" do
      assigns = %{form: to_form(%{"bio" => "hello bio"}, as: :user)}
      html = render(~H|<.textarea field={@form[:bio]} label="Bio" />|)

      assert html =~ ~s(id="user_bio")
      assert html =~ ~s(name="user[bio]")
      assert html =~ "hello bio"
      assert html =~ "textarea w-full"
      assert html =~ ~s(for="user_bio")
    end

    test "explicit id, name, and value override the field" do
      assigns = %{form: to_form(%{"bio" => "from field"}, as: :user)}

      html =
        render(
          ~H|<.textarea field={@form[:bio]} id="custom-id" name="custom" value="explicit" />|
        )

      assert html =~ ~s(id="custom-id")
      assert html =~ ~s(name="custom")
      assert html =~ "explicit"
      refute html =~ "from field"
    end
  end

  describe "error rendering and used_input? gating" do
    test "errors render when the input was used (param present)" do
      assigns = %{form: error_form(%{"email" => ""})}
      html = render(~H|<.textarea field={@form[:email]} />|)

      assert html =~ "can&#39;t be blank"
      assert html =~ "textarea-error"
    end

    test "errors are hidden when the param is marked unused" do
      assigns = %{form: error_form(%{"email" => "", "_unused_email" => ""})}
      html = render(~H|<.textarea field={@form[:email]} />|)

      refute html =~ "can&#39;t be blank"
      refute html =~ "textarea-error"
    end

    test "errors are hidden when the param is absent entirely" do
      assigns = %{form: error_form(%{})}
      html = render(~H|<.textarea field={@form[:email]} />|)

      refute html =~ "can&#39;t be blank"
    end
  end

  describe "field/1" do
    test "wires label, description, and error ids with aria attributes" do
      assigns = %{form: error_form(%{"email" => ""})}

      html =
        render(~H"""
        <.field field={@form[:email]} label="Email" description="We never share it." :let={f}>
          <input id={f.id} aria-describedby={f.describedby} />
        </.field>
        """)

      assert html =~ ~s(aria-invalid="true")
      assert html =~ ~s(aria-describedby="user_email-description user_email-error")
      assert html =~ ~s(<label for="user_email")
      assert html =~ ~s(id="user_email-description")
      assert html =~ "We never share it."
      assert html =~ ~s(id="user_email-error")
      assert html =~ "can&#39;t be blank"
    end

    test "without errors there is no aria-invalid or error container" do
      assigns = %{form: to_form(%{"email" => "hi"}, as: :user)}

      html =
        render(~H"""
        <.field field={@form[:email]} label="Email" description="Desc" :let={f}>
          <input id={f.id} aria-describedby={f.describedby} />
        </.field>
        """)

      refute html =~ "aria-invalid"
      assert html =~ ~s(aria-describedby="user_email-description")
      refute html =~ "user_email-error"
    end

    test "without description or errors no aria-describedby is set" do
      assigns = %{form: to_form(%{"email" => "hi"}, as: :user)}

      html =
        render(~H"""
        <.field field={@form[:email]} label="Email">
          <input />
        </.field>
        """)

      refute html =~ "aria-describedby"
      refute html =~ "user_email-description"
    end

    test "passes errors to the inner block" do
      assigns = %{form: error_form(%{"email" => ""})}

      html =
        render(~H"""
        <.field field={@form[:email]} :let={f}>
          <span data-errors={Enum.join(f.errors, ",")} />
        </.field>
        """)

      assert html =~ ~s(data-errors="can&#39;t be blank")
    end
  end

  describe "checkbox/1" do
    test "renders the hidden false input and normalizes the checked state" do
      assigns = %{form: to_form(%{"active" => "true"}, as: :user)}
      html = render(~H|<.checkbox field={@form[:active]} label="Active" />|)

      assert html =~ ~s(<input type="hidden" name="user[active]" value="false">)
      assert html =~ ~r/type="checkbox"[^>]*checked/
      assert html =~ ~s(id="user_active")
      assert html =~ ~s(value="true")
      assert html =~ "checkbox checkbox-sm"
      assert html =~ "Active"
    end

    test "is unchecked for a false value" do
      assigns = %{form: to_form(%{"active" => "false"}, as: :user)}
      html = render(~H|<.checkbox field={@form[:active]} label="Active" />|)

      refute html =~ ~r/type="checkbox"[^>]*checked/
    end

    test "explicit checked overrides the value" do
      assigns = %{}
      html = render(~H|<.checkbox name="x" checked label="X" />|)

      assert html =~ ~r/type="checkbox"[^>]*checked/
    end

    test "renders the description" do
      assigns = %{}
      html = render(~H|<.checkbox name="x" label="X" description="Optional thing" />|)

      assert html =~ "Optional thing"
    end
  end

  describe "switch/1" do
    test "renders a daisyUI toggle bound to the field" do
      assigns = %{form: to_form(%{"notifications" => true}, as: :user)}
      html = render(~H|<.switch field={@form[:notifications]} label="Email notifications" />|)

      assert html =~ ~s(<input type="hidden" name="user[notifications]" value="false">)
      assert html =~ ~r/type="checkbox"[^>]*checked/
      assert html =~ "toggle"
      refute html =~ "checkbox checkbox-sm"
      assert html =~ "Email notifications"
    end
  end

  describe "radio_group/1" do
    test "checks the radio matching the field value" do
      assigns = %{form: to_form(%{"plan" => "pro"}, as: :user)}

      html =
        render(~H"""
        <.radio_group field={@form[:plan]} label="Plan">
          <:radio value="free">Free</:radio>
          <:radio value="pro">Pro</:radio>
        </.radio_group>
        """)

      assert html =~ "<legend"
      assert html =~ "Plan"
      assert count(html, ~s(type="radio")) == 2
      assert count(html, ~s(name="user[plan]")) == 2
      assert html =~ ~s(id="user_plan-0")
      assert html =~ ~s(id="user_plan-1")
      assert html =~ ~s(value="pro" checked)
      refute html =~ ~s(value="free" checked)
      assert html =~ "Free"
      assert html =~ "Pro"
    end
  end

  describe "native_select/1" do
    test "renders prompt, options, and the selected value" do
      assigns = %{form: to_form(%{"role" => "member"}, as: :user)}

      html =
        render(
          ~H|<.native_select field={@form[:role]} label="Role" prompt="Pick one" options={["admin", "member"]} />|
        )

      assert html =~ ~s(id="user_role")
      assert html =~ ~s(name="user[role]")
      assert html =~ "select w-full"
      assert html =~ ~s(<option value="">Pick one</option>)
      assert html =~ ~s(value="admin")
      assert html =~ ~r/selected[^>]*value="member"|value="member"[^>]*selected/
    end

    test "multiple appends [] to the name" do
      assigns = %{form: to_form(%{}, as: :user)}

      html =
        render(~H|<.native_select field={@form[:roles]} multiple options={["a", "b"]} />|)

      assert html =~ ~s(name="user[roles][]")
      assert html =~ "multiple"
    end

    test "adds select-error when the field has used errors" do
      assigns = %{
        form:
          to_form(%{"role" => ""},
            as: :user,
            errors: [role: {"is required", []}],
            action: :validate
          )
      }

      html = render(~H|<.native_select field={@form[:role]} options={["a"]} />|)

      assert html =~ "select-error"
      assert html =~ "is required"
    end
  end

  describe "textarea/1" do
    test "renders without a field" do
      assigns = %{}
      html = render(~H|<.textarea name="note" value="jot" label="Note" />|)

      assert html =~ ~s(name="note")
      assert html =~ "jot"
      assert html =~ "Note"
      refute html =~ "textarea-error"
    end
  end
end
