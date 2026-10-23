# The package has no JSON dependency; rendering %Phoenix.LiveView.JS{}
# attributes (flash close, row_click, …) goes through Phoenix.json_library().
# Point it at the JSON module that ships with Elixir >= 1.18.
Application.put_env(:phoenix, :json_library, JSON)

defmodule ShadcnDaisyui.ChromeSlots do
  @moduledoc false
  # The *_browser_test files each run a page in headless Chrome. Eight at once
  # on a 4-core CI runner starve each other past the harness's timeout, so
  # they share a few slots: half the schedulers, at least two.
  @slots max(2, div(System.schedulers_online(), 2))

  def run(fun) do
    slot = acquire()

    try do
      fun.()
    after
      :global.del_lock({{__MODULE__, slot}, self()}, [node()])
    end
  end

  defp acquire do
    Enum.find(1..@slots, &:global.set_lock({{__MODULE__, &1}, self()}, [node()], 0)) ||
      (Process.sleep(25) && acquire())
  end
end

ExUnit.start()
