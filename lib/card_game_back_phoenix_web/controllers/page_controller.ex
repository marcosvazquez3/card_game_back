defmodule CardGameBackPhoenixWeb.PageController do
  use CardGameBackPhoenixWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
