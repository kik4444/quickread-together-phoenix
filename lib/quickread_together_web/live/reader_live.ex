defmodule QuickreadTogetherWeb.ReaderLive do
  use QuickreadTogetherWeb, :live_view

  alias QuickreadTogether.Player
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

  def mount(_params, _session, %Phoenix.LiveView.Socket{} = socket) do
    if connected?(socket) do
      QuickreadTogetherWeb.Presence.track(socket.id)
      Phoenix.PubSub.subscribe(QuickreadTogether.PubSub, "reader:main")
    end

    %Player.State{} = state = Player.get(& &1)

    {:ok,
     assign(socket,
       textarea: %{"raw_text" => state.raw_text},
       playing: state.playing,
       current_chunk: elem(state.parsed_text, clamp(state.current_index, 0, tuple_size(state.parsed_text) - 1)).chunk,
       current_index: state.current_index,
       chunks_length: tuple_size(state.parsed_text) - 1,
       duration: state.duration,
       textarea_locked: state.textarea_locked,
       controls: %{"words_per_minute" => state.words_per_minute, "chunk_size" => state.chunk_size},
       reader_count: QuickreadTogetherWeb.Presence.get_reader_count()
     )}
  end

  def handle_event("text_changed", %{"raw_text" => new_text}, socket) do
    Player.new_text(new_text)

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

  def handle_event("stop_pressed", _, socket) do
    with true <- socket.assigns.textarea_locked, do: Player.stop()

    {:noreply, socket}
  end

  def handle_event("wpm_changed", %{"words_per_minute" => wpm}, socket) do
    with {parsed, ""} <- Integer.parse(wpm),
         clamped <- clamp(parsed, 60, 1000) do
      Player.new_words_per_minute(clamped)
      broadcast!({:wpm_changed, clamped})
    end

    {:noreply, socket}
  end

  def handle_event("chunk_size_changed", %{"chunk_size" => chunk_size}, socket) do
    with {parsed, ""} <- Integer.parse(chunk_size),
         clamped <- clamp(parsed, 1, 10) do
      Player.new_chunk_size(clamped)
      broadcast!({:chunk_size_changed, clamped})
    end

    {:noreply, socket}
  end

  def handle_event("controls_reset_pressed", _, socket) do
    Player.controls_reset()

    {:noreply, socket}
  end

  def handle_event("index_changed", %{"index" => new_index}, socket) do
    {index, ""} = Integer.parse(new_index)

    Player.index_changed(index)

    {:noreply, socket}
  end

  # Change multiple fields that are common between ReaderLive and Player.State
  def handle_info({:multiple_assigns_changes, changes}, socket) when is_list(changes) do
    {:noreply, assign(socket, changes)}
  end

  def handle_info({:new_text, new_text}, socket) do
    {:noreply,
     assign(socket, textarea: %{"raw_text" => new_text})
     # We use push_event for inputs because updating the assigns
     # won't change the input's value on the frontend if the user is focused on it.
     |> push_event("new_text", %{new_text: new_text})}
  end

  def handle_info({:playing, _} = new_state, socket) do
    {:noreply, assign(socket, [new_state])}
  end

  def handle_info({:textarea_locked, _} = new_state, socket) do
    {:noreply, assign(socket, [new_state])}
  end

  def handle_info({:update_chunk, %TextChunk.Update{text_chunk: %TextChunk{}} = msg}, socket) do
    socket = assign(socket, current_chunk: msg.text_chunk.chunk, current_index: msg.index, duration: msg.duration)

    if msg.focus do
      {:noreply,
       push_event(socket, "select_range", %{
         start_offset: msg.text_chunk.start_offset,
         stop_offset: msg.text_chunk.stop_offset
       })}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:update_chunks_length, length}, socket) do
    {:noreply, assign(socket, chunks_length: length - 1)}
  end

  def handle_info(:selection_blur, socket) do
    {:noreply, push_event(socket, "selection_blur", %{})}
  end

  def handle_info({:wpm_changed, wpm}, socket) do
    {:noreply,
     assign(socket, controls: %{socket.assigns.controls | "words_per_minute" => wpm})
     |> push_event("wpm_changed", %{wpm: wpm})}
  end

  def handle_info({:chunk_size_changed, chunk_size}, socket) do
    {:noreply,
     assign(socket, controls: %{socket.assigns.controls | "chunk_size" => chunk_size})
     |> push_event("chunk_size_changed", %{chunk_size: chunk_size})}
  end

  def handle_info({:reader_count, reader_count}, socket) do
    {:noreply, assign(socket, reader_count: reader_count)}
  end
end
