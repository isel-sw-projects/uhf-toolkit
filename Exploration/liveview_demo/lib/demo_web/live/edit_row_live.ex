defmodule DemoWeb.EditRowLive do
  @moduledoc """
  Trace of the `edit-row` example do HtmlFlow-Datastar-Examples em Phoenix LiveView.

  No BRHC: `data-signals:_editing` por linha + `@@get('/edit-row/{i}')` devolve a linha
  in edit mode (patch-elements). Here: an `editing_index` assign swaps the row; the
  `phx-submit` grava no processo.
  """
  use DemoWeb, :live_view

  @users for(
           i <- 1..5,
           do: %{id: i, first: "First#{i}", last: "Last#{i}", email: "user#{i}@example.com"}
         )

  def mount(_params, _session, socket) do
    {:ok, assign(socket, users: @users, editing_index: nil)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h1>Edit Row</h1>
      <p>Trace of the <em>edit-row</em> example - in BRHC the row toggles view/form via
      fragments (<code>@@get</code>/<code>@@put</code>); aqui o assign <code>editing_index</code>
      comuta o render da linha no servidor.</p>

      <div class="demo-box">
      <table>
        <thead><tr><th>#</th><th>First</th><th>Last</th><th>Email</th><th></th></tr></thead>
        <tbody>
          <% # A <form> cannot live inside a <tr> (invalid HTML - the browser
             # ejects it from the table). LiveView solution: an extra column acts as the
             # "form row" - the <form phx-submit> lives in that td and, in edit mode,
             # os inputs das outras td referenciam-no pelo atributo form=. O
             # navegador trata-os como parte do form, o LiveView recebe o submit. %>
          <tr :for={{u, i} <- Enum.with_index(@users)}>
            <td>{i}</td>
            <%= if @editing_index == i do %>
              <td><input form={"edit-row-#{i}"} type="text" name="first" value={u.first} /></td>
              <td><input form={"edit-row-#{i}"} type="text" name="last" value={u.last} /></td>
              <td><input form={"edit-row-#{i}"} type="text" name="email" value={u.email} /></td>
              <td>
                <form id={"edit-row-#{i}"} phx-submit="save" phx-value-index={i}>
                  <button type="submit">Save</button>
                </form>
              </td>
            <% else %>
              <td>{u.first}</td><td>{u.last}</td><td>{u.email}</td>
              <td><button phx-click="edit" phx-value-index={i}>Edit</button></td>
            <% end %>
          </tr>
        </tbody>
      </table>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("edit", %{"index" => i}, socket),
    do: {:noreply, assign(socket, editing_index: String.to_integer(i))}

  # Os inputs referenciam o form pelo atributo form= - o submit chega com os
  # valores de todos os inputs da linha, como num <form> normal.
  def handle_event("save", params, socket) do
    i = String.to_integer(params["index"])

    {:noreply,
     socket
     |> update(:users, fn users ->
       List.update_at(users, i, fn u ->
         %{u | first: params["first"], last: params["last"], email: params["email"]}
       end)
     end)
     |> assign(editing_index: nil)}
  end
end
