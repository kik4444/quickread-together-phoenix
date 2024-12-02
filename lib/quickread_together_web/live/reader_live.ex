defmodule QuickreadTogetherWeb.ReaderLive do
  use QuickreadTogetherWeb, :live_view

  alias QuickreadTogether.ReaderState
  alias QuickreadTogether.TextChunk
  alias QuickreadTogetherWeb.PlayerBroadcaster

  def broadcast!(msg) do
    Phoenix.PubSub.broadcast!(QuickreadTogether.PubSub, "reader:main", msg)
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(QuickreadTogether.PubSub, "reader:main")
    end

    %ReaderState{} = state = ReaderState.get(& &1)

    {:ok,
     assign(socket,
       textarea: %{"raw_text" => state.raw_text},
       playing: state.playing,
       current_chunk: state.current_chunk,
       textarea_locked: state.textarea_locked,
       controls: %{"words_per_minute" => state.words_per_minute, "chunk_size" => state.chunk_size}
     )}
  end

  def handle_event("text_changed", %{"raw_text" => new_text}, socket) do
    with false <- ReaderState.get(& &1.textarea_locked) do
      ReaderState.cast(&%{&1 | raw_text: new_text})
      broadcast!({:new_text, new_text})
    end

    {:noreply, socket}
  end

  def handle_event("play_pressed", _, socket) do
    send(PlayerBroadcaster, :play)

    {:noreply, socket}
  end

  def handle_event("pause_pressed", _, socket) do
    send(PlayerBroadcaster, :pause)

    {:noreply, socket}
  end

  # User entered empty input
  def handle_event("wpm_changed", %{"words_per_minute" => wpm}, socket) when wpm == "" do
    {:noreply, socket}
  end

  def handle_event("wpm_changed", %{"words_per_minute" => wpm}, socket) do
    {wpm, ""} = Integer.parse(wpm)

    wpm =
      cond do
        wpm < 60 -> 60
        wpm > 1000 -> 1000
        true -> wpm
      end

    ReaderState.cast(&%{&1 | words_per_minute: wpm})
    send(PlayerBroadcaster, :wpm_changed)
    broadcast!({:wpm_changed, wpm})

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
end
