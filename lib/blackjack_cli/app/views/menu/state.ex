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
        %{model | input: min(model.input + 1, length(menu()) - 1)}

      {:event, %{key: @down}} ->
        %{model | input: min(model.input + 1, length(menu()) - 1)}

      {:event, %{key: @enter}} ->
        menu_option = match_menu(model.input)

        %{
          model
          | input: 0,
            menu: false,
            screen: menu_option,
            data: menu_option |> match_data(model.token)
        }

      _ ->
        model
    end
  end

  defp menu do
    [:servers, :search, :friends, :inbox, :account, :settings, :exit]
  end

  defp match_menu(index) do
    Enum.find(menu(), &(menu() |> Enum.at(index) == &1))
  end

  def match_data(menu_option, token) do
    case menu_option do
      :servers ->
        BlackjackCli.get_servers(token)

      :friends ->
        BlackjackCli.get_friends()

      :inbox ->
        BlackjackCli.get_inbox(:all)
    end
  end
end
