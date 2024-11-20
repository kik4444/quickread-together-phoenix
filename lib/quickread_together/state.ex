# Implements multiple readers single writer access to an ETS table.
#
# Writes to the ETS are serialized through this GenServer,
# while reads are performed by the caller process concurrently.

defmodule QuickreadTogether.State do
  use GenServer

  @impl true
  def init(_) do
    :state = :ets.new(:state, [:set, :protected, :named_table])
    true = :ets.insert(:state, {:raw_text, "Press start to begin reading quickly."})
    {:ok, nil}
  end

  @impl true
  def handle_cast({_field, _value} = args, _) do
    true = :ets.insert(:state, args)
    {:noreply, nil}
  end

  def start_link(_), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  def get(field) do
    [{^field, value}] = :ets.lookup(:state, field)
    value
  end

  def set({_field, _value} = args), do: GenServer.cast(__MODULE__, args)
end
