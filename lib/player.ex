defmodule Player do

  # Esto sería mais ben player info
  defstruct [cards: [], points: 0, pointcards: []]

  def new(name) do
    %Player{name: name}
  end

end
