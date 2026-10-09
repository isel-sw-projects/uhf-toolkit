defmodule DemoWeb.MultiClientCounterLive do
  @moduledoc """
  Trace of the `multi-client-counter` example in Phoenix LiveView.

  In BRHC: a shared `MutableStateFlow` and every client connected to `/events` receives the
  same patch - opening two windows shows both synchronising. Here: Phoenix's PubSub
  Phoenix is the channel; the LiveView process subscribes to the topic (`subscribe`) and every
  broadcast arrives as a message in every client's process (one view per user).
  """
  use DemoWeb, :live_view

  @topic "shared-counter"

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Demo.PubSub, @topic)
    end

    {:ok, assign(socket, shared_value: value())}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h1>Multi-Client Counter</h1>
      <p>Trace of the <em>multi-client-counter</em> example - in BRHC every client subscribes to the
      same SSE stream; here each process subscribes to the PubSub topic and the broadcast reaches
      every process (one per user view).</p>

      <div class="demo-box">
        <p class="fs-3">Shared value: <strong>{@shared_value}</strong></p>
        <button phx-click="increment">Increment (all clients)</button>
        <p class="muted">Open a second window at <code>/multi-client-counter</code> - the values synchronise.</p>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("increment", _p, socket) do
    v = value() + 1
    :persistent_term.put({@topic, :value}, v)

    # the sender already assigned; the other processes receive :value via handle_info
    Phoenix.PubSub.broadcast(Demo.PubSub, @topic, {:value, v})
    {:noreply, assign(socket, shared_value: v)}
  end

  # broadcast also reaches the sender - the assign is idempotent
  def handle_info({:value, v}, socket), do: {:noreply, assign(socket, shared_value: v)}

  # O "bus": o valor comum vive no processo de registo do PubSub - aqui um
  # :persistent_term is enough for this trace (same role as a shared state).
  defp value do
    case :persistent_term.get({@topic, :value}, nil) do
      nil -> 0
      v -> v
    end
  end
end
