defmodule ShadcnDaisyui.Translate do
  @moduledoc false
  # Error translation for form components. The package cannot depend on the
  # consuming app's Gettext backend, so apps point us at their translator:
  #
  #     config :shadcn_daisyui, :translate_error, {MyAppWeb.CoreComponents, :translate_error}
  #
  # Without config we interpolate `%{key}` bindings directly (no translation).

  def translate_error({msg, opts}) do
    case Application.get_env(:shadcn_daisyui, :translate_error) do
      {mod, fun} ->
        apply(mod, fun, [{msg, opts}])

      nil ->
        Enum.reduce(opts, msg, fn {key, value}, acc ->
          String.replace(acc, "%{#{key}}", to_string(value))
        end)
    end
  end
end
