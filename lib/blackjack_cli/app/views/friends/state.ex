defmodule BlackjackCli.Views.Friends.State do
  import Ratatouille.Constants, only: [key: 1]

  alias Ratatouille.Runtime.Command
  alias BlackjackCli.Views.FriendRequest.FriendRequestForm

  @up key(:arrow_up)
  @down key(:arrow_down)
  @enter key(:enter)
  @tab key(:tab)

  @type model() :: Map.t()
  @type event() :: {atom(), map()}

  @doc """
     Takes a model and an event to evaluate and update menu view.
  """
  @spec update(model(), event()) :: map()
  def update(model, msg) do
    friends =
      model.data["friends"]
      |> Enum.sort_by(
        &(&1["inserted_at"] |> NaiveDateTime.from_iso8601!()),
        {:asc, NaiveDateTime}
      )

    case msg do
      {:event, %{key: @tab}} ->
        switch_menus(model)

      {:event, %{ch: ?w}} ->
        update_cmd(%{model | input: max(model.input - 1, 0)})

      {:event, %{key: @down}} ->
        if model.menu do
          %{
            model
            | input: min(model.input + 1, length(menu()) - 1)
          }
        else
          update_cmd(%{
            model
            | input: min(model.input + 1, length(friends) - 1)
          })
        end

      {:event, %{ch: ?s}} ->
        update_cmd(%{
          model
          | input: min(model.input + 1, length(friends) - 1)
        })

      {:event, %{key: @up}} ->
        if model.menu do
          %{model | input: max(model.input - 1, 0)}
        else
          update_cmd(%{model | input: max(model.input - 1, 0)})
        end

      {:event, %{key: @enter}} ->
        if model.menu == false do
          %{"username" => username} = match_friends(friends, model.input)

          %{
            model
            | screen: :friends,
              data: username
          }
        else
          case match_menu(model) do
            :menu ->
              %{model | screen: match_menu(model), input: 0}

            :friend_request ->
              FriendRequestForm.start_link([])
              %{model | input: "", menu: false, screen: match_menu(model)}

            _ ->
              %{model | input: "", menu: false, screen: match_menu(model)}
          end
        end

      _ ->
        model
    end
  end

  def menu do
    [:find_user, :friend_request, :menu]
  end

  defp match_menu(model) do
    menu()
    |> Enum.at(model.input)
  end

  defp match_friends(friends, index) do
    friends
    |> Enum.find(fn friend ->
      friends |> Enum.at(index) == friend
    end)
  end

  defp update_cmd(model) do
    # IO.inpsect(label: "GET friends")
    friends = model.data
    # BlackjackCli.get_friends()

    list_friends =
      if Enum.count(friends) > 0 and model.menu == false do
        friends
      else
        []
      end

    Command.new(fn -> list_friends end, :friends_updated)

    model
  end

  def switch_menus(model) do
    %{model | menu: !model.menu}
  end
end
