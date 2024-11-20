# Implements multiple readers single writer access to an ETS table.
#
# Writes to the ETS are serialized through this GenServer,
# while reads are performed by the caller process concurrently.

defmodule QuickreadTogether.State do
  use GenServer

  @impl true
  def init(_) do
    :state = :ets.new(:state, [:set, :protected, :named_table])
    true = :ets.insert(:state, {:text, "Press start to begin reading quickly."})
    {:ok, nil}
  end

  @impl true
  def handle_cast({:update, new_state}, _) do
    true = :ets.insert(:state, {:text, new_state})
    {:noreply, nil}
  end

  def start_link(_), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  def get do
    [text: text] = :ets.lookup(:state, :text)
    text
  end

  def set(new_state), do: GenServer.cast(__MODULE__, {:update, new_state})
end
