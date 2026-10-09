defmodule DemoWeb.LazyTabsLive do
  @moduledoc """
  Trace of the `lazy-tabs` example do HtmlFlow-Datastar-Examples em Phoenix LiveView.

  In BRHC: `data-on:click="@@get('/lazy-tabs/{n}')"` - each tab's content arrives as
  an on-demand fragment. Here: the `active_tab` assign switches the render; the tab content
  only exists in the active tab's diff (the "lazy load" is that block's first render).
  """
  use DemoWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, active_tab: nil, loading: false)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h1>Lazy Tabs</h1>
      <p>Trace of the <em>lazy-tabs</em> example - in BRHC every click requests the tab fragment
      (<code>@@get('/lazy-tabs/' &lt;&gt; tab)</code>); here the active tab's conditional block is what
      arrives in the diff.</p>

      <div class="demo-box">
      <div class="tabs" role="tablist">
        <button :for={n <- 1..3} phx-click="select-tab" phx-value-tab={n}
                class={if @active_tab == n, do: "active", else: ""}
                role="tab" aria-selected={@active_tab == n}>
          Tab {n}
        </button>
      </div>

      <div class="tab-content" role="tabpanel">
        <%= cond do %>
          <% is_nil(@active_tab) -> %>
            <em class="muted">Pick a tab to load its content</em>
          <% @loading -> %>
            <em>Loading</em>
          <% true -> %>
            <p>Tab {@active_tab} content - generated on the server when the tab is activated.</p>
        <% end %>
      </div>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("select-tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: String.to_integer(tab), loading: false)}
  end
end
