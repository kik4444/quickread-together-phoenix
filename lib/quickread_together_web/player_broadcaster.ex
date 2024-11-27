defmodule QuickreadTogetherWeb.PlayerBroadcaster do
  @moduledoc """
  Called from ReaderLive to start playback of the current text.
  This moves through every chunk and broadcasts a message to all clients
  to update their currently shown chunk.
  """
  use GenServer

  alias QuickreadTogether.ReaderState
  alias QuickreadTogether.TextChunk
  alias QuickreadTogetherWeb.ReaderLive

  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @impl true
  def init(init), do: {:ok, init}

  # Clean start.
  @impl true
  def handle_info(:start, []) do
    # TODO chunk_size
    parsed_chunks = TextChunk.parse(ReaderState.get(& &1.raw_text))

    ReaderState.cast(&%{&1 | textarea_locked: true})
    ReaderLive.broadcast!({:textarea_locked, true})

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
  # If paused, save current chunk.
  @impl true
  def handle_info(:next_chunk, [%TextChunk{} = current_chunk | tail] = total_left) do
    ReaderLive.broadcast!({:update_chunk, current_chunk})

    case ReaderState.get(& &1.playing) do
      true ->
        # TODO words_per_minute
        Process.send_after(self(), :next_chunk, 300)

        {:noreply, tail}

      false ->
        # Save current chunk when pause is first observed
        # to sync it to newly-joined clients
        ReaderState.cast(&%{&1 | current_chunk: current_chunk.chunk})

        {:noreply, total_left}
    end
  end

  # End of chunks to show.
  @impl true
  def handle_info(:next_chunk, []) do
    changes = [playing: false, textarea_locked: false]

    ReaderState.cast(&Map.merge(&1, Map.new(changes)))

    for new_state <- changes do
      ReaderLive.broadcast!(new_state)
    end

    {:noreply, []}
  end
end
