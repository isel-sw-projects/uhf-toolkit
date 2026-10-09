defmodule DemoWeb.FileUploadLive do
  @moduledoc """
  Trace of the `file-upload` example do HtmlFlow-Datastar-Examples em Phoenix LiveView.

  No BRHC: `data-bind:files` serializa os ficheiros (base64) nos signals e o `@@post`
  valida o limite de 1 MB. Aqui: `live_file_input` (primitiva nativa do LiveView, com
  streaming and progress) - no manual serialisation, like Blazor's InputFile.
  """
  use DemoWeb, :live_view

  @max_entries 10

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> allow_upload(:files,
       accept: :any,
       max_entries: @max_entries,
       max_file_size: 1_000_000,
       auto_upload: false
     )
     |> assign(processed: nil)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h1>File Upload</h1>
      <p>Trace of the <em>file-upload</em> example - in BRHC files travel serialised
      into signals (base64) in the <code>@@post</code> body; here they travel over native channels
      (<code>live_file_input</code>) with the 1 MB limit validated by LiveView itself.</p>

    <div class="demo-box">
      <form phx-submit="save" phx-change="validate">
        <.live_file_input upload={@uploads.files} />

        <%= for entry <- @uploads.files.entries do %>
          <p class="muted">{entry.client_name}: {entry.progress}% - {upload_state(entry)}</p>
          <%= for err <- upload_errors(@uploads.files, entry) do %>
            <p class="error">Erro: {err_to_msg(err)}</p>
          <% end %>
        <% end %>

        <button type="submit" disabled={@uploads.files.entries == []}>Submit</button>
      </form>

      <%= if @processed do %>
        <table>
          <thead><tr><th>Nome</th><th>Tamanho</th><th>Estado</th></tr></thead>
          <tbody>
            <tr :for={f <- @processed} class={f.status}>
              <td>{f.name}</td><td>{f.size}</td><td>{f.state}</td>
            </tr>
          </tbody>
        </table>
      <% end %>
    </div>
    </Layouts.app>
    """
  end

  defp upload_state(%{progress: 100}), do: "pronto"
  defp upload_state(_entry), do: "uploading"

  defp err_to_msg(:too_large), do: "file > 1 MB"
  defp err_to_msg(:too_many_files), do: "too many files"
  defp err_to_msg(err), do: to_string(err)

  def handle_event("validate", _p, socket), do: {:noreply, socket}

  def handle_event("save", _p, socket) do
    # consume_uploaded_entries: o callback devolve {:ok, valor} (assinatura exigida
    # pelo LiveView 1.2) e a API devolve a lista dos valores "desembrulhados".
    processed =
      Phoenix.LiveView.consume_uploaded_entries(socket, :files, fn meta, entry ->
        size = File.stat!(meta.path).size

        {:ok,
         %{
           name: entry.client_name,
           size: "#{div(size, 1024)}.0 KB",
           state: "✔ aceite",
           status: "ok"
         }}
      end)

    # Log rejected files: the criterion is client_size (invalid entries
    # are never consumed; they only get the :too_large error).
    rejected =
      for entry <- socket.assigns.uploads.files.entries,
          entry.valid? == false or entry.client_size > 1_000_000 do
        %{name: entry.client_name, size: "> 1 MB", state: "✘ > 1 MB", status: "erro"}
      end

    {:noreply, socket |> assign(processed: processed ++ rejected)}
  end
end
