defmodule QuickreadTogetherWeb.HelloController do
  use QuickreadTogetherWeb, :controller

  def index(conn, _params) do
    assign(conn, :value, "custom value") |> render(:index)
  end
end
