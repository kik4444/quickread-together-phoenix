defmodule QuickreadTogetherWeb.LiveTest do
  use QuickreadTogetherWeb, :live_view

  def render(assigns) do
    ~H"""
    <div id="thermostat" phx-window-keyup="update_temp">
      Current temperature: <%= @temperature %>
    </div>
    """
  end

  def handle_event("update_temp", %{"key" => "ArrowUp"}, socket) do
    {:noreply, update(socket, :temperature, &(&1 + 1))}
  end

  def handle_event("update_temp", %{"key" => "ArrowDown"}, socket) do
    new_temp = socket.assigns.temperature - 1
    {:noreply, assign(socket, :temperature, new_temp)}
  end

  def handle_event("update_temp", _, socket) do
    {:noreply, socket}
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, temperature: 16)}
  end
end
