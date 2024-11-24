defmodule QuickreadTogetherWeb.ReaderLive do
  use QuickreadTogetherWeb, :live_view
  alias QuickreadTogether.State

  defp broadcast!(msg) do
    Phoenix.PubSub.broadcast!(QuickreadTogether.PubSub, "reader:main", msg)
  end

  def mount(_params, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(QuickreadTogether.PubSub, "reader:main")

    {:ok,
     assign(socket,
       form: %{"raw_text" => State.get(:raw_text)},
       playing: State.get(:playing)
     )}
  end

  def handle_event("text_changed", %{"raw_text" => new_text}, socket) do
    State.set({:raw_text, new_text})
    broadcast!({:new_text, new_text})

    {:noreply, socket}
  end

  def handle_event("play_pause", _, socket) do
    new_state = {:playing, not socket.assigns.playing}

    State.set(new_state)
    broadcast!(new_state)

    {:noreply, assign(socket, [new_state])}
  end

  def handle_event("reader_ended", _, socket) do
    new_state = {:playing, false}

    State.set(new_state)
    broadcast!(:reader_reset)

    {:noreply, assign(socket, [new_state])}
  end

  def handle_info({:new_text, new_text}, socket) do
    {:noreply, push_event(socket, "new_text", %{new_text: new_text})}
  end

  def handle_info({:playing, playing}, socket) do
    {:noreply, push_event(socket, "playing_toggle", %{playing: playing})}
  end

  def handle_info(:reader_reset, socket) do
    {:noreply, push_event(socket, "reader_reset", %{})}
  end
end
