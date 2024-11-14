defmodule QuickreadTogetherWeb.HelloHTML do
  use QuickreadTogetherWeb, :html

  def index(assigns) do
    ~H"""
    <strong>Hello!</strong>
    """
  end
end
