defmodule DemoWeb.LargeListLive do
  @moduledoc """
  Trace of the `large-list` example (keyed morph de 500 rows) em Phoenix LiveView.

  In BRHC: the keys are the `<tr>` `id`s in the patch-elements - the morph moves nodes
  existentes. Aqui: `Phoenix.Component` usa `:for` com o DOM id por linha; o reorder
  re-renders from the assign - LiveView reconciliation compares the tree and preserves
  nodes whose ids (and content position) stay the same.
  """
  use DemoWeb, :live_view

  @rows 500

  def mount(_params, _session, socket) do
    {:ok, assign(socket, rows: build_rows(1..@rows))}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h1>Large List (500 keyed rows)</h1>
      <p>Trace of the <em>large-list</em> example - no BRHC o reorder reenvia os mesmos
      <code>&lt;tr id&gt;</code> in a different order and the keyed morph moves nodes; here the
      re-render is the render-tree diff over the assigns.</p>

      <div class="demo-box">
        <div class="border rounded p-2" style="max-height: 24em; overflow-y: auto;">
          <table>
            <tbody>
              <tr :for={row <- @rows} id={"row-#{row.id}"}>
                <td class="text-end" style="width: 6em;">{row.id}</td>
                <td>{row.label}</td>
              </tr>
            </tbody>
          </table>
        </div>
        <button phx-click="reorder" class="btn btn-primary mt-3">Reorder</button>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("reorder", _p, socket) do
    # o Kotlin re-patch com as mesmas rows em ordem inversa; aqui o diff da
    # render tree resolves the change in one cycle - reordering does not persist.
    {:noreply, assign(socket, rows: Enum.reverse(socket.assigns.rows))}
  end

  defp build_rows(range), do: Enum.map(range, &%{id: &1, label: "Row #{&1}"})
end
