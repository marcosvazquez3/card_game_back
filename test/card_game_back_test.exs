defmodule CardGameBackTest do
  use ExUnit.Case
  doctest CardGameBack

  test "greets the world" do
    assert CardGameBack.hello() == :world
  end
end
