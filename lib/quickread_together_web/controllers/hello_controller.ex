defmodule QuickreadTogetherWeb.HelloController do
  use QuickreadTogetherWeb, :controller

  def index(conn, _params) do
    assign(conn, :value, "custom value") |> render(:index)
  end

  def show(conn, %{"messenger" => messenger}) do
    render(conn, :show, messenger: messenger)
  end
end
