defmodule BlackjackCli.Views.FriendRequest.State do
  import Ratatouille.Constants, only: [key: 1]

  @up key(:arrow_up)
  @down key(:arrow_down)
  @space_bar key(:space)
  @tab key(:tab)
  @enter key(:enter)

  @delete_keys [
    key(:delete),
    key(:backspace),
    key(:backspace2)
  ]

  def update(model, msg) do
    case msg do
      {:event, %{key: @tab}} ->
        switch_menus(model)

      {:event, %{ch: ?w}} ->
        %{model | input: max(model.input - 1, 0)}

      {:event, %{key: @down}} ->
        %{
          model
          | input: min(model.input + 1, length(menu()) - 1)
        }

      {:event, %{ch: ?s}} ->
        %{
          model
          | input: min(model.input + 1, length(menu()) - 1)
        }

      {:event, %{key: @up}} ->
        %{model | input: max(model.input - 1, 0)}

      {:event, %{key: key}} when key in @delete_keys ->
        %{model | input: String.slice(model.input, 0..-2)}

      {:event, %{key: @space_bar}} ->
        %{model | input: model.input <> " "}

      {:event, %{ch: ch}} when ch > 0 ->
        %{model | input: model.input <> <<ch::utf8>>}

      {:event, %{key: @enter}} ->
        if model.menu == false do
          response = BlackjackCli.create_friendship(model.input)

          %{model | input: "", screen: :friend_request, data: %{notice: response}}
        else
          case match_menu(model) do
            :menu ->
              %{model | screen: match_menu(model), input: 0}

            _ ->
              %{model | screen: match_menu(model), input: ""}
          end
        end

      _ ->
        model
    end
  end

  defp menu do
    [:friend_request, :menu]
  end

  defp match_menu(model) do
    menu()
    |> Enum.at(model.input)
  end

  def switch_menus(model) do
    %{model | input: 0, menu: !model.menu}
  end
end
