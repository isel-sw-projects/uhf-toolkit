defmodule DemoWeb.InfiniteScrollLive do
  @moduledoc """
  Trace of the `infinite-scroll` example do HtmlFlow-Datastar-Examples em Phoenix LiveView.

  No BRHC: `data-on-intersect="@@get('/infinite-scroll/more')"` num sentinela - quando o
  sentinela entra no viewport, o servidor devolve mais linhas. Aqui: `phx-viewport-bottom`
  (a NATIVE LiveView primitive for reaching the bottom of the page) loads more items;
  o offset vive no assign.
  """
  use DemoWeb, :live_view

  @limit 5
  @max 30

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(agents: generate(0, @limit), offset: @limit, loading: false)
     |> assign(max: @max)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h1>Infinite Scroll</h1>
      <p>Trace of the <em>infinite-scroll</em> example - no BRHC o sentinela usa
      <code>data-on-intersect</code> (atributo Datastar); aqui o LiveView tem a primitiva
      native <code>phx-viewport-bottom</code> - no manual JS, mirroring BRHC.</p>

      <div class="demo-box" id="infinite-scroll" phx-viewport-bottom="load-more">
        <ul>
          <li :for={a <- @agents}>{a}</li>
        </ul>
        <%= if @loading do %><em>Loading more</em><% end %>
        <%= if @offset >= @max do %><p class="muted">End of the list.</p><% end %>
      </div>
    </Layouts.app>
    """
  end

  defp generate(o, n), do: for(i <- (o + 1)..(o + n), do: "Agent #{i}")

  # phx-viewport-bottom fires this event when the user reaches the bottom.
  def handle_event("load-more", _p, socket) do
    if socket.assigns.loading or socket.assigns.offset >= @max do
      {:noreply, socket}
    else
      {:noreply,
       socket
       |> assign(loading: true)
       |> assign(:agents, socket.assigns.agents ++ generate(socket.assigns.offset, @limit))
       |> update(:offset, &(&1 + @limit))
       |> assign(loading: false)}
    end
  end
end
