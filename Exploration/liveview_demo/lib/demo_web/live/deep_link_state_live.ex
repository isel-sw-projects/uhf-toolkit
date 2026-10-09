defmodule DemoWeb.DeepLinkStateLive do
  @moduledoc """
  Trace of the `deeplink-state` example em Phoenix LiveView.

  In BRHC: the server reads filter/page from the query string and seeds the `data-signals`/rows
  with that state - the served page is already right. Here: `handle_params`
  (LiveView's native API for URL params); every interaction uses `patch` to
  escrever a URL sem recarregar, e o LiveView recebe `handle_params` de novo -
  deep linking maintained in both directions.
  """
  use DemoWeb, :live_view

  @per_page 4
  @max_page 3

  def mount(_params, _session, socket), do: {:ok, assign(socket, max_page: @max_page)}

  # The URL is the source of state - on mount and on every patch
  def handle_params(params, _url, socket) do
    filter = params["filter"] || "all"
    page = parse_int(params["page"], 1) |> clamp(1, @max_page)

    {:noreply, assign(socket, filter: filter, page: page)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h1>Deep-Link State</h1>
      <p>Trace of the <em>deeplink-state</em> example - no BRHC o servidor semeia os
      <code>data-signals</code> com o estado vindo da URL; aqui <code>handle_params</code>
      reads the query and <code>push_navigate</code>/patch keeps the URL in sync.</p>

      <div class="demo-box">
        <div class="btn-group mb-3" role="group">
          <button :for={f <- ["all", "active", "inactive"]}
                  phx-click="set-filter" phx-value-filter={f}
                  class={if @filter == f, do: "btn btn-sm btn-primary", else: "btn btn-sm btn-outline-primary"}>
            {f}
          </button>
        </div>

        <nav aria-label="Page">
          <span>Current page: <strong>{@page}</strong></span>
          <button phx-click="prev-page" class="btn btn-sm btn-outline-secondary ms-2" disabled={@page <= 1}>‹</button>
          <button phx-click="next-page" class="btn btn-sm btn-outline-secondary" disabled={@page >= @max_page}>›</button>
        </nav>

        <table class="mt-3">
          <thead><tr><th>Contact</th><th>Estado</th></tr></thead>
          <tbody>
            <tr :for={c <- paged(@filter, @page)}>
              <td>Contact {c}</td><td>{if rem(c, 3) == 0, do: "inactive", else: "active"}</td>
            </tr>
          </tbody>
        </table>

        <p class="muted">A URL reflecte o estado - recarregar/ligar directamente restaura a mesma vista.</p>
      </div>
    </Layouts.app>
    """
  end

  # eventos: escrever a URL (patch) - o estado volta por handle_params
  def handle_event("set-filter", %{"filter" => f}, socket) do
    {:noreply, push_patch(socket, to: "/deeplink-state?filter=#{f}&page=1")}
  end

  def handle_event("prev-page", _p, socket),
    do: navigate(socket, socket.assigns.page - 1)

  def handle_event("next-page", _p, socket),
    do: navigate(socket, socket.assigns.page + 1)

  defp navigate(socket, page) do
    {:noreply,
     push_patch(socket, to: "/deeplink-state?filter=#{socket.assigns.filter}&page=#{page}")}
  end

  defp paged(filter, page) do
    contacts =
      case filter do
        "active" -> Enum.filter(1..12, &(rem(&1, 3) != 0))
        "inactive" -> Enum.filter(1..12, &(rem(&1, 3) == 0))
        _ -> Enum.to_list(1..12)
      end

    contacts |> Enum.drop((page - 1) * @per_page) |> Enum.take(@per_page)
  end

  defp parse_int(nil, default), do: default
  defp parse_int(s, default) do
    case Integer.parse(s) do
      {n, _} -> n
      :error -> default
    end
  end

  defp clamp(n, min, _max) when n < min, do: min
  defp clamp(n, _min, max) when n > max, do: max
  defp clamp(n, _min, _max), do: n
end
