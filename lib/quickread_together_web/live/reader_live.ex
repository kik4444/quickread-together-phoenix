defmodule QuickreadTogetherWeb.ReaderLive do
  use QuickreadTogetherWeb, :live_view
  alias Phoenix.PubSub
  alias QuickreadTogether.State

  def render(assigns) do
    ~H"""
    <main class="h-screen w-screen grid place-items-center">
      <.form for={@raw_text} phx-change="text_changed">
        <textarea
          id="textarea"
          placeholder="Enter text to read quickly."
          class="min-w-[50vw]"
          name="raw_text"
          phx-debounce="500"
        ><%= @raw_text["value"] %></textarea>
      </.form>

      <p id="display" class="font-semibold leading-[1.3] tracking-normal antialiased">
        TEMP
      </p>
      <button>Start</button>
    </main>
    """
  end

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
