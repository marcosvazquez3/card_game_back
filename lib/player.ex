defmodule Player do

  @enforce_keys [:name]
  defstruct [:name]

  def new(name) do
    %Player{name: name}
  end

end
