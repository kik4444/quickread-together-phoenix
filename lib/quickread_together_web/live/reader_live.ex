defmodule QuickreadTogetherWeb.ReaderLive do
  use QuickreadTogetherWeb, :live_view
  alias QuickreadTogether.State

  defp broadcast!(msg) do
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
       current_chunk: "Quickread Together"
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

    {:noreply, socket}
  end

  def handle_info({:new_text, new_text}, socket) do
    {:noreply, push_event(socket, "new_text", %{new_text: new_text})}
  end

  def handle_info({:playing, _} = new_state, socket) do
    {:noreply, assign(socket, [new_state])}
  end
end
