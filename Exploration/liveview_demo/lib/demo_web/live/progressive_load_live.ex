defmodule DemoWeb.ProgressiveLoadLive do
  @moduledoc """
  Trace of the `progressive-load` example do HtmlFlow-Datastar-Examples em Phoenix LiveView.

  No BRHC: o servidor envia fragmentos sequenciais por SSE (header → article → comments →
  footer). Here: the sequence is a chain of messages to the process; each step adds
  a section to the diff. The button disables itself while loading (the data-indicator analogue).
  """
  use DemoWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, header: nil, article: nil, comments: nil, footer: nil, loading: false)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h1>Progressive Load</h1>
      <p>Trace of the <em>progressive-load</em> example - in BRHC the sections arrive over
      as sequential patches on SSE; here they arrive as messages to the process, each
      triggering a diff. <code>loading</code> is the <code>data-indicator</code> analogue.</p>

      <div class="demo-box">
      <button phx-click="load" disabled={@loading}>
        {if @loading, do: "Loading", else: "Load content"}
      </button>

      <%= if @header do %><h2>{@header}</h2><% end %>
      <%= if @article do %><p class="lead">{@article}</p><% end %>
      <%= if @comments do %>
        <ul><li :for={c <- @comments}>{c}</li></ul>
      <% end %>
      <%= if @footer do %><p class="muted">{@footer}</p><% end %>
    </div>
    </Layouts.app>
    """
  end

  def handle_event("load", _p, socket) do
    Process.send_after(self(), :step_header, 400)

    {:noreply,
     assign(socket, loading: true, header: nil, article: nil, comments: nil, footer: nil)}
  end

  def handle_info(:step_header, socket) do
    Process.send_after(self(), :step_article, 600)
    {:noreply, assign(socket, header: "Progressive Load")}
  end

  def handle_info(:step_article, socket) do
    Process.send_after(self(), :step_comments, 600)

    {:noreply,
     assign(socket,
       article: "This article arrived in parts - in BRHC, each part is a patchElements on the SSE stream."
     )}
  end

  def handle_info(:step_comments, socket) do
    Process.send_after(self(), :step_footer, 600)
    {:noreply, assign(socket, comments: ["Comment 1", "Comment 2", "Comment 3"])}
  end

  def handle_info(:step_footer, socket) do
    {:noreply, assign(socket, footer: "End of deferred content.", loading: false)}
  end
end
