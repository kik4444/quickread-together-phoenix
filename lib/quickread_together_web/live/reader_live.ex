defmodule QuickreadTogetherWeb.ReaderLive do
  use QuickreadTogetherWeb, :live_view

  alias QuickreadTogether.State
  alias QuickreadTogether.TextChunk
  alias QuickreadTogetherWeb.PlayerBroadcaster

  def broadcast!(msg) do
    Phoenix.PubSub.broadcast!(QuickreadTogether.PubSub, "reader:main", msg)
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(QuickreadTogether.PubSub, "reader:main")
    end

    {:ok,
     assign(socket,
       textarea: %{"raw_text" => State.get(:raw_text)},
       playing: State.get(:playing),
       current_chunk: State.get(:current_chunk),
       paused_in_play: State.get(:paused_in_play)
     )}
  end

  def handle_event("text_changed", %{"raw_text" => new_text}, socket) do
    State.set({:raw_text, new_text})
    broadcast!({:new_text, new_text})

    {:noreply, socket}
  end

  def handle_event("play_pause", _, socket) do
    playing = not socket.assigns.playing
    new_state = {:playing, playing}

    State.set(new_state)
    broadcast!(new_state)

    if playing do
      send(PlayerBroadcaster, :start)
    end

    {:noreply, socket}
  end

  def handle_info({:new_text, new_text}, socket) do
    {:noreply, assign(socket, textarea: %{"raw_text" => new_text})}
  end

  def handle_info({:playing, _} = new_state, socket) do
    {:noreply, assign(socket, [new_state])}
  end

  def handle_info({:paused_in_play, _} = new_state, socket) do
    {:noreply, assign(socket, [new_state])}
  end

  def handle_info({:update_chunk, %TextChunk{} = parsed_chunk}, socket) do
    # TODO select range in textarea
    {:noreply, assign(socket, current_chunk: parsed_chunk.chunk)}
  end
end
