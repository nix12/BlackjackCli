defmodule BlackjackCli.Views.Menu.State do
  @moduledoc """
    Updates the terminal view of the menu view.
  """

  import Ratatouille.Constants, only: [key: 1]

  @up key(:arrow_up)
  @down key(:arrow_down)
  @enter key(:enter)

  @type model() :: Map.t()
  @type event() :: {atom(), map()}

  @doc """
     Takes a model and an event to evaluate and update menu view.
  """
  @spec update(model(), event()) :: map()
  def update(model, msg) do
    case msg do
      {:event, %{ch: ?w}} ->
        %{model | input: max(model.input - 1, 0)}

      {:event, %{key: @up}} ->
        %{model | input: max(model.input - 1, 0)}

      {:event, %{ch: ?s}} ->
        %{model | input: min(model.input + 1, length(screens()) - 1)}

      {:event, %{key: @down}} ->
        %{model | input: min(model.input + 1, length(screens()) - 1)}

      {:event, %{key: @enter}} ->
        %{model | screen: match_screen(model.input)}

      _ ->
        model
    end
  end

  defp screens do
    [:servers, :search, :account, :settings, :exit]
  end

  defp match_screen(index) do
    Enum.find(screens(), &(screens() |> Enum.at(index) == &1))
  end
end