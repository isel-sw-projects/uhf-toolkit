defmodule DemoWeb.CounterSignalsLive do
  @moduledoc """
  Trace of the `counter-signals` variant do HtmlFlow-Datastar-Examples.

  In BRHC, a local `count` signal is synchronised over SSE (server <-> client).
  In LiveView the distinction collapses: the `count` assign IS the signal - it lives in the
  server process and the diff arrives over the same WebSocket as the events. Teaching note:
  o UHF procura um signal TIPADO com este papel; aqui ele existe implicitamente
  (assigns), with no type declaration.
  """
  use DemoWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, count: 0, synced: false)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h1>Counter (Signals)</h1>
      <p>Trace of the <em>counter-signals</em> variant - in BRHC the signal is synchronised over SSE
      (<code>data-init @@get('/counter/events')</code>); here the assign is the signal and the
      "synchronisation" is the WebSocket diff itself. The didactic difference between BRHC's two variants collapses.</p>

      <div class="demo-box">
        <p class="fs-3">Current count: <strong>{@count}</strong></p>
        <p class="muted">Signal synchronised: {if @synced, do: "yes (after the first event)", else: "not yet"}</p>
        <button phx-click="inc">Increment</button>
        <button phx-click="dec">Decrement</button>
        <button phx-click="reset">Reset</button>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("inc", _p, socket),
    do: {:noreply, socket |> assign(:synced, true) |> update(:count, &(&1 + 1))}

  def handle_event("dec", _p, socket),
    do: {:noreply, socket |> assign(:synced, true) |> update(:count, &(&1 - 1))}

  def handle_event("reset", _p, socket), do: {:noreply, assign(socket, count: 0)}
end
