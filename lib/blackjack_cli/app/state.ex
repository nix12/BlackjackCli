defmodule BlackjackCli.App.State do
  @moduledoc """
    Main state for frontend application
  """
  alias BlackjackCli.GuiServer
  alias BlackjackCli.Client

  alias BlackjackCli.Views.{
    Start,
    Login,
    Registration,
    Account,
    Server,
    Servers,
    CreateServer,
    Games,
    Search,
    Dashboard,
    Menu,
    Friends,
    Inbox,
    FriendRequest
  }

  @initial_state %{
    input: 0,
    menu: true,
    user: nil,
    screen: :start,
    token: "",
    data: []
  }

  def init() do
    # Process.register(self(), :gui)
    # put_in(@initial_state.data, BlackjackCli.get_servers())
    Registry.register(Registry.App, :gui, %{})
   

    @initial_state
  end

  @spec update(map(), tuple()) :: map()
  def update(model, msg) do
    case {model, msg} do
      {%{token: ""}, :check_token} ->
        check_token(model)

      {%{screen: :start}, _} ->
        Start.State.update(model, msg)

      {%{screen: :login}, _} ->
        Login.State.update(model, msg)

      {%{screen: :registration} = model, _} ->
        Registration.State.update(model, msg)

      {%{screen: :account} = model, _} ->
        Account.update(model, msg)

      {%{screen: :server} = model, msg} ->
        Server.State.update(model, msg)

      {%{screen: :servers} = model, _} ->
        Servers.State.update(model, msg)

      {%{screen: :create_server} = model, _} ->
        CreateServer.update(model, msg)

      {%{screen: :games} = model, _} ->
        Games.update(model, msg)

      {%{screen: :search} = model, _} ->
        Search.update(model, msg)

      {%{screen: :dashboard} = model, _} ->
        Dashboard.update(model, msg)

      {%{screen: :menu} = model, _} ->
        Menu.State.update(model, msg)

      {%{screen: :friends} = model, _} ->
        Friends.State.update(model, msg)

      {%{screen: :inbox} = model, _} ->
        Inbox.State.update(model, msg)

      {%{screen: :friend_request} = model, _} ->
        FriendRequest.State.update(model, msg)

      {%{token: ""} = model, _} ->
        Start.State.update(model, msg)

      _ ->
        model
    end
  end

  defp check_token(model) do
    case model.token do
      token when is_nil(token) == false or token != "" ->
        model

      _ ->
        BlackjackCli.Views.Login.State.start_login()
        put_in(model.screen, :login)
    end
  end
end
