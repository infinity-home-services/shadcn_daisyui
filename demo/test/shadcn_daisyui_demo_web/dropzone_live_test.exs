defmodule ShadcnDaisyuiDemoWeb.DropzoneLiveTest do
  @moduledoc """
  `<.dropzone>` on real LiveView uploads (`/lab/dropzone`): files chosen
  through the upload show as attachment tiles, progress and errors come from
  the upload, the remove button cancels an entry, and Import consumes it.
  Plus the gallery pages for the dropzone and the file input.
  """
  use ShadcnDaisyuiDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  defp csv(name \\ "people.csv", rows \\ "name,email\nA,a@x.test\nB,b@x.test\n") do
    %{name: name, content: rows, type: "text/csv"}
  end

  test "the zones render from the uploads", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/lab/dropzone")

    assert html =~ "Drop a CSV file here, or choose one"
    assert html =~ "Choose a CSV file"
    assert html =~ "One .csv file, up to 1 MB."
    assert html =~ "Up to 3 image or .pdf files, 8 MB each."
    assert html =~ "Choose a file or drop it here"
    assert has_element?(view, "#import-file label[data-dropzone-area][phx-drop-target]")
    assert has_element?(view, "#import-file[phx-hook=ShadcnDropzone]")
    assert has_element?(view, "#locked[data-disabled]")
    refute has_element?(view, "#locked [phx-drop-target]")
    assert has_element?(view, "#plain[data-dropzone=plain] input[name='documents[]']")
  end

  test "a chosen file is a tile; Import consumes it", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/lab/dropzone")

    input = file_input(view, "#import-form", :people_csv, [csv()])
    # (the test client preflights as it picks: in a browser the tile is idle
    # until Import starts the upload)
    assert render_upload(input, "people.csv", 0) =~ "people.csv"

    assert has_element?(view, "#import-file [data-slot=attachment]", "people.csv")
    assert has_element?(view, "#import-file [aria-label='Cancel people.csv']")

    render_upload(input, "people.csv", 100)

    assert has_element?(
             view,
             "#import-file [data-state=done]",
             "Uploaded · #{byte_size(csv().content)} bytes"
           )

    view |> form("#import-form") |> render_submit()
    assert has_element?(view, "#imported", "Imported 3 rows.")
    refute has_element?(view, "#import-file [data-slot=attachment]")
  end

  test "progress and done come from the upload", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/lab/dropzone")

    pdf = %{name: "report.pdf", content: String.duplicate("x", 2_000), type: "application/pdf"}
    input = file_input(view, "#files-form", :files, [pdf])

    render_upload(input, "report.pdf", 50)
    assert has_element?(view, "#attachments [data-state=uploading]", "Uploading · 50%")

    render_upload(input, "report.pdf", 50)
    assert has_element?(view, "#attachments [data-state=done]", "Uploaded · 2 KB")
  end

  test "a rejected file shows its error and the remove button cancels it", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/lab/dropzone")

    txt = %{name: "notes.txt", content: "hi", type: "text/plain"}
    input = file_input(view, "#files-form", :files, [txt])
    render_upload(input, "notes.txt")

    assert has_element?(view, "#attachments[data-invalid]")

    assert has_element?(
             view,
             "#attachments [data-state=error]",
             "Only image or .pdf files are accepted."
           )

    assert has_element?(view, "#attachments input[aria-invalid=true]")

    view |> element("#attachments [aria-label='Remove notes.txt']") |> render_click()
    refute has_element?(view, "#attachments [data-slot=attachment]")
    refute has_element?(view, "#attachments[data-invalid]")
  end

  test "too many files is an error for the whole upload, under the zone", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/lab/dropzone")

    files = for n <- 1..4, do: %{name: "f#{n}.pdf", content: "x", type: "application/pdf"}
    input = file_input(view, "#files-form", :files, files)
    render_upload(input, "f1.pdf", 0)

    assert has_element?(view, "#attachments-errors p", "Too many files. Choose up to 3.")
  end

  test "the dropzone gallery page shows every example", %{conn: conn} do
    html = conn |> get(~p"/docs/components/dropzone") |> html_response(200)

    for title <- ["Default", "Compact", "Multiple, uploading", "Errors", "Disabled", "Plain form"] do
      assert html =~ ~r{>\s*#{title}\s*</h[23]>}
    end

    assert html =~ "Uploading · 64%"
    assert html =~ "Too many files. Choose one."
    assert html =~ "That isn&#39;t a CSV file. Export the sheet as .csv first."
    assert html =~ ".fileImporter"
    assert html =~ ".dropDestination"
    # the snapshots carry no LiveView wiring
    refute html =~ "Phoenix.LiveFileUpload"
  end

  test "the input page shows the file input; attachment links to the dropzone", %{conn: conn} do
    html = conn |> get(~p"/docs/components/input") |> html_response(200)
    assert html =~ "File input states"
    assert html =~ "file-input file-input-ghost"

    html = conn |> get(~p"/docs/components/attachment") |> html_response(200)
    assert html =~ ~r{<a href="/docs/components/dropzone"[^>]*>&lt;.dropzone&gt;</a>}
  end
end
