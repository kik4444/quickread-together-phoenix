defmodule QuickreadTogetherWeb.ReaderLive do
  use QuickreadTogetherWeb, :live_view

  alias QuickreadTogether.Player
  alias QuickreadTogether.PlayerState
  alias QuickreadTogether.TextChunk

  defp clamp(value, min, max) when is_number(value) and is_number(min) and is_number(max) do
    cond do
      value < min -> min
      value > max -> max
      true -> value
    end
  end

  def broadcast!(msg) do
    Phoenix.PubSub.broadcast!(QuickreadTogether.PubSub, "reader:main", msg)
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(QuickreadTogether.PubSub, "reader:main")
    end

    %PlayerState{} = state = Player.get(& &1)

    {:ok,
     assign(socket,
       textarea: %{"raw_text" => state.raw_text},
       playing: state.playing,
       current_chunk: elem(state.parsed_text, clamp(state.current_index, 0, tuple_size(state.parsed_text) - 1)).chunk,
       textarea_locked: state.textarea_locked,
       controls: %{"words_per_minute" => state.words_per_minute, "chunk_size" => state.chunk_size}
     )}
  end

  def handle_event("text_changed", %{"raw_text" => new_text}, socket) do
    # Due to client latency, one client may send a text_changed event
    # after we've started playing, so we must ignore it.
    with false <- Player.get(& &1.textarea_locked) do
      Player.set(&%{&1 | raw_text: new_text})
      broadcast!({:new_text, new_text})
    end

    {:noreply, socket}
  end

  def handle_event("play_pressed", _, socket) do
    Player.play()

    {:noreply, socket}
  end

  def handle_event("pause_pressed", _, socket) do
    Player.pause()

    {:noreply, socket}
  end

  def handle_event("restart_pressed", _, socket) do
    Player.restart()

    {:noreply, socket}
  end

  # Ignore empty input
  def handle_event("wpm_changed", %{"words_per_minute" => wpm}, socket) when wpm == "" do
    {:noreply, socket}
  end

  def handle_event("wpm_changed", %{"words_per_minute" => wpm}, socket) do
    {wpm, ""} = Integer.parse(wpm)
    wpm = clamp(wpm, 60, 1000)

    Player.cast({:wpm_changed, wpm})

    broadcast!({:wpm_changed, wpm})

    {:noreply, socket}
  end

  # Ignore empty input
  def handle_event("chunk_size_changed", %{"chunk_size" => chunk_size}, socket) when chunk_size == "" do
    {:noreply, socket}
  end

  def handle_event("chunk_size_changed", %{"chunk_size" => chunk_size}, socket) do
    {chunk_size, ""} = Integer.parse(chunk_size)
    chunk_size = clamp(chunk_size, 1, 10)

    Player.cast({:chunk_size_changed, chunk_size})

    broadcast!({:chunk_size_changed, chunk_size})

    {:noreply, socket}
  end

  def handle_info({:new_text, new_text}, socket) do
    {:noreply, push_event(socket, "new_text", %{new_text: new_text})}
  end

  def handle_info({:playing, _} = new_state, socket) do
    {:noreply, assign(socket, [new_state])}
  end

  def handle_info({:textarea_locked, _} = new_state, socket) do
    {:noreply, assign(socket, [new_state])}
  end

  def handle_info({:update_chunk, %TextChunk{} = text_chunk}, socket) do
    {:noreply,
     assign(socket, current_chunk: text_chunk.chunk)
     |> push_event("select_range", %{
       start_offset: text_chunk.start_offset,
       stop_offset: text_chunk.stop_offset
     })}
  end

  def handle_info(:selection_blur, socket) do
    {:noreply, push_event(socket, "selection_blur", %{})}
  end

  def handle_info({:wpm_changed, wpm}, socket) do
    {:noreply, assign(socket, controls: %{socket.assigns.controls | "words_per_minute" => wpm})}
  end

  def handle_info({:chunk_size_changed, chunk_size}, socket) do
    {:noreply, assign(socket, controls: %{socket.assigns.controls | "chunk_size" => chunk_size})}
  end
end
