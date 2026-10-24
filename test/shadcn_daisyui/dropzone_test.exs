defmodule ShadcnDaisyui.DropzoneTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.FormComponents, only: [dropzone: 1]

  alias Phoenix.LiveView.{UploadConfig, UploadEntry}

  defp render(template), do: template |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()

  defp upload(opts \\ []) do
    struct!(
      UploadConfig,
      Keyword.merge(
        [
          name: :people_csv,
          ref: "phx-up",
          accept: ".csv",
          max_entries: 1,
          max_file_size: 1_000_000,
          entries: [],
          errors: []
        ],
        opts
      )
    )
  end

  defp entry(ref, name, opts \\ []) do
    struct!(
      UploadEntry,
      Keyword.merge(
        [
          ref: ref,
          upload_ref: "phx-up",
          client_name: name,
          client_size: 1_234_567,
          client_type: "text/csv",
          valid?: true
        ],
        opts
      )
    )
  end

  # the opening tag of the first element matching `selector`-ish text
  defp tag(html, marker) do
    [_, tag] = Regex.run(~r/(<[a-z]+[^>]*#{Regex.escape(marker)}[^>]*>)/, html)
    tag
  end

  describe "a LiveView upload" do
    test "the zone is a label, the drop target, around the hidden live_file_input" do
      assigns = %{upload: upload()}
      html = render(~H|<.dropzone id="import-file" upload={@upload} />|)

      root = tag(html, ~s(id="import-file"))
      assert root =~ ~s(class="dropzone)
      assert root =~ ~s(data-dropzone="upload")
      assert root =~ ~s(phx-hook="ShadcnDropzone")
      assert root =~ ~s(data-size="default")

      zone = tag(html, "data-dropzone-area")
      assert zone =~ ~r/^<label /
      assert zone =~ ~s(phx-drop-target="phx-up")
      assert zone =~ "ignore_attrs"

      input = tag(html, ~s(type="file"))
      assert input =~ ~s(id="phx-up")
      assert input =~ ~s(name="people_csv")
      assert input =~ ~s(accept=".csv")
      assert input =~ ~s(data-phx-hook="Phoenix.LiveFileUpload")
      assert input =~ ~s(class="dropzone-input")
      assert input =~ ~s(aria-describedby="import-file-description")
      refute input =~ "multiple"
      refute input =~ "aria-invalid"
      # the label sits around the input: no inline handlers anywhere
      assert html =~ ~r/<label[^>]*data-dropzone-area[^>]*>\s*<input/
      refute html =~ ~r/\son[a-z]+=/
    end

    test "the title and the description default from the upload" do
      assigns = %{upload: upload()}
      html = render(~H|<.dropzone id="z" upload={@upload} />|)

      assert html =~ ~r/class="dropzone-mouse">Drop a file here, or choose one</
      assert html =~ ~r/class="dropzone-touch">Choose a file</
      assert html =~ "One .csv file, up to 1 MB."
      # read once, as the description (aria-describedby), not again in the name
      assert tag(html, ~s(id="z-description")) =~ ~s(aria-hidden="true")
      assert html =~ "hero-arrow-up-tray"
    end

    test "several files, types and binary sizes read naturally" do
      assigns = %{
        upload:
          upload(
            accept: ".csv,.xls,.xlsx",
            max_entries: 3,
            max_file_size: 5_242_880
          )
      }

      html = render(~H|<.dropzone id="z" upload={@upload} />|)
      assert html =~ "Drop files here, or choose them"
      assert html =~ "Choose files"
      assert html =~ "Up to 3 .csv, .xls or .xlsx files, 5 MB each."
      assert tag(html, ~s(type="file")) =~ "multiple"
    end

    test "MIME types and wildcards in accept, and :any" do
      assigns = %{
        images: upload(accept: "image/*,application/pdf,image/svg+xml", max_file_size: 8_000_000),
        any: upload(accept: :any, max_entries: 2, max_file_size: 1_500_000)
      }

      html = render(~H|<.dropzone id="a" upload={@images} /><.dropzone id="b" upload={@any} />|)
      assert html =~ "One image, .pdf or .svg file, up to 8 MB."
      assert html =~ "Up to 2 files, 1.5 MB each."
    end

    test "slots replace the title and the description; touch words the title for touch screens" do
      assigns = %{upload: upload()}

      html =
        render(~H"""
        <.dropzone id="z" upload={@upload}>
          <:title touch="Choose a CSV file">Drop a CSV file here, or choose one</:title>
          <:description>Exported from the old system.</:description>
        </.dropzone>
        """)

      assert html =~ ~r/class="dropzone-mouse">Drop a CSV file here, or choose one</
      assert html =~ ~r/class="dropzone-touch">Choose a CSV file</
      assert html =~ "Exported from the old system."
      refute html =~ "One .csv file"

      html =
        render(~H"""
        <.dropzone id="z" upload={@upload}><:title>Pick the export</:title></.dropzone>
        """)

      assert html =~ "Pick the export"
      refute html =~ "dropzone-touch"
    end

    test "entries are attachment tiles: idle, uploading with progress, done" do
      entries = [
        entry("0", "a.csv"),
        entry("1", "b.csv", progress: 64, preflighted?: true),
        entry("2", "c.csv", progress: 100, done?: true, client_size: 2_000_000)
      ]

      assigns = %{upload: upload(max_entries: 3, entries: entries)}
      html = render(~H|<.dropzone id="z" upload={@upload} />|)

      assert html =~ ~s(class="dropzone-entries" role="list" aria-label="Chosen files")
      assert length(Regex.scan(~r/role="listitem"/, html)) == 3
      assert tag(html, ~s(id="z-0")) =~ ~s(data-state="idle")
      assert tag(html, ~s(id="z-1")) =~ ~s(data-state="uploading")
      assert tag(html, ~s(id="z-2")) =~ ~s(data-state="done")
      assert html =~ "a.csv"
      assert html =~ "1.2 MB"
      assert html =~ "Uploading · 64%"
      assert html =~ "loading-spinner"
      assert html =~ "Uploaded · 2 MB"
      # no on_cancel: no remove button
      refute html =~ "attachment-action"
    end

    test "on_cancel adds a remove button that pushes the entry's ref" do
      entries = [entry("0", "a.csv"), entry("1", "b.csv", progress: 10, preflighted?: true)]
      assigns = %{upload: upload(max_entries: 2, entries: entries)}

      html =
        render(~H|<.dropzone id="z" upload={@upload} on_cancel="import:cancel" target="#form" />|)

      remove = tag(html, ~s(aria-label="Remove a.csv"))
      assert remove =~ ~s(phx-click="import:cancel")
      assert remove =~ ~s(phx-value-ref="0")
      assert remove =~ ~s(phx-target="#form")
      assert tag(html, ~s(aria-label="Cancel b.csv")) =~ ~s(phx-value-ref="1")
    end

    test "image entries preview with live_img_preview" do
      assigns = %{
        upload:
          upload(accept: "image/*", entries: [entry("0", "p.png", client_type: "image/png")])
      }

      html = render(~H|<.dropzone id="z" upload={@upload} />|)
      assert html =~ ~s(data-variant="image")
      assert html =~ ~s(data-phx-hook="Phoenix.LiveImgPreview")
    end

    test "errors: per entry on its tile, the upload's under the zone, all tied to the input" do
      entries = [entry("0", "people.xlsx"), entry("1", "big.csv")]

      assigns = %{
        upload:
          upload(
            entries: entries,
            errors: [{"0", :not_accepted}, {"1", :too_large}, {"phx-up", :too_many_files}]
          )
      }

      html = render(~H|<.dropzone id="z" upload={@upload} />|)

      assert tag(html, ~s(id="z")) =~ "data-invalid"
      input = tag(html, ~s(type="file"))
      assert input =~ ~s(aria-invalid="true")
      assert input =~ ~s(aria-describedby="z-description z-errors z-0-error z-1-error")

      assert tag(html, ~s(id="z-0")) =~ ~s(data-state="error")
      assert html =~ ~r/id="z-0-error">Only .csv files are accepted.</
      assert html =~ ~r/id="z-1-error">File is larger than 1 MB.</
      assert html =~ ~s(id="z-errors" class="dropzone-errors" aria-live="polite")
      assert html =~ "Too many files. Choose one."
      assert html =~ "hero-exclamation-circle"
    end

    test "default text for every LiveView upload error, and the plural limit" do
      many = [entry("0", "a"), entry("1", "b"), entry("2", "c")]

      assigns = %{
        one: upload(errors: [{"phx-up", :external_client_failure}]),
        many: upload(max_entries: 2, entries: many, errors: [{"phx-up", :too_many_files}]),
        other: upload(accept: :any, entries: [entry("0", "a")], errors: [{"0", :not_accepted}]),
        weird: upload(errors: [{"phx-up", {:error, :boom}}])
      }

      html =
        render(~H"""
        <.dropzone id="a" upload={@one} />
        <.dropzone id="b" upload={@many} />
        <.dropzone id="c" upload={@other} />
        <.dropzone id="d" upload={@weird} />
        """)

      assert html =~ "The upload failed. Try again."
      assert html =~ "Too many files. Choose up to 2."
      assert html =~ "This file type isn&#39;t accepted."
      assert html =~ "The upload failed."
    end

    test "error_text replaces the default; nil keeps it" do
      assigns = %{
        upload:
          upload(
            entries: [entry("0", "x.xlsx"), entry("1", "big.csv")],
            errors: [{"0", :not_accepted}, {"1", :too_large}]
          ),
        text: fn
          :not_accepted -> "That isn't a CSV file."
          _ -> nil
        end
      }

      html = render(~H|<.dropzone id="z" upload={@upload} error_text={@text} />|)
      assert html =~ "That isn&#39;t a CSV file."
      assert html =~ "File is larger than 1 MB."
    end

    test "<:entry> renders each entry; their errors then show under the zone" do
      assigns = %{
        upload:
          upload(
            max_entries: 2,
            entries: [entry("0", "ok.csv"), entry("1", "big.csv")],
            errors: [{"1", :too_large}]
          )
      }

      html =
        render(~H"""
        <.dropzone id="z" upload={@upload}>
          <:entry :let={entry}><span class="mine">{entry.client_name} {entry.progress}</span></:entry>
        </.dropzone>
        """)

      assert html =~ ~s(<span class="mine">ok.csv 0</span>)
      assert html =~ ~s(<span class="mine">big.csv 0</span>)
      refute html =~ ~s(data-slot="attachment")
      assert html =~ "big.csv: File is larger than 1 MB."
      assert tag(html, ~s(type="file")) =~ ~s(aria-describedby="z-description z-errors")
    end

    test "compact is one row; the description sits under it" do
      assigns = %{upload: upload()}
      html = render(~H|<.dropzone id="z" upload={@upload} size="compact" />|)

      assert tag(html, ~s(id="z")) =~ ~s(data-size="compact")
      assert html =~ "Choose a file or drop it here"
      assert html =~ ~r/<\/label>\s*<p id="z-description" class="dropzone-description">/
      refute tag(html, ~s(id="z-description")) =~ "aria-hidden"
    end

    test "disabled: no drop target, a disabled input" do
      assigns = %{upload: upload()}
      html = render(~H|<.dropzone id="z" upload={@upload} disabled />|)

      assert tag(html, ~s(id="z")) =~ "data-disabled"
      refute html =~ "phx-drop-target"
      assert tag(html, ~s(type="file")) =~ "disabled"
    end

    test "class and global attributes land on the root" do
      assigns = %{upload: upload()}
      html = render(~H|<.dropzone id="z" upload={@upload} class="mt-4" data-test="x" />|)

      root = tag(html, ~s(id="z"))
      assert root =~ "dropzone mt-4"
      assert root =~ ~s(data-test="x")
    end
  end

  describe "a plain form (name instead of upload)" do
    test "a named file input the hook takes drops for" do
      assigns = %{}

      html =
        render(~H|<.dropzone id="docs" name="documents" accept={~w(.pdf .txt)} multiple />|)

      assert tag(html, ~s(id="docs")) =~ ~s(data-dropzone="plain")
      refute html =~ "phx-drop-target"
      input = tag(html, ~s(type="file"))
      assert input =~ ~s(id="docs-input")
      assert input =~ ~s(name="documents[]")
      assert input =~ ~s(accept=".pdf,.txt")
      assert input =~ "multiple"
      assert html =~ "One or more .pdf or .txt files."
      assert html =~ ~s(data-dropzone-chosen)
      assert tag(html, "data-dropzone-chosen") =~ ~s(phx-update="ignore")
    end

    test "single file, no accept: no description" do
      assigns = %{}
      html = render(~H|<.dropzone id="logo" name="logo" />|)

      assert tag(html, ~s(type="file")) =~ ~s(name="logo")
      refute html =~ "dropzone-description"
      refute tag(html, ~s(type="file")) =~ "aria-describedby"
    end
  end

  test "needs upload or name" do
    assigns = %{}

    assert_raise ArgumentError, ~r/needs `upload`/, fn ->
      render(~H|<.dropzone id="z" />|)
    end
  end
end
