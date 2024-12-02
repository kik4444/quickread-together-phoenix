defmodule QuickreadTogether.Player do
  use GenServer

  alias QuickreadTogether.TextChunk
  alias QuickreadTogether.PlayerState
  alias QuickreadTogetherWeb.ReaderLive

  def start_link(_), do: GenServer.start_link(__MODULE__, %PlayerState{}, name: __MODULE__)

  defp calculate_speed(words_per_minute, chunk_size)
       when is_integer(words_per_minute) and is_integer(chunk_size) do
    (1000 / (words_per_minute / 60) * chunk_size) |> floor()
  end

  # --- CLIENT ---
  def get(fun) when is_function(fun, 1), do: GenServer.call(__MODULE__, {:get, fun}, :infinity)

  def set(fun) when is_function(fun, 1), do: GenServer.cast(__MODULE__, {:set, fun})

  def play(), do: GenServer.cast(__MODULE__, :play)
  def pause(), do: GenServer.cast(__MODULE__, :pause)
  def cast(args) when is_tuple(args), do: GenServer.cast(__MODULE__, args)

  # --- SERVER STATE ---
  @impl true
  def init(init), do: {:ok, init}

  @impl true
  def handle_call({:get, fun}, _from, state), do: {:reply, fun.(state), state}

  @impl true
  def handle_cast({:set, fun}, state), do: {:noreply, fun.(state)}

  # --- SERVER PLAYER ---

  # Initial start.
  @impl true
  def handle_cast(:play, %PlayerState{playing: false, textarea_locked: false} = state) do
    # TODO better way to do this?
    changes = [playing: true, textarea_locked: true]

    state = Map.merge(state, Map.new(changes))

    for new_state <- changes do
      ReaderLive.broadcast!(new_state)
    end

    parsed_text = TextChunk.parse(state.raw_text, state.chunk_size)
    speed = calculate_speed(state.words_per_minute, state.chunk_size)

    send(self(), :next_chunk)

    {:noreply, %{state | parsed_text: parsed_text, current_index: 0, speed: speed}}
  end

  # Pause during play.
  @impl true
  def handle_cast(:pause, %PlayerState{playing: true, textarea_locked: true} = state) do
    ReaderLive.broadcast!({:playing, false})

    {:noreply, %{state | playing: false}}
  end

  # Ignore invalid pause events due to client latency.
  @impl true
  def handle_cast(:pause, state), do: {:noreply, state}

  # Resume from pause.
  @impl true
  def handle_cast(:play, %PlayerState{playing: false, textarea_locked: true} = state) do
    ReaderLive.broadcast!({:playing, true})

    send(self(), :next_chunk)

    {:noreply, %{state | playing: true}}
  end

  # Ignore invalid resume events due to client latency.
  @impl true
  def handle_cast(:play, state), do: {:noreply, state}

  # words_per_minute changed
  @impl true
  def handle_cast({:wpm_changed, new_wpm}, %PlayerState{chunk_size: chunk_size} = state) do
    {:noreply, %{state | words_per_minute: new_wpm, speed: calculate_speed(new_wpm, chunk_size)}}
  end

  # chunk_size changed
  # TODO

  # Display current chunk and move to the next.
  @impl true
  def handle_info(
        :next_chunk,
        %PlayerState{
          parsed_text: parsed_text,
          playing: true,
          textarea_locked: true,
          current_index: current_index,
          speed: speed
        } = state
      )
      when current_index < tuple_size(parsed_text) do
    %TextChunk{} = text_chunk = elem(parsed_text, current_index)

    ReaderLive.broadcast!({:update_chunk, text_chunk})

    Process.send_after(self(), :next_chunk, speed)

    {:noreply, %{state | current_index: current_index + 1}}
  end

  # Do nothing when paused.
  @impl true
  def handle_info(:next_chunk, %PlayerState{playing: false} = state), do: {:noreply, state}

  # Playback ended or user seeked beyond end.
  @impl true
  def handle_info(
        :next_chunk,
        %PlayerState{
          parsed_text: parsed_text,
          current_index: current_index
        } = state
      )
      when current_index >= tuple_size(parsed_text) do
    changes = [playing: false, textarea_locked: false]

    for new_state <- changes do
      ReaderLive.broadcast!(new_state)
    end

    ReaderLive.broadcast!(:selection_blur)

    state = Map.merge(state, Map.new(changes))

    {:noreply, %{state | current_index: tuple_size(parsed_text) - 1}}
  end
end
