defmodule DemoWeb.CounterLive do
  @moduledoc """
  Trace of the `counter` example do HtmlFlow-Datastar-Examples em Phoenix LiveView.

  In BRHC: `data-init @get('/counter/events')` opens SSE; the buttons issue `@post(increment)`
  and the server emits the new value. Here: one LiveView process per user keeps `count`
  and each `handle_event` re-renders - the transport is the /live WebSocket with diffs.
  """
  use DemoWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, count: 0)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h1>Counter</h1>
      <p>Trace of the <em>counter</em> example - in BRHC the counter lives in a <code>MutableStateFlow</code>
      and arrives over SSE; here it lives in a BEAM process and arrives as WebSocket diffs.</p>

      <div class="demo-box">
        <p class="fs-3">Current count: <strong>{@count}</strong></p>
        <button phx-click="increment">Increment</button>
        <button phx-click="decrement">Decrement</button>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("increment", _params, socket),
    do: {:noreply, update(socket, :count, &(&1 + 1))}

  def handle_event("decrement", _params, socket),
    do: {:noreply, update(socket, :count, &(&1 - 1))}
end
