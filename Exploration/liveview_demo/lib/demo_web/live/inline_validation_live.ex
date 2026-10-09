defmodule DemoWeb.InlineValidationLive do
  @moduledoc """
  Trace of the `inline-validation` example do HtmlFlow-Datastar-Examples em Phoenix LiveView.

  No BRHC: `data-on:keydown__debounce.500ms @@post('/validate')` - o servidor valida
  campo a campo e devolve patch-signals/patch-elements com os erros. Aqui:
  `phx-change` + `phx-debounce="500"`; the rules run in the process (unique email =
  test@test.com, nomes ≥ 2 caracteres).
  """
  use DemoWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket, form: %{"email" => "", "first_name" => "", "last_name" => ""}, errors: %{})}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h1>Inline Validation</h1>
      <p>Trace of the <em>inline-validation</em> example - in BRHC every keystroke (debounced)
      sends the field to <code>@@post('/validate')</code> and errors come back in patch-signals;
      here <code>phx-change</code> + <code>phx-debounce</code> validate in the process and errors
      chegam no diff.</p>

      <div class="demo-box">
      <form phx-change="validate">
        <label>Email
          <input type="text" name="email" value={@form["email"]} phx-debounce="500" />
        </label>
        <span class="error">{@errors["email"]}</span>

        <label>First Name
          <input type="text" name="first_name" value={@form["first_name"]} phx-debounce="500" />
        </label>
        <span class="error">{@errors["first_name"]}</span>

        <label>Last Name
          <input type="text" name="last_name" value={@form["last_name"]} phx-debounce="500" />
        </label>
        <span class="error">{@errors["last_name"]}</span>

        <button type="submit" disabled={map_size(@errors) > 0 or form_incomplete?(@form)}>Submit</button>
      </form>
      </div>
    </Layouts.app>
    """
  end

  defp form_incomplete?(form), do: Enum.any?(form, fn {_k, v} -> v == "" end)

  # Rules identical to the BRHC server (email=test@test.com, names >= 2 chars).
  def handle_event("validate", params, socket) do
    errors =
      %{}
      |> maybe_error("email", params["email"] == "test@test.com", "Email already registered")
      |> maybe_error(
        "first_name",
        String.length(params["first_name"] || "") < 2,
        "Minimum 2 characters"
      )
      |> maybe_error(
        "last_name",
        String.length(params["last_name"] || "") < 2,
        "Minimum 2 characters"
      )

    {:noreply, assign(socket, form: params, errors: errors)}
  end

  defp maybe_error(map, key, true, msg), do: Map.put(map, key, msg)
  defp maybe_error(map, _key, false, _msg), do: map
end
