defmodule DemoWeb.DeleteRowLive do
  @moduledoc """
  Trace of the `delete-row` example do HtmlFlow-Datastar-Examples em Phoenix LiveView.

  No BRHC: `data-on:click="confirm(...) && @@delete('/delete-row/{i}')"` - o servidor
  remove e emite morph. Aqui: `phx-click` com `data-confirm` (atributo nativo do LiveView
  for confirmation) and the removal runs in the process.
  """
  use DemoWeb, :live_view

  @users for(i <- 1..5, do: %{id: i, first: "User #{i}", email: "user#{i}@example.com"})

  def mount(_params, _session, socket) do
    {:ok, assign(socket, users: @users)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h1>Delete Row</h1>
      <p>Trace of the <em>delete-row</em> example - no BRHC o
      <code>confirm(...) &amp;&amp; @@delete('/delete-row/idx')</code> remove no servidor e
      o SSE emite morph; aqui <code>data-confirm</code> + <code>phx-click</code> fazem o mesmo
      no WebSocket.</p>

      <div class="demo-box">
      <table>
        <thead><tr><th>ID</th><th>First</th><th>Email</th><th></th></tr></thead>
        <tbody>
          <tr :for={{u, i} <- Enum.with_index(@users)}>
            <td>{u.id}</td><td>{u.first}</td><td>{u.email}</td>
            <td>
              <button phx-click="delete" phx-value-index={i} data-confirm="Are you sure?">
                Delete
              </button>
            </td>
          </tr>
        </tbody>
      </table>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("delete", %{"index" => idx}, socket) do
    i = String.to_integer(idx)
    {:noreply, update(socket, :users, &List.delete_at(&1, i))}
  end
end
