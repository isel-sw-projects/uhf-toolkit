defmodule DemoWeb.ClickToEditLive do
  @moduledoc """
  Trace of the `click-to-edit` example do HtmlFlow-Datastar-Examples em Phoenix LiveView.

  In BRHC: `data-on:click` swaps the fragment (view <-> form) via @get/@put.
  Aqui: o assign `editing` comuta o render; `phx-submit` actualiza o estado no
  processo do servidor - sem fragmentos, com diffs.
  """
  use DemoWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, first_name: "John", last_name: "Doe", editing: false)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h1>Click to Edit</h1>
      <p>Trace of the <em>click-to-edit</em> example - in BRHC the view/form arrives as
      fragments (<code>@@get</code>/<code>@@put</code>); here it is an <code>if</code> in HEEx over
      o assign <code>editing</code>.</p>

      <div class="demo-box">
        <%= if @editing do %>
          <form phx-submit="save">
            <label>First Name <input type="text" name="first_name" value={@first_name} /></label>
            <label>Last Name <input type="text" name="last_name" value={@last_name} /></label>
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

  def handle_event("edit", _p, socket), do: {:noreply, assign(socket, editing: true)}

  def handle_event("cancel", _p, socket), do: {:noreply, assign(socket, editing: false)}

  def handle_event("save", %{"first_name" => f, "last_name" => l}, socket) do
    {:noreply, socket |> assign(first_name: f, last_name: l, editing: false)}
  end
end
