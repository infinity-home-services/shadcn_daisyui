# The package has no JSON dependency; rendering %Phoenix.LiveView.JS{}
# attributes (flash close, row_click, …) goes through Phoenix.json_library().
# Point it at the JSON module that ships with Elixir >= 1.18.
Application.put_env(:phoenix, :json_library, JSON)

ExUnit.start()
