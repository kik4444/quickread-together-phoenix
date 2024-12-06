defmodule QuickreadTogetherWeb.Presence do
  @moduledoc """
  Provides presence tracking to channels and processes.

  See the [`Phoenix.Presence`](https://hexdocs.pm/phoenix/Phoenix.Presence.html)
  docs for more details.
  """

  use Phoenix.Presence,
    otp_app: :quickread_together,
    pubsub_server: QuickreadTogether.PubSub

  alias QuickreadTogetherWeb.ReaderLive

  # --- CLIENT ---
  def track(key), do: track(self(), "reader_count", key, %{})
  def get_reader_count, do: list("reader_count") |> map_size()

  # --- SERVER ---
  @impl true
  def init(_), do: {:ok, nil}

  @impl true
  def handle_metas("reader_count", _diff, presences, state) do
    ReaderLive.broadcast!({:reader_count, map_size(presences)})

    {:ok, state}
  end
end
