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

  @derive {Inspect, except: [:parsed_text]}
  defstruct parsed_text: {%TextChunk{}},
            current_index: 0,
            speed: nil

  def start_link(_), do: GenServer.start_link(__MODULE__, %__MODULE__{}, name: __MODULE__)

  @impl true
  def init(init), do: {:ok, init}

  defp calculate_speed(words_per_minute, chunk_size)
       when is_integer(words_per_minute) and is_integer(chunk_size) do
    (1000 / (words_per_minute / 60) * chunk_size) |> floor()
  end

  # Clean start.
  # 0 and nil are interpreted as starting from the beginning.
  @impl true
  def handle_info(:play, %__MODULE__{current_index: 0, speed: nil}) do
    changes = [playing: true, textarea_locked: true]

    ReaderState.cast(&Map.merge(&1, Map.new(changes)))

    for new_state <- changes do
      ReaderLive.broadcast!(new_state)
    end

    # TODO variable chunk_size in runtime
    {raw_text, wpm, chunk_size} =
      ReaderState.get(&{&1.raw_text, &1.words_per_minute, &1.chunk_size})

    parsed_text = TextChunk.parse(raw_text, chunk_size)
    speed = calculate_speed(wpm, chunk_size)

    send(self(), :next_chunk)

    {:noreply, %__MODULE__{parsed_text: parsed_text, current_index: 0, speed: speed}}
  end

  # Pause during play
  @impl true
  def handle_info(:pause, %__MODULE__{} = state) do
    with true <- ReaderState.get(& &1.playing) do
      %TextChunk{} = current_chunk = elem(state.parsed_text, state.current_index)

      # Save current chunk when pause is first observed
      # to sync it to newly-joined clients.
      ReaderState.cast(&%{&1 | playing: false, current_chunk: current_chunk.chunk})

      ReaderLive.broadcast!({:playing, false})
    end

    {:noreply, %{state | speed: nil}}
  end

  # Resume from pause.
  @impl true
  def handle_info(:play, %__MODULE__{current_index: n, speed: nil} = state) when n > 0 do
    # Due to client latency, it's possible we may get a resume signal while we're already playing,
    # so we should check that to avoid jumping over a chunk too quickly.
    with false <- ReaderState.get(& &1.playing) do
      ReaderState.cast(&%{&1 | playing: true})
      ReaderLive.broadcast!({:playing, true})

      send(self(), :next_chunk)
    end

    {wpm, chunk_size} = ReaderState.get(&{&1.words_per_minute, &1.chunk_size})

    speed = calculate_speed(wpm, chunk_size)

    {:noreply, %{state | speed: speed}}
  end

  # Do nothing when next_chunk is called while paused.
  @impl true
  def handle_info(:next_chunk, %__MODULE__{speed: nil} = state), do: {:noreply, state}

  # End of chunks to show.
  @impl true
  def handle_info(:next_chunk, %__MODULE__{parsed_text: parsed_text, current_index: n} = state)
      when n >= tuple_size(parsed_text) do
    changes = [playing: false, textarea_locked: false]

    ReaderState.cast(&Map.merge(&1, Map.new(changes)))

    for new_state <- changes do
      ReaderLive.broadcast!(new_state)
    end

    ReaderLive.broadcast!(:selection_blur)

    {:noreply, %{state | current_index: 0, speed: nil}}
  end

  # Move to the next chunk.
  @impl true
  def handle_info(:next_chunk, %__MODULE__{speed: speed} = state) do
    %TextChunk{} = current_chunk = elem(state.parsed_text, state.current_index)

    ReaderLive.broadcast!({:update_chunk, current_chunk})

    Process.send_after(self(), :next_chunk, speed)

    {:noreply, %{state | current_index: state.current_index + 1}}
  end
end
