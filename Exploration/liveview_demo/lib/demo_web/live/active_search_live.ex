defmodule DemoWeb.ActiveSearchLive do
  @moduledoc """
  Trace of the `active-search` example do HtmlFlow-Datastar-Examples em Phoenix LiveView.

  No BRHC: `data-bind:search` + `data-on:input__debounce.200ms @get('/search')` - o termo
  viaja no `?datastar=` e o servidor devolve as linhas do tbody. Aqui: `phx-change` com
  debounce via `phx-debounce="200"`, o filtro corre no processo do servidor.
  """
  use DemoWeb, :live_view

  @contacts for(
              {f, l} <- [
                {"Abraham", "Altenwerth"},
                {"Adan", "Padberg"},
                {"Aiden", "Haley"},
                {"Alec", "Kris"},
                {"Alfredo", "Nitzsche"},
                {"Alisha", "Rogahn"},
                {"Alvah", "Bins"},
                {"Anabel", "Lehner"},
                {"Angela", "Swift"},
                {"Annamarie", "Rippin"}
              ],
              do: %{first: f, last: l}
            )

  def mount(_params, _session, socket) do
    {:ok, assign(socket, search: "", is_searching: false, all_count: length(@contacts))}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h1>Active Search</h1>
      <p>Trace of the <em>Active Search</em> example - no BRHC o termo viaja no
      <code>?datastar=</code> up to the handler (<code>@@get('/active-search/search')</code>) and the
      servidor devolve o tbody; aqui o filtro corre no processo LiveView via <code>phx-change</code>.</p>

      <div class="demo-box">
        <form phx-change="search">
          <input type="text" placeholder="Search..." phx-debounce="200" name="q" />
        </form>

        <table>
          <thead>
            <tr><th>First Name</th><th>Last Name</th></tr>
          </thead>
          <tbody>
            <tr :for={c <- filtered(@search)}><td>{c.first}</td><td>{c.last}</td></tr>
          </tbody>
        </table>

        <p class="muted">
          {if @is_searching, do: "Filtering", else: "#{length(filtered(@search))} of #{@all_count} contacts"}
        </p>
      </div>
    </Layouts.app>
    """
  end

  defp filtered(term) do
    t = String.downcase(term || "")

    if t == "",
      do: @contacts,
      else:
        Enum.filter(@contacts, fn c ->
          String.contains?(String.downcase(c.first), t) or
            String.contains?(String.downcase(c.last), t)
        end)
  end

  # Debounce analogous to Datastar's data-on:input__debounce.200ms.
  def handle_event("search", %{"q" => term}, socket) do
    {:noreply, assign(socket, search: term, is_searching: false)}
  end
end
