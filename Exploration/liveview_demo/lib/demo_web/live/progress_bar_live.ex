defmodule DemoWeb.ProgressBarLive do
  @moduledoc """
  Trace of the `progress-bar` example do HtmlFlow-Datastar-Examples em Phoenix LiveView.

  In BRHC: an SSE stream of patchElements with the progress value up to 100%. Here: the
  LiveView process sends itself :tick on intervals - the "server pushes a sequence
  of states" pattern is the same; the wire changes (patch SSE vs WebSocket diffs).
  """
  use DemoWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, progress: 0, running: false)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h1>Progress Bar</h1>
      <p>Trace of the <em>progress-bar</em> example - in BRHC progress is an SSE stream of
      patches; here the process sends itself <code>:tick</code>, with the diff
      updating the bar at each step.</p>

      <div class="demo-box">
      <%= if @running do %>
        <div class="progress-outer">
          <div class="progress-inner" style={"width: #{@progress}%"}>{@progress}%</div>
        </div>
      <% else %>
        <button phx-click="start" disabled={@progress >= 100}>
          {if @progress >= 100, do: "✔ Complete", else: "Start"}
        </button>
      <% end %>
    </div>
    </Layouts.app>
    """
  end

  def handle_event("start", _p, socket) do
    Process.send_after(self(), :tick, 100)
    {:noreply, assign(socket, running: true, progress: 0)}
  end

  def handle_info(:tick, socket) do
    new = min(socket.assigns.progress + 5, 100)

    if new < 100 do
      Process.send_after(self(), :tick, 100)
      {:noreply, assign(socket, progress: new)}
    else
      {:noreply, assign(socket, progress: new, running: false)}
    end
  end
end
