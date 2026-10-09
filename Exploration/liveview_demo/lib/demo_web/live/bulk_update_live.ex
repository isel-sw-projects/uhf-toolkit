defmodule DemoWeb.BulkUpdateLive do
  @moduledoc """
  Trace of the `bulk-update` example do HtmlFlow-Datastar-Examples em Phoenix LiveView.

  No BRHC: `data-bind:selections` + `data-on:change @setAll` + `@put` - as checkboxes
  synchronise the selection signal and the server bulk-enables/disables. Here:
  checkboxes bound by phx-change; the "Update Selected" button stores in the process.
  """
  use DemoWeb, :live_view

  @users for(i <- 1..5, do: %{id: i, name: "User #{i}", active: rem(i, 2) == 1})

  def mount(_params, _session, socket) do
    {:ok, assign(socket, users: @users, selected: MapSet.new())}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h1>Bulk Update</h1>
      <p>Trace of the <em>bulk-update</em> example - in BRHC the selections live in a signal
      (<code>data-bind:selections</code>) and <code>@@put</code> bulk-enables/disables;
      aqui as checkboxes alimentam um MapSet no processo via <code>phx-change</code>.</p>

      <div class="demo-box">
      <table>
        <thead><tr><th></th><th>Name</th><th>Active</th></tr></thead>
        <tbody>
          <tr :for={{u, i} <- Enum.with_index(@users)}>
            <td>
              <input type="checkbox" phx-click="toggle-select" phx-value-index={i}
                     checked={MapSet.member?(@selected, i)} />
            </td>
            <td>{u.name}</td>
            <td>{if u.active, do: "✔ activo", else: "✘ inactivo"}</td>
          </tr>
        </tbody>
      </table>

      <button phx-click="set-active" disabled={MapSet.size(@selected) == 0}>Activate Selected</button>
      <button phx-click="set-inactive" disabled={MapSet.size(@selected) == 0}>Deactivate Selected</button>
      <p class="muted">{MapSet.size(@selected)} seleccionado(s)</p>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("toggle-select", %{"index" => i}, socket) do
    idx = String.to_integer(i)
    {:noreply, update(socket, :selected, &toggle_member(&1, idx))}
  end

  def handle_event("set-active", _p, socket), do: {:noreply, bulk_set(socket, true)}
  def handle_event("set-inactive", _p, socket), do: {:noreply, bulk_set(socket, false)}

  defp toggle_member(set, idx) do
    if MapSet.member?(set, idx), do: MapSet.delete(set, idx), else: MapSet.put(set, idx)
  end

  defp bulk_set(socket, value) do
    socket
    |> update(:users, fn users ->
      users
      |> Enum.with_index()
      |> Enum.map(fn {u, i} ->
        if MapSet.member?(socket.assigns.selected, i), do: %{u | active: value}, else: u
      end)
    end)
    |> assign(selected: MapSet.new())
  end
end
