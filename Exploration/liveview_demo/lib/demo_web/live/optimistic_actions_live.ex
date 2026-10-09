defmodule DemoWeb.OptimisticActionsLive do
  @moduledoc """
  Trace of the `optimistic-actions` example (the rollback case the original corpus
  does not have) in Phoenix LiveView.

  In BRHC: the button shows the *pending* state via `data-indicator`/`data-attr:disabled`
  while the POST is in flight; the server confirms the value or rolls it back via
  `patch-elements` on `#items-table` - "Item 3" always fails, and the rollback stays
  visible. Here: component state goes through `pending` in the assign and the LiveView
  diff delivers the badge; the rollback is assigning the previous value again.
  """
  use DemoWeb, :live_view

  @latency_ms 600

  def mount(_params, _session, socket) do
    items = [
      %{id: 0, label: "Item 1", value: 10, pending: false, failed: false},
      %{id: 1, label: "Item 2", value: 20, pending: false, failed: false},
      # "Item 3" falha sempre - alimenta o caminho de rollback (igual ao Kotlin).
      %{id: 2, label: "Item 3", value: 30, pending: false, failed: true},
      %{id: 3, label: "Item 4", value: 40, pending: false, failed: false}
    ]

    {:ok, assign(socket, items: items, server_error: nil)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h1>Optimistic Actions</h1>
      <p>Trace of the <em>optimistic-actions</em> example - in BRHC the pending badge lives in
      <code>data-indicator</code> and the rollback arrives as <code>patch-elements</code>; here the
      LiveView diff delivers the same effect with state in the process.</p>

      <div class="demo-box">
        <%= if @server_error do %>
          <div class="alert alert-danger py-2">{@server_error}</div>
        <% end %>

        <table>
          <thead><tr><th>Item</th><th>Value</th><th>Action</th></tr></thead>
          <tbody>
            <tr :for={item <- @items}>
              <td>{item.label}</td>
              <td>{item.value}</td>
              <td>
                <button phx-click="apply" phx-value-id={item.id} disabled={item.pending}>
                  {if item.pending, do: "pending…", else: "+10"}
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("apply", %{"id" => id}, socket) do
    id = String.to_integer(id)
    index = Enum.find_index(socket.assigns.items, &(&1.id == id))
    will_fail = Enum.at(socket.assigns.items, index).failed

    # (1) badge pending - o equivalente do PATCH com pending=true
    socket = update(socket, :items, &List.replace_at(&1, index, %{Enum.at(&1, index) | pending: true}))

    Process.send_after(self(), {:resolve, index, will_fail}, @latency_ms)

    {:noreply, socket}
  end

  def handle_info({:resolve, index, will_fail}, socket) do
    item = Enum.at(socket.assigns.items, index)

    # (2) confirmation or rollback - BRHC's rollback patch
    updated =
      if will_fail do
        %{item | pending: false}
      else
        %{item | value: item.value + 10, pending: false}
      end

    {:noreply,
     socket
     |> update(:items, &List.replace_at(&1, index, updated))
     |> assign(:server_error, if(will_fail, do: "Servidor recusou: falha simulada (rollback)", else: nil))}
  end
end
