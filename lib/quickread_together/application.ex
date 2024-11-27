defmodule QuickreadTogether.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      QuickreadTogether.ReaderState,
      QuickreadTogetherWeb.PlayerBroadcaster,
      QuickreadTogetherWeb.Telemetry,
      {Phoenix.PubSub, name: QuickreadTogether.PubSub},
      # Start a worker by calling: QuickreadTogether.Worker.start_link(arg)
      # {QuickreadTogether.Worker, arg},
      # Start to serve requests, typically the last entry
      QuickreadTogetherWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: QuickreadTogether.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    QuickreadTogetherWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
