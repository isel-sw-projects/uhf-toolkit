defmodule DemoWeb.BinaryPayloadLive do
  @moduledoc """
  Trace of the `binary-payload` example em Phoenix LiveView.

  In BRHC: bytes arrive in the POST body (not base64 in signals) and the response is
  um patch com tamanho e SHA-256. Aqui: `live_file_input` (a primitiva nativa do
  LiveView, same as file-upload) hands over the metadata and the temporary path;
  `consume_uploaded_entries` gives access to the content - the digest is computed in Elixir
  sem o payload passar pelo canal de assigns.
  """
  use DemoWeb, :live_view

  @max_entries 1

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> allow_upload(:payload,
       accept: :any,
       max_entries: @max_entries,
       max_file_size: 8_000_000,
       auto_upload: false
     )
     |> assign(report: nil)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h1>Binary-Native Payload</h1>
      <p>Trace of the <em>binary-payload</em> example - in BRHC the bytes travel in the body of the
      <code>@@post</code> (not in signals); here they travel over LiveView's native channels
      (<code>live_file_input</code>) and the digest is computed on the server.</p>

      <div class="demo-box">
        <form phx-submit="echo" phx-change="validate">
          <.live_file_input upload={@uploads.payload} />
          <button type="submit" disabled={@uploads.payload.entries == []}>Enviar</button>
        </form>

        <div id="binary-report" class="mt-3">
          <%= if @report do %>
            <div>bytes recebidos: <strong>{@report.size}</strong></div>
            <div>sha256: <code>{@report.sha256}</code></div>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("validate", _p, socket), do: {:noreply, socket}

  def handle_event("echo", _p, socket) do
    report =
      Phoenix.LiveView.consume_uploaded_entries(socket, :payload, fn meta, entry ->
        size = File.stat!(meta.path).size
        bytes = File.read!(meta.path)
        sha = :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)
        {:ok, %{size: size, sha256: sha, name: entry.client_name}}
      end)
      |> List.first()

    {:noreply, assign(socket, report: report)}
  end
end
