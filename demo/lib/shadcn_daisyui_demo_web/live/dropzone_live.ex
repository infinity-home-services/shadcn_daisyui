defmodule ShadcnDaisyuiDemoWeb.DropzoneLive do
  @moduledoc """
  `/lab/dropzone` (not in the static export): `<.dropzone>` on real LiveView
  uploads. A CSV import (one file, picked files wait for Import), attachments
  that upload as soon as they're picked (three files, images or PDFs, with
  progress), a compact logo picker, a disabled zone, and a plain form's zone
  (`name`, no LiveView upload) that takes drops through the hook.
  """
  use ShadcnDaisyuiDemoWeb, :live_view

  import ShadcnDaisyui.FormComponents, only: [dropzone: 1]
  import ShadcnDaisyui.Components.Display, only: [push_toast: 3]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Dropzone", imported: nil)
     |> allow_upload(:people_csv, accept: ~w(.csv), max_entries: 1, max_file_size: 1_000_000)
     |> allow_upload(:files,
       accept: ~w(image/* .pdf),
       max_entries: 3,
       max_file_size: 8_000_000,
       auto_upload: true
     )
     |> allow_upload(:logo, accept: ~w(.png .svg), max_entries: 1, max_file_size: 500_000)
     |> allow_upload(:locked, accept: ~w(.csv), max_entries: 1)}
  end

  @impl true
  def handle_event("validate", _params, socket), do: {:noreply, socket}

  def handle_event("cancel", %{"upload" => name, "ref" => ref}, socket),
    do: {:noreply, cancel_upload(socket, String.to_existing_atom(name), ref)}

  def handle_event("import", _params, socket) do
    rows =
      consume_uploaded_entries(socket, :people_csv, fn %{path: path}, _entry ->
        {:ok, path |> File.read!() |> String.split("\n", trim: true) |> length()}
      end)

    case rows do
      [count] ->
        {:noreply,
         socket
         |> assign(imported: count)
         |> push_toast("Imported #{count} rows", type: :success)}

      [] ->
        {:noreply, push_toast(socket, "Choose a CSV file first", type: :error)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="mx-auto max-w-xl space-y-12 px-4 py-12 sm:px-6">
      <div class="space-y-1">
        <h1 class="text-3xl font-bold tracking-tight">Dropzone</h1>
        <p class="text-sm text-muted-foreground">
          Real LiveView uploads: drag files onto a zone, or click it (Enter or Space) to choose.
        </p>
      </div>

      <section class="space-y-4">
        <h2 class="border-b border-border pb-2 text-xl font-semibold tracking-tight">Import</h2>
        <.form for={%{}} id="import-form" phx-change="validate" phx-submit="import" class="space-y-4">
          <.dropzone
            id="import-file"
            upload={@uploads.people_csv}
            on_cancel={JS.push("cancel", value: %{upload: "people_csv"})}
          >
            <:title touch="Choose a CSV file">Drop a CSV file here, or choose one</:title>
          </.dropzone>
          <div class="flex items-center gap-3">
            <.button type="submit" phx-disable-with="Importing…">Import</.button>
            <p :if={@imported} id="imported" class="text-sm text-muted-foreground">
              Imported {@imported} rows.
            </p>
          </div>
        </.form>
      </section>

      <section class="space-y-4">
        <h2 class="border-b border-border pb-2 text-xl font-semibold tracking-tight">
          Attachments (upload as picked)
        </h2>
        <.form for={%{}} id="files-form" phx-change="validate">
          <.dropzone
            id="attachments"
            upload={@uploads.files}
            on_cancel={JS.push("cancel", value: %{upload: "files"})}
          />
        </.form>
      </section>

      <section class="space-y-4">
        <h2 class="border-b border-border pb-2 text-xl font-semibold tracking-tight">Compact</h2>
        <.form for={%{}} id="logo-form" phx-change="validate" class="max-w-md space-y-2">
          <label for={@uploads.logo.ref} class="text-sm font-medium">Logo</label>
          <.dropzone
            id="logo"
            upload={@uploads.logo}
            size="compact"
            on_cancel={JS.push("cancel", value: %{upload: "logo"})}
          />
        </.form>
      </section>

      <section class="space-y-4">
        <h2 class="border-b border-border pb-2 text-xl font-semibold tracking-tight">Disabled</h2>
        <.form for={%{}} id="locked-form" phx-change="validate">
          <.dropzone id="locked" upload={@uploads.locked} disabled />
        </.form>
      </section>

      <section class="space-y-4">
        <h2 class="border-b border-border pb-2 text-xl font-semibold tracking-tight">
          Plain form
        </h2>
        <form id="plain-form" action="#" class="space-y-4">
          <.dropzone id="plain" name="documents" accept=".pdf,.txt" multiple />
          <button type="reset" class="btn btn-outline btn-sm">Reset</button>
        </form>
      </section>
    </main>
    """
  end
end
