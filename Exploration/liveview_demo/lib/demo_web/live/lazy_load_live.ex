defmodule DemoWeb.LazyLoadLive do
  @moduledoc """
  Trace of the `lazy-load` example do HtmlFlow-Datastar-Examples em Phoenix LiveView.

  No BRHC: `data-init="@@get('/lazy-load/graph')"` abre SSE; o servidor espera 2s e emite
  patchElements. Aqui: `handle_info(:loaded)` chega 2s depois do mount connected - o
  "push" exists (Process.send_after); only the wire changes.
  """
  use DemoWeb, :live_view

  def mount(_params, _session, socket) do
    if connected?(socket), do: Process.send_after(self(), :loaded, 2000)
    {:ok, assign(socket, loaded: false)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h1>Lazy Load</h1>
      <p>Trace of the <em>lazy-load</em> example - in BRHC the heavy content arrives 2s later over
      SSE (<code>patchElements</code>); aqui chega por mensagem ao processo
      (<code>Process.send_after</code>) e o diff renderiza o bloco.</p>

      <div class="demo-box">
        <%= if @loaded do %>
          <div class="loaded-box">
            <strong>Heavy content loaded</strong>
            <p class="muted">(no BRHC este bloco chegou via patchElements no SSE)</p>
          </div>
        <% else %>
          <em>Loading deferred content (2s)</em>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  def handle_info(:loaded, socket), do: {:noreply, assign(socket, loaded: true)}
end
