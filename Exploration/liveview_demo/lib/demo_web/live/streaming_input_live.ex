defmodule DemoWeb.StreamingInputLive do
  @moduledoc """
  Trace of the `streaming-input` example em Phoenix LiveView.

  In BRHC: the stream is an SSE channel emitting successive `patch-elements`, and the input
  stays active - the POST receives the signals and responds with its own patch.
  Here: the stream is a chain of messages to the process (Process.send_after), and the
  input stays active during it because every assign only touches the affected section.
  As mensagens enviadas durante a stream entram no log sem a interromper.
  """
  use DemoWeb, :live_view

  @chunks ["chunk A", "chunk B", "chunk C", "chunk D"]
  @chunk_delay_ms 800

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Process.send_after(self(), :chunk, @chunk_delay_ms)
    end

    {:ok, assign(socket, chunks: [], messages: [], stream_done: false, streaming: true)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h1>Streaming Input</h1>
      <p>Trace of the <em>streaming-input</em> example - no BRHC a stream corre num canal SSE
      com <code>patch-elements</code> em chunks; aqui corre como mensagens ao processo. O
      input stays active in both models - the combination <em>progressive-load</em>
      does not exercise.</p>

      <div class="demo-box">
        <div class="border rounded p-3 mb-3" style="min-height: 8em; background: #f8f9fa;">
          <%= if @chunks == [] do %>
            <span class="muted">Waiting for the stream to start</span>
          <% end %>
          <div :for={c <- @chunks}>{Phoenix.HTML.raw(c)}</div>
          <%= if @stream_done do %><div><strong>stream complete.</strong></div><% end %>
        </div>

        <div class="input-group">
          <input class="form-control" phx-keyup="typed" phx-debounce="200" name="message" placeholder="type during the stream..." />
          <button phx-click="send">Send</button>
        </div>

        <%= if @messages != [] do %>
          <ul class="mt-3">
            <li :for={m <- @messages}>{Phoenix.HTML.raw(m)}</li>
          </ul>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("typed", %{"value" => v}, socket), do: {:noreply, assign(socket, draft: v)}

  def handle_event("send", _p, socket) do
    msg = socket.assigns[:draft] || ""
    msg = String.trim(msg)

    if msg == "" do
      {:noreply, socket}
    else
      safe = Phoenix.HTML.html_escape(msg) |> Phoenix.HTML.safe_to_string()
      entry = "mensagem recebida durante o stream: <strong>#{safe}</strong>"
      {:noreply, update(socket, :messages, &(&1 ++ [entry]))}
    end
  end

  def handle_info(:chunk, %{assigns: %{chunks: [], streaming: true}} = socket) do
    Process.send_after(self(), :chunk, @chunk_delay_ms)
    {:noreply, assign(socket, chunks: ["<em>chunk A</em> received."])}
  end

  def handle_info(:chunk, %{assigns: %{streaming: true, chunks: chunks}} = socket) do
    if length(chunks) >= length(@chunks) do
      {:noreply, assign(socket, streaming: false, stream_done: true)}
    else
      Process.send_after(self(), :chunk, @chunk_delay_ms)
      next = Enum.at(@chunks, length(chunks))
      {:noreply, assign(socket, chunks: chunks ++ ["<em>#{next}</em> received."])}
    end
  end

  def handle_info(:chunk, socket), do: {:noreply, socket}

  # a stream inicia automaticamente no mount (como nos outros demos)
  def handle_info(:start, socket), do: start(socket)

  defp start(socket) do
    if socket.assigns.streaming do
      {:noreply, socket}
    else
      Process.send_after(self(), :chunk, @chunk_delay_ms)
      {:noreply, assign(socket, streaming: true, chunks: [], stream_done: false)}
    end
  end
end
