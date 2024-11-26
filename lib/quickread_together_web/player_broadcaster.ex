defmodule QuickreadTogetherWeb.PlayerBroadcaster do
  @moduledoc """
  Called from ReaderLive to start playback of the current text.
  This moves through every chunk and broadcasts a message to all clients
  to update their currently shown chunk.
  """
  use GenServer

  alias QuickreadTogether.State
  alias QuickreadTogether.TextChunk
  alias QuickreadTogetherWeb.ReaderLive

  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @impl true
  def init(init), do: {:ok, init}

  # Clean start.
  @impl true
  def handle_info(:start, []) do
    # TODO chunk_size
    parsed_chunks = TextChunk.parse(State.get(:raw_text))

    send(self(), :next_chunk)

    {:noreply, parsed_chunks}
  end

  # Resume from pause.
  @impl true
  def handle_info(:start, [%TextChunk{} | _] = total_left) do
    send(self(), :next_chunk)

    {:noreply, total_left}
  end

  # Move to the next chunk.
  # If paused, do nothing.
  @impl true
  def handle_info(:next_chunk, [%TextChunk{} = current_chunk | tail] = total_left) do
    case State.get(:playing) do
      true ->
        ReaderLive.broadcast!({:update_chunk, current_chunk})

        # TODO words_per_minute
        Process.send_after(self(), :next_chunk, 300)

        {:noreply, tail}

      false ->
        {:noreply, total_left}
    end
  end

  # End of chunks to show.
  @impl true
  def handle_info(:next_chunk, []) do
    new_state = {:playing, false}

    State.set(new_state)
    ReaderLive.broadcast!(new_state)

    {:noreply, []}
  end
end
