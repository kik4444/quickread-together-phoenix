defmodule QuickreadTogetherWeb.ReaderLive do
  use QuickreadTogetherWeb, :live_view
  alias Phoenix.PubSub

  def render(assigns) do
    ~H"""
    <main class="h-screen w-screen grid place-items-center">
      <.form for={@text} phx-change="text_changed">
        <textarea
          id="textarea"
          placeholder="Enter text to read quickly."
          class="min-w-[50vw]"
          name="text"
          phx-debounce="500"
        ><%= @text["content"] %></textarea>
      </.form>

      <p id="display" class="font-semibold leading-[1.3] tracking-normal antialiased">
        TEMP
      </p>
      <button>Start</button>
    </main>
    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket), do: PubSub.subscribe(QuickreadTogether.PubSub, "new_text")

    {:ok, assign(socket, text: %{"content" => "Press start to begin reading quickly."})}
  end

  def handle_event("text_changed", %{"text" => text}, socket) do
    PubSub.broadcast!(QuickreadTogether.PubSub, "new_text", {:new_text, text})
    {:noreply, socket}
  end

  def handle_info({:new_text, new_text}, socket) do
    {:noreply, push_event(socket, "new_text", %{new_text: new_text})}
  end
end
