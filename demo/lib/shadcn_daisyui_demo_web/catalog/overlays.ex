defmodule ShadcnDaisyuiDemoWeb.Catalog.Overlays do
  @moduledoc """
  Catalog pages for overlay components whose examples are rendered from the
  real component: `<.alert_dialog>` and the styled `data-confirm` it backs.
  Design metadata (specs, accessibility, SwiftUI) is inline here.

  As in `ShadcnDaisyuiDemoWeb.Catalog.DataPages`, each example's `code` is
  the component's markup at runtime, made a plain-HTML recipe by
  `DataPages.code/1`, so the code tab never drifts from the component. The
  pages are built once per code version (see `all/0`).
  """
  use Phoenix.Component

  import ShadcnDaisyui.Components.Overlay,
    only: [alert_dialog: 1, dropdown_menu: 1, show_modal: 1]

  import ShadcnDaisyui.CoreComponents, only: [button: 1, icon: 1]

  alias ShadcnDaisyuiDemoWeb.Catalog.DataPages

  # Modules whose markup the examples render: a change to any of them (or to
  # this module) rebuilds the pages.
  @sources [
    __MODULE__,
    DataPages,
    ShadcnDaisyui.Components.Overlay,
    ShadcnDaisyui.CoreComponents
  ]

  @doc "The pages, kept in `:persistent_term` per code version (as `DataPages.all/0`)."
  def all do
    key = {__MODULE__, Enum.map(@sources, & &1.module_info(:md5))}

    case :persistent_term.get(key, nil) do
      nil ->
        pages = [alert_dialog()]
        :persistent_term.put(key, pages)
        pages

      pages ->
        pages
    end
  end

  defp code(rendered), do: DataPages.code(rendered)

  # ---------------------------------------------------------------------------
  # Alert dialog
  # ---------------------------------------------------------------------------

  defp alert_dialog do
    %{
      slug: "alert-dialog",
      title: "Alert Dialog",
      description:
        "A modal that interrupts to confirm an action: a question, its consequence, Cancel and the action.",
      guidance: %{
        use_when: [
          "Confirming an action that is hard to undo: delete, remove, discard changes",
          "A decision the server makes first (\"discard your changes?\") - open it from the server",
          "Every data-confirm in the app, once initConfirmDialog() is on"
        ],
        avoid_when: [
          "A form or a task in a modal - use <.dialog> (it closes on a backdrop click)",
          "Telling people something happened - use a toast",
          "Actions that are easy to undo - do it, and offer Undo in a toast"
        ],
        sizing:
          "shadcn's AlertDialog: up to 32rem (max-w-lg; size=\"sm\" 20rem), 24px padding, 16px between header and footer, the rounded-xl popover surface with a 1px ring and shadow-lg. Title text-lg semibold, description text-sm muted 6px under it. Buttons h-9, 8px apart: Cancel outline, the action primary or destructive.",
        responsive:
          "Phones: the full width less 2rem, the header centred, the action above Cancel, both full width. From 640px the text aligns left and the buttons sit in a row on the right. size=\"sm\" stays centred, its two buttons side by side.",
        ios:
          ".alert with a .cancel and a .destructive button (or .confirmationDialog when there are several choices)."
      },
      props: [
        %{name: "id", type: "string (required)", default: "-"},
        %{name: "size", type: "default | sm", default: "default"},
        %{name: "cancel", type: "string (Cancel's label)", default: ~s("Cancel")},
        %{name: "show", type: "boolean (open while true)", default: "false"},
        %{name: "on_close", type: "event name or JS (Cancel, Esc, the action)", default: "nil"},
        %{name: "class", type: "any", default: "nil"},
        %{name: ":trigger", type: "slot (opens it)", default: "-"},
        %{name: ":media", type: "slot (64px square above the title)", default: "-"},
        %{name: ":title", type: "slot (required; names the dialog)", default: "-"},
        %{name: ":description", type: "slot (describes the dialog)", default: "-"},
        %{name: "inner_block", type: "slot (between the header and the buttons)", default: "-"},
        %{
          name: ":action",
          type:
            "slot (required): variant default | destructive, close={false}, and any button or <.link> attribute (phx-click, type + form, navigate, href + method)",
          default: "-"
        }
      ],
      notes:
        "Open it like any modal: the :trigger slot, phx-click={show_modal(id)}, or from the server with push_show_modal(socket, id) or show={@assign} + on_close. A backdrop click doesn't close it; Cancel, Esc and the action do (each runs on_close). Focus lands on Cancel and goes back to what opened it. The action runs whatever it carries - a phx-click, a form submit, a link - and closes the dialog; close={false} keeps it open until the server closes it (push_hide_modal/2). For data-confirm (dropdown and command items' confirm, links, buttons) call initConfirmDialog() once in app.js: the browser's confirm() becomes this dialog, and the click runs as before once confirmed.",
      specs: %{
        anatomy: [
          %{part: "Trigger", description: "Optional; opens the dialog (show_modal)."},
          %{
            part: "Box",
            description:
              "The .modal-box popover surface: a grid of the header and the footer, 16px apart."
          },
          %{
            part: "Header",
            description:
              "Optional media, the title (the question) and a muted description (the consequence)."
          },
          %{
            part: "Footer",
            description:
              "Cancel (outline, focused on open) and the action (primary or destructive)."
          }
        ],
        measurements: [
          %{
            property: "Box",
            value:
              "max 32rem (sm 20rem), 100% - 2rem on phones, 1.5rem padding, var(--radius-xl), var(--popover)"
          },
          %{property: "Title", value: "1.125rem / 28px, weight 600"},
          %{property: "Description", value: "0.875rem, var(--muted-foreground), 6px below"},
          %{property: "Media", value: "4rem square, var(--muted), var(--radius-md)"},
          %{property: "Buttons", value: "2.25rem tall, 0.5rem apart"},
          %{property: "Backdrop", value: "oklch(0 0 0 / 0.5), doesn't close it"}
        ],
        tokens: [
          "popover",
          "popover-foreground",
          "muted",
          "muted-foreground",
          "primary",
          "primary-foreground",
          "destructive",
          "ring"
        ]
      },
      accessibility: %{
        roles:
          "A native modal <dialog role=\"alertdialog\">: aria-labelledby the title, aria-describedby the description. Everything behind it is inert.",
        keyboard: [
          %{keys: "Tab / Shift+Tab", action: "Move between Cancel and the action"},
          %{keys: "Enter / Space", action: "Activate the focused button"},
          %{keys: "Esc", action: "Cancel: close it without the action"}
        ],
        focus:
          "Focus lands on Cancel, the safe choice, when it opens, and goes back to what opened it when it closes.",
        screen_reader:
          "Announced as an alert dialog with its title and description, so the question and the consequence are read before the buttons.",
        touch_target:
          "The buttons are full width on phones (2.25rem tall); keep the action's label short so it stays one line.",
        reduced_motion: "Fades in and out without the zoom under prefers-reduced-motion."
      },
      swiftui: %{
        code: ~S"""
        .alert("Delete Q3 report?", isPresented: $confirmDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete report", role: .destructive) { delete() }
        } message: {
            Text("The report and its comments are deleted for everyone.")
        }
        """,
        notes:
          "Maps directly to an .alert: the title, a message, a .cancel button and a .destructive action."
      },
      ios_status: :parity,
      examples: [
        %{
          title: "Default",
          heex: ~S"""
          <.alert_dialog id="alert-default">
            <:trigger><.button variant="outline">Show dialog</.button></:trigger>
            <:title>Are you absolutely sure?</:title>
            <:description>
              This permanently deletes your account and removes your data from our servers.
            </:description>
            <:action phx-click="delete_account">Continue</:action>
          </.alert_dialog>
          """,
          code: default_code()
        },
        %{
          title: "Destructive",
          heex: ~S"""
          <.alert_dialog id="alert-delete">
            <:trigger><.button variant="destructive">Delete report</.button></:trigger>
            <:title>Delete Q3 report?</:title>
            <:description>The report and its comments are deleted for everyone.</:description>
            <:action variant="destructive" phx-click="delete" phx-value-id={@report.id}>
              Delete report
            </:action>
          </.alert_dialog>
          """,
          code: destructive_code()
        },
        %{
          title: "Small, with media",
          heex: ~S"""
          <.alert_dialog id="alert-share" size="sm">
            <:trigger><.button variant="outline">Share report</.button></:trigger>
            <:media><.icon name="hero-share" class="size-8" /></:media>
            <:title>Share with Acme Marketing?</:title>
            <:description>They can view and comment until you stop sharing.</:description>
            <:action phx-click="share">Share</:action>
          </.alert_dialog>
          """,
          code: small_code()
        },
        server_example(),
        confirm_example()
      ]
    }
  end

  defp default_code do
    assigns = %{}

    code(~H"""
    <.alert_dialog id="alert-default">
      <:trigger><.button variant="outline">Show dialog</.button></:trigger>
      <:title>Are you absolutely sure?</:title>
      <:description>
        This permanently deletes your account and removes your data from our servers.
      </:description>
      <:action phx-click="delete_account">Continue</:action>
    </.alert_dialog>
    """)
  end

  defp destructive_code do
    assigns = %{}

    code(~H"""
    <.alert_dialog id="alert-delete">
      <:trigger><.button variant="destructive">Delete report</.button></:trigger>
      <:title>Delete Q3 report?</:title>
      <:description>The report and its comments are deleted for everyone.</:description>
      <:action variant="destructive" phx-click="delete" phx-value-id="q3">Delete report</:action>
    </.alert_dialog>
    """)
  end

  defp small_code do
    assigns = %{}

    code(~H"""
    <.alert_dialog id="alert-share" size="sm">
      <:trigger><.button variant="outline">Share report</.button></:trigger>
      <:media><.icon name="hero-share" class="size-8" /></:media>
      <:title>Share with Acme Marketing?</:title>
      <:description>They can view and comment until you stop sharing.</:description>
      <:action phx-click="share">Share</:action>
    </.alert_dialog>
    """)
  end

  defp server_example do
    assigns = %{}

    %{
      title: "Open from the server",
      heex: ~S"""
      <%!-- a decision the server makes: unsaved changes ask first --%>
      def handle_event("cancel", _params, socket) do
        if socket.assigns.dirty?,
          do: {:noreply, push_show_modal(socket, "discard")},
          else: {:noreply, push_navigate(socket, to: ~p"/orders")}
      end

      <.alert_dialog id="discard" cancel="Keep editing">
        <:title>Discard your changes?</:title>
        <:description>Your edits to #1042 haven't been saved.</:description>
        <:action variant="destructive" navigate={~p"/orders"}>Discard changes</:action>
      </.alert_dialog>

      <%!-- or open while an assign is true; on_close turns it back off --%>
      <.alert_dialog id="delete-order" show={@confirm?} on_close="keep_order">…</.alert_dialog>

      def handle_event("keep_order", _params, socket), do: {:noreply, assign(socket, confirm?: false)}
      """,
      code:
        code(~H"""
        <.button variant="outline" phx-click={show_modal("alert-discard")}>Cancel</.button>
        <.alert_dialog id="alert-discard" cancel="Keep editing" on_close="keep_editing">
          <:title>Discard your changes?</:title>
          <:description>Your edits to #1042 haven't been saved.</:description>
          <:action variant="destructive" phx-click="discard">Discard changes</:action>
        </.alert_dialog>
        """)
    }
  end

  defp confirm_example do
    assigns = %{}

    %{
      title: "Styled data-confirm",
      heex: ~S"""
      // assets/js/app.js, once: data-confirm asks in this dialog, not the browser's confirm()
      import { Hooks, initConfirmDialog } from "shadcn_daisyui"
      initConfirmDialog()

      <.button
        variant="destructive"
        phx-click="delete"
        data-confirm="Delete Q3 report?"
        data-confirm-description="The report and its comments are deleted for everyone."
        data-confirm-action="Delete report"
      >
        Delete report
      </.button>

      <%!-- a destructive item gets a destructive action --%>
      <.dropdown_menu align="end" close_on_select>
        <:trigger>Member actions</:trigger>
        <:item phx-click="edit" phx-value-id={@member.id}>Edit</:item>
        <:item
          phx-click="remove"
          phx-value-id={@member.id}
          variant="destructive"
          confirm={"Remove #{@team.name} from #{@member.name}?"}
        >
          Remove
        </:item>
      </.dropdown_menu>
      """,
      code:
        code(~H"""
        <.button
          variant="destructive"
          data-confirm="Delete Q3 report?"
          data-confirm-description="The report and its comments are deleted for everyone."
          data-confirm-action="Delete report"
          data-toast="Q3 report deleted"
        >
          Delete report
        </.button>
        <.dropdown_menu align="end" close_on_select>
          <:trigger>Member actions</:trigger>
          <:item phx-click="edit">Edit</:item>
          <:item phx-click="remove" variant="destructive" confirm="Remove Acme Marketing from Pat Lee?">
            Remove
          </:item>
        </.dropdown_menu>
        """)
    }
  end
end
