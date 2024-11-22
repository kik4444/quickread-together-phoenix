defmodule QuickreadTogetherWeb.ReaderLive do
  use QuickreadTogetherWeb, :live_view
  alias Phoenix.PubSub
  alias QuickreadTogether.State

  def mount(_params, _session, socket) do
    if connected?(socket), do: PubSub.subscribe(QuickreadTogether.PubSub, "reader:main")

    {:ok, assign(socket, raw_text: %{"value" => State.get(:raw_text)})}
  end

  def handle_event("text_changed", %{"raw_text" => new_text}, socket) do
    State.set({:raw_text, new_text})
    PubSub.broadcast!(QuickreadTogether.PubSub, "reader:main", {:new_text, new_text})
    {:noreply, socket}
  end

  def handle_info({:new_text, new_text}, socket) do
    {:noreply, push_event(socket, "new_text", %{new_text: new_text})}
  end
end
