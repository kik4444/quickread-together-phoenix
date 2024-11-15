defmodule QuickreadTogetherWeb.PageController do
  use QuickreadTogetherWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    put_flash(conn, :error, "Let's pretend we have an error.")
    |> render(:home, layout: false)
  end

  def red(conn, _params) do
    redirect(conn, to: ~p"/hello")
  end
end
