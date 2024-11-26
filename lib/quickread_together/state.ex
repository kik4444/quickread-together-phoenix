defmodule QuickreadTogether.State do
  @moduledoc """
  Implements multiple readers single writer access to an ETS table.

  Writes to the ETS are serialized through this GenServer,
  while reads are performed by the caller process concurrently.

  """
  use GenServer

  @initial_state [
    raw_text: "Welcome to Quickread Together. Press start to begin reading quickly.",
    playing: false
  ]

  @impl true
  def init(_) do
    :state = :ets.new(:state, [:set, :protected, :named_table])

    for key_val <- @initial_state do
      true = :ets.insert(:state, key_val)
    end

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
