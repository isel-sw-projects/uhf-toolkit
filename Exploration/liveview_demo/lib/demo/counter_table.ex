defmodule Demo.CounterTable do
  @moduledoc """
  The shared counter, held by one process.

  Every read and every increment is a message to this process, so the operations are
  serialised by construction: two views clicking at the same time cannot lose an
  increment, which the previous read-then-write through `:persistent_term` allowed.
  The process outlives requests and connections.
  """
  use GenServer

  def start_link(_ \\ :ok), do: GenServer.start_link(__MODULE__, 0, name: __MODULE__)

  def value, do: GenServer.call(__MODULE__, :value)
  def increment, do: GenServer.call(__MODULE__, :increment)

  @impl true
  def init(value), do: {:ok, value}

  @impl true
  def handle_call(:value, _from, value), do: {:reply, value, value}
  def handle_call(:increment, _from, value), do: {:reply, value + 1, value + 1}
end
