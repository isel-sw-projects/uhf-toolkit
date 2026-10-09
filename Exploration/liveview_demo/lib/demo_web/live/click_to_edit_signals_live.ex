defmodule DemoWeb.ClickToEditSignalsLive do
  @moduledoc """
  Trace of the `click-to-edit-signals` variant do HtmlFlow-Datastar-Examples.

  In BRHC this variant uses local signals (`data-signals`, `data-bind`, `data-text`)
  instead of fragment swapping. In LiveView the assigns fill that role - the
  variant collapses into the base implementation, with `phx-change` validating
  live (the analogue of the signal flowing to the server).
  """
  use DemoWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, first_name: "John", last_name: "Doe", editing: false, draft: nil)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h1>Click to Edit (Signals)</h1>
      <p>Trace of the <em>click-to-edit-signals</em> variant - os signals locais do BRHC
      (<code>data-bind:first-name</code>, <code>$_editing</code>) correspondem aqui a assigns
      actualizados por <code>phx-change</code>, sem trocar fragments.</p>

      <div class="demo-box">
        <%= if @editing do %>
          <form phx-change="validate" phx-submit="save">
            <label>First Name <input type="text" name="first_name" value={@draft["first_name"]} /></label>
            <label>Last Name <input type="text" name="last_name" value={@draft["last_name"]} /></label>
            <p class="muted">Preview (signal flowing): <strong>{@draft["first_name"]} {@draft["last_name"]}</strong></p>
            <button type="submit">Submit</button>
            <button type="button" phx-click="cancel">Cancel</button>
          </form>
        <% else %>
          <h2>{@first_name} {@last_name}</h2>
          <button phx-click="edit">Edit</button>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("edit", _p, socket) do
    {:noreply,
     assign(socket,
       editing: true,
       draft: %{
         "first_name" => socket.assigns.first_name,
         "last_name" => socket.assigns.last_name
       }
     )}
  end

  def handle_event("cancel", _p, socket),
    do: {:noreply, assign(socket, editing: false, draft: nil)}

  # The local-signal analogue: every keystroke sends the value; the server keeps the draft.
  def handle_event("validate", params, socket) do
    {:noreply, assign(socket, draft: params)}
  end

  def handle_event("save", params, socket) do
    {:noreply,
     socket
     |> assign(
       first_name: params["first_name"],
       last_name: params["last_name"],
       editing: false,
       draft: nil
     )}
  end
end
