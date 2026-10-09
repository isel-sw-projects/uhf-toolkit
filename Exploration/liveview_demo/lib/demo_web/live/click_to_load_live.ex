defmodule DemoWeb.ClickToLoadLive do
  @moduledoc """
  Trace of the `click-to-load` example do HtmlFlow-Datastar-Examples em Phoenix LiveView.

  In BRHC: `@get('/more')` with `data-signals:offset/limit` - the server returns more
  rows and appends them. Here: the offset lives in the assign; every "Load More" click
  appends a batch generated on the server (the LiveView process).
  """
  use DemoWeb, :live_view

  @limit 5
  @max 30

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(agents: generate(0, @limit), offset: @limit, loading: false)
     |> assign(max: @max, limit: @limit)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h1>Click to Load</h1>
      <p>Trace of the <em>click-to-load</em> example - in BRHC the button issues
      <code>@@get('/more')</code> e o servidor faz append das linhas; aqui o
      <code>phx-click</code> actualiza o offset no processo e o diff acrescenta as linhas.</p>

      <div class="demo-box">
        <ul>
          <li :for={a <- @agents}>{a}</li>
        </ul>

        <button phx-click="more" disabled={@loading or @offset >= @max}>
          {cond do
            @loading -> "Loading"
            @offset >= @max -> "End of the list"
            true -> "Load More Agents (offset: #{@offset}, limit: #{@limit})"
          end}
        </button>
      </div>
    </Layouts.app>
    """
  end

  defp generate(o, n), do: for(i <- (o + 1)..(o + n), do: "Agent #{i}")

  def handle_event("more", _p, socket) do
    {:noreply,
     socket
     |> assign(loading: true)
     |> assign(:agents, socket.assigns.agents ++ generate(socket.assigns.offset, @limit))
     |> update(:offset, &(&1 + @limit))
     |> assign(loading: false)}
  end
end
