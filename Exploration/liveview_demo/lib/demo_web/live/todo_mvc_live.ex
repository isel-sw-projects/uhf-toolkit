defmodule DemoWeb.TodoMvcLive do
  @moduledoc """
  Trace of the `todo-mvc` example from HtmlFlow-Datastar-Examples in Phoenix LiveView.

  In BRHC: full CRUD with `data-init @@get('/todo-mvc/updates')` (SSE), `@post/@patch/
  @delete/@put mode`, editing by double-click. Here: assigns + handle_event for the same
  operations; the filters (all/active/completed) are a `mode` assign.
  """
  use DemoWeb, :live_view

  defmodule Task do
    defstruct [:id, :title, :completed, :editing]
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, tasks: [], mode: "all", input: "")}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h1>TodoMVC</h1>
      <p>Trace of the <em>todo-mvc</em> example - no BRHC o estado vive num
      <code>ConcurrentHashMap&lt;UUID, MutableStateFlow&gt;</code> and mutations arrive over
      <code>@@post</code>/<code>@@patch</code>/<code>@@delete</code>; here they live in a list in
      the process and every handle_event re-renders.</p>

      <div class="demo-box">
      <form phx-submit="add" class="todo-add">
        <input type="text" name="title" placeholder="What needs to be done?" value={@input} autofocus />
      </form>

      <ul class="todo-list">
        <li :for={t <- visible(@tasks, @mode)} class={if t.completed, do: "completed", else: ""}>
          <%= if t.editing do %>
            <% # Row being edited: one form per li (LiveView submits only this form's inputs);
            # Escape cancela via phx-window-keydown no form %>
            <form phx-submit="commit-edit" phx-window-keydown="blur-edit" phx-key="Escape"
                  phx-value-id={t.id} class="todo-edit">
              <input type="text" name="title" value={t.title} />
            </form>
          <% else %>
            <input type="checkbox" phx-click="toggle" phx-value-id={t.id} checked={t.completed} />
            <% # In BRHC editing opens by double-click (data-on:dblclick). LiveView has
            # no phx-double-click - the equivalent is the event on a button/label. %>
            <label phx-click="edit" phx-value-id={t.id} title="Clica para editar">{t.title}</label>
            <button class="destroy" phx-click="remove" phx-value-id={t.id} aria-label="Remove">✕</button>
          <% end %>
        </li>
      </ul>

      <div class="todo-footer">
        <span>{count_active(@tasks)} itens restantes</span>
        <div class="todo-filters">
          <button :for={m <- ["all", "active", "completed"]} phx-click="set-mode" phx-value-mode={m}
                  class={"todo-filter" <> if @mode == m, do: " selected", else: ""}>
            {m}
          </button>
        </div>
        <button phx-click="clear-completed">Clear completed</button>
      </div>
      </div>
    </Layouts.app>
    """
  end

  defp visible(tasks, "active"), do: Enum.filter(tasks, &(!&1.completed))
  defp visible(tasks, "completed"), do: Enum.filter(tasks, & &1.completed)
  defp visible(tasks, _), do: tasks

  defp count_active(tasks), do: Enum.count(tasks, &(!&1.completed))

  def handle_event("add", %{"title" => ""}, socket), do: {:noreply, socket}

  def handle_event("add", %{"title" => title}, socket) do
    task = %Task{
      id: Ecto.UUID.generate(),
      title: String.trim(title),
      completed: false,
      editing: false
    }

    {:noreply, socket |> update(:tasks, &(&1 ++ [task])) |> assign(input: "")}
  end

  def handle_event("toggle", %{"id" => id}, socket) do
    {:noreply, update(socket, :tasks, &toggle_task(&1, id))}
  end

  def handle_event("remove", %{"id" => id}, socket) do
    {:noreply, update(socket, :tasks, &Enum.reject(&1, fn t -> t.id == id end))}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    {:noreply, update(socket, :tasks, &mark_editing(&1, id))}
  end

  def handle_event("blur-edit", %{"key" => "Escape"}, socket) do
    {:noreply, update(socket, :tasks, &stop_editing(&1))}
  end

  def handle_event("blur-edit", _params, socket), do: {:noreply, socket}

  def handle_event("commit-edit", %{"id" => id, "title" => ""}, socket) do
    handle_event("remove", %{"id" => id}, socket)
  end

  def handle_event("commit-edit", %{"id" => id, "title" => title}, socket) do
    {:noreply,
     update(socket, :tasks, fn tasks ->
       Enum.map(tasks, fn
         %{id: ^id} = t -> %{t | title: title, editing: false}
         t -> t
       end)
     end)}
  end

  def handle_event("set-mode", %{"mode" => m}, socket), do: {:noreply, assign(socket, mode: m)}

  def handle_event("clear-completed", _p, socket) do
    {:noreply,
     update(socket, :tasks, fn tasks -> Enum.reject(tasks, fn t -> t.completed end) end)}
  end

  defp toggle_task(tasks, id) do
    Enum.map(tasks, fn
      %{id: ^id} = t -> %{t | completed: !t.completed}
      t -> t
    end)
  end

  defp mark_editing(tasks, id) do
    Enum.map(tasks, fn
      %{id: ^id} = t -> %{t | editing: true}
      t -> %{t | editing: false}
    end)
  end

  defp stop_editing(tasks), do: Enum.map(tasks, &%{&1 | editing: false})
end
