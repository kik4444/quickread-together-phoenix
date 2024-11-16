defmodule QuickreadTogetherWeb.LiveTest do
  use QuickreadTogetherWeb, :live_view

  def render(assigns) do
    ~H"""
    Current temperature: <%= @temperature %>°C <button phx-click="increase_temp">+</button>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, temperature: 16)}
  end

  def handle_event("increase_temp", _params, socket) do
    {:noreply, update(socket, :temperature, &(&1 + 1))}
  end
end
