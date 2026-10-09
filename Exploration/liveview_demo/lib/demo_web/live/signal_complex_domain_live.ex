defmodule DemoWeb.SignalComplexDomainLive do
  @moduledoc """
  Trace of the `signal-complex-domain` example do HtmlFlow-Datastar-Examples em Phoenix LiveView.

  In BRHC: nested signals (`data-signals={person:{name,age}}`, `$person.name`) and buttons
  `@@put` to mutate. Here: a `%{name:, age:}` map in the assign - the nested path is the
  chave do mapa; pattern matching substitui o caminho de signal.
  """
  use DemoWeb, :live_view

  @users [%{name: "John", age: 30}, %{name: "Jane", age: 25}]

  def mount(_params, _session, socket) do
    {:ok, assign(socket, person: hd(@users), user_index: 0)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h1>Signal Complex Domain</h1>
      <p>Trace of the <em>signal-complex-domain</em> example - os sinais aninhados
      (<code>$person.name</code>, <code>$person.age</code>) correspondem aqui a um mapa no
      assign; os <code>@@put</code> do BRHC tornam-se <code>phx-click</code>.</p>

      <div class="demo-box">
      <dl>
        <dt>Name</dt><dd>{@person.name}</dd>
        <dt>Age</dt><dd>{@person.age}</dd>
      </dl>

      <button phx-click="increase-age">Increase Age</button>
      <button phx-click="switch-user">Switch User</button>
    </div>
    </Layouts.app>
    """
  end

  def handle_event("increase-age", _p, socket) do
    {:noreply, update(socket, :person, fn p -> %{p | age: p.age + 1} end)}
  end

  def handle_event("switch-user", _p, socket) do
    idx = rem(socket.assigns.user_index + 1, length(@users))
    {:noreply, assign(socket, user_index: idx, person: Enum.at(@users, idx))}
  end
end
