defmodule QuickreadTogetherWeb.HelloController do
  use QuickreadTogetherWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end
end
