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

  # TODO use struct to hold your state:
  # tuple of parsed text
  # current index
  # calculated speed
  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @impl true
  def init(init), do: {:ok, init}

  # Clean start.
  @impl true
  def handle_info(:play, []) do
    changes = Keyword.from_keys([:playing, :textarea_locked], true)

    ReaderState.cast(&Map.merge(&1, Map.new(changes)))

    for new_state <- changes do
      ReaderLive.broadcast!(new_state)
    end

    # TODO variable chunk_size in runtime
    {raw_text, chunk_size} = ReaderState.get(&{&1.raw_text, &1.chunk_size})
    parsed_chunks = TextChunk.parse(raw_text, chunk_size)

    send(self(), :next_chunk)

    {:noreply, parsed_chunks}
  end

  # Pause during play
  @impl true
  def handle_info(:pause, state) do
    with true <- ReaderState.get(& &1.playing) do
      ReaderState.cast(&%{&1 | playing: false})
      ReaderLive.broadcast!({:playing, false})
    end

    {:noreply, state}
  end

  # Resume from pause.
  @impl true
  def handle_info(:play, [%TextChunk{} | _] = total_left) do
    # Due to client latency, it's possible we may get a resume signal while we're already playing,
    # so we should check that to avoid jumping over a chunk too quickly.
    with false <- ReaderState.get(& &1.playing) do
      ReaderState.cast(&%{&1 | playing: true})
      ReaderLive.broadcast!({:playing, true})

      send(self(), :next_chunk)
    end

    {:noreply, total_left}
  end

  # Move to the next chunk.
  # If paused, save current chunk.
  @impl true
  def handle_info(:next_chunk, [%TextChunk{} = current_chunk | tail] = total_left) do
    ReaderLive.broadcast!({:update_chunk, current_chunk})

    {playing, chunk_size, wpm} =
      ReaderState.get(&{&1.playing, &1.chunk_size, &1.words_per_minute})

    speed = (1000 / (wpm / 60) * chunk_size) |> floor()

    case playing do
      true ->
        # TODO words_per_minute
        Process.send_after(self(), :next_chunk, speed)

        {:noreply, tail}

      false ->
        # Save current chunk when pause is first observed
        # to sync it to newly-joined clients.
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

    ReaderLive.broadcast!(:selection_blur)

    {:noreply, []}
  end
end
