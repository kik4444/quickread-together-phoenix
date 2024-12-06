defmodule QuickreadTogether.Player do
  @moduledoc false

  use GenServer

  alias QuickreadTogether.Player
  alias QuickreadTogether.TextChunk
  alias QuickreadTogetherWeb.ReaderLive

  # --- CLIENT ---
  def start_link(_), do: GenServer.start_link(__MODULE__, %Player.State{}, name: __MODULE__)

  def get(fun) when is_function(fun, 1), do: GenServer.call(__MODULE__, {:get, fun}, :infinity)

  def play, do: GenServer.cast(__MODULE__, :play)
  def pause, do: GenServer.cast(__MODULE__, :pause)
  def restart, do: GenServer.cast(__MODULE__, :restart)
  def stop, do: GenServer.cast(__MODULE__, :stop)

  def new_text(text) when is_binary(text), do: GenServer.cast(__MODULE__, {:new_text, text})

  def new_words_per_minute(wpm) when is_integer(wpm), do: GenServer.cast(__MODULE__, {:wpm_changed, wpm})
  def new_chunk_size(cs) when is_integer(cs), do: GenServer.cast(__MODULE__, {:chunk_size_changed, cs})
  def controls_reset, do: GenServer.cast(__MODULE__, :controls_reset)
  def index_changed(new_index) when is_integer(new_index), do: GenServer.cast(__MODULE__, {:index_changed, new_index})

  # --- SERVER ---
  @impl true
  def init(init), do: {:ok, init}

  @impl true
  def handle_call({:get, fun}, _from, state), do: {:reply, fun.(state), state}

  # Initial start or resume from pause.
  @impl true
  def handle_cast(:play, %Player.State{playing: false} = state), do: {:noreply, do_play(state)}

  # Ignore invalid play events due to client latency.
  @impl true
  def handle_cast(:play, state), do: {:noreply, state}

  # Pause during play.
  @impl true
  def handle_cast(:pause, %Player.State{playing: true, textarea_locked: true} = state) do
    ReaderLive.broadcast!(:pause)

    {:noreply, %{state | playing: false}}
  end

  # Ignore invalid pause events due to client latency.
  @impl true
  def handle_cast(:pause, state), do: {:noreply, state}

  # Restart from the beginning.
  @impl true
  def handle_cast(:restart, %Player.State{} = state), do: {:noreply, do_restart(state)}

  # Stop and restart.
  @impl true
  def handle_cast(:stop, %Player.State{} = state), do: {:noreply, do_stop(state)}

  # Handle changing the textarea text while not playing or locked.
  @impl true
  def handle_cast({:new_text, new_text}, %Player.State{playing: false, textarea_locked: false} = state) do
    new_parsed_text = TextChunk.parse(new_text, state.chunk_size)

    ReaderLive.broadcast!({:new_text, new_text})
    ReaderLive.broadcast!({:update_chunks_length, tuple_size(new_parsed_text)})

    {:noreply, do_restart(%{state | parsed_text: new_parsed_text, raw_text: new_text})}
  end

  # Ignore invalid new_text requests due to latency.
  @impl true
  def handle_cast({:new_text, _text}, state), do: {:noreply, state}

  @impl true
  def handle_cast({:wpm_changed, new_wpm}, %Player.State{chunk_size: chunk_size} = state) do
    ReaderLive.broadcast!({:wpm_changed, new_wpm})

    {:noreply, %{state | words_per_minute: new_wpm, speed: calculate_speed(new_wpm, chunk_size)}}
  end

  def handle_cast({:chunk_size_changed, new_chunk_size}, %Player.State{} = state) do
    ReaderLive.broadcast!({:chunk_size_changed, new_chunk_size})

    {:noreply, do_update_chunk_size(state, new_chunk_size)}
  end

  def handle_cast(:controls_reset, %Player.State{} = state) do
    for new_state <- [wpm_changed: 300, chunk_size_changed: 1] do
      ReaderLive.broadcast!(new_state)
    end

    {:noreply, do_update_chunk_size(%{state | words_per_minute: 300}, 1)}
  end

  def handle_cast({:index_changed, new_index}, %Player.State{parsed_text: parsed_text} = state)
      when new_index in 0..(tuple_size(parsed_text) - 1)//1 do
    {:noreply, do_update_chunk(%{state | current_index: new_index})}
  end

  # Ignore invalid indices
  def handle_cast({:index_changed, _index}, state), do: {:noreply, state}

  # Display current chunk and move to the next.
  @impl true
  def handle_info(
        :next_chunk,
        %Player.State{
          parsed_text: parsed_text,
          playing: true,
          textarea_locked: true,
          current_index: current_index,
          speed: speed
        } = state
      )
      when current_index < tuple_size(parsed_text) do
    Process.send_after(self(), :next_chunk, speed)

    {:noreply, %{do_update_chunk(state, true) | current_index: current_index + 1}}
  end

  # When paused, display the current chunk anyway.
  # This is to avoid a desync when you pause, then refresh
  # and suddenly see the next chunk.
  @impl true
  def handle_info(:next_chunk, %Player.State{playing: false} = state), do: {:noreply, do_update_chunk(state)}

  # Stop when playback ended or user seeked beyond end.
  @impl true
  def handle_info(
        :next_chunk,
        %Player.State{
          parsed_text: parsed_text,
          current_index: current_index
        } = state
      )
      when current_index >= tuple_size(parsed_text) do
    {:noreply, do_stop(state)}
  end

  defp do_play(%Player.State{} = state) do
    ReaderLive.broadcast!(:play)

    send(self(), :next_chunk)

    %{state | playing: true, textarea_locked: true}
  end

  defp do_update_chunk(%Player.State{} = state, focus \\ false) do
    %TextChunk{} = text_chunk = elem(state.parsed_text, state.current_index)

    duration = calculate_duration(state)

    ReaderLive.broadcast!(
      {:update_chunk,
       %TextChunk.Update{text_chunk: text_chunk, index: state.current_index, duration: duration, focus: focus}}
    )

    %{state | duration: duration}
  end

  defp do_restart(%Player.State{} = state), do: do_update_chunk(%{state | current_index: 0})

  defp do_update_chunk_size(%Player.State{} = state, new_chunk_size) when is_integer(new_chunk_size) do
    # Recalculate what the new chunk index should be after recreating the text chunks with a different size
    new_index = recalculate_index(state.current_index, state.chunk_size, new_chunk_size)

    new_parsed_text = TextChunk.parse(state.raw_text, new_chunk_size)

    new_speed = calculate_speed(state.words_per_minute, new_chunk_size)

    ReaderLive.broadcast!({:update_chunks_length, tuple_size(new_parsed_text)})

    %{state | parsed_text: new_parsed_text, current_index: new_index, chunk_size: new_chunk_size, speed: new_speed}
  end

  defp do_stop(%Player.State{} = state) do
    ReaderLive.broadcast!(:stop)

    %{do_restart(state) | playing: false, textarea_locked: false}
  end

  defp calculate_speed(words_per_minute, chunk_size)
       when is_integer(words_per_minute) and is_integer(chunk_size) do
    (1000 / (words_per_minute / 60) * chunk_size) |> floor()
  end

  defp recalculate_index(current_index, chunk_size, new_chunk_size)
       when is_integer(current_index) and is_integer(chunk_size) and is_integer(new_chunk_size) do
    (current_index * chunk_size) |> div(new_chunk_size)
  end

  defp calculate_duration(%Player.State{} = state) do
    remaining_chunks = tuple_size(state.parsed_text) - state.current_index
    duration_seconds = (state.speed * state.chunk_size * remaining_chunks / 1000 / state.chunk_size) |> floor()

    minutes = rem(duration_seconds, 3600) |> div(60)
    seconds = rem(duration_seconds, 60)

    "#{minutes}m #{seconds}s"
  end
end
