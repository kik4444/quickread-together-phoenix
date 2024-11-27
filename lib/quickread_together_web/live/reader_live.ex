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
       textarea_locked: state.textarea_locked
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

  def handle_info({:new_text, new_text}, socket) do
    {:noreply, assign(socket, textarea: %{"raw_text" => new_text})}
  end

  def handle_info({:playing, _} = new_state, socket) do
    {:noreply, assign(socket, [new_state])}
  end

  def handle_info({:textarea_locked, _} = new_state, socket) do
    {:noreply, assign(socket, [new_state])}
  end

  def handle_info({:update_chunk, %TextChunk{} = parsed_chunk}, socket) do
    # TODO select range in textarea
    {:noreply, assign(socket, current_chunk: parsed_chunk.chunk)}
  end
end
