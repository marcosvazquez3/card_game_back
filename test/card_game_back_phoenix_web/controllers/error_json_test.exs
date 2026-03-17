defmodule CardGameBackPhoenixWeb.ErrorJSONTest do
  use CardGameBackPhoenixWeb.ConnCase, async: true

  test "renders 404" do
    assert CardGameBackPhoenixWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert CardGameBackPhoenixWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
