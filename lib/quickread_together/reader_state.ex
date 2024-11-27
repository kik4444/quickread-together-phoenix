defmodule QuickreadTogether.ReaderState do
  @moduledoc """
  Contains the state used by a reader room
  """
  use Agent

  defstruct raw_text: "Welcome to Quickread Together. Press start to begin reading quickly.",
            current_chunk: "Quickread Together",
            playing: false,
            textarea_locked: false

  def start_link(_), do: Agent.start_link(fn -> %__MODULE__{} end, name: __MODULE__)

  def get(fun) when is_function(fun, 1), do: Agent.get(__MODULE__, fun, :infinity)

  def cast(fun) when is_function(fun, 1), do: Agent.cast(__MODULE__, fun)
end
