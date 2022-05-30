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
    Menu
  }

  # @initial_state %{
  #   input: 0,
  #   menu: true,
  #   user: nil,
  #   screen: :start,
  #   key: "",
  #   data: []
  # }

  def init() do
    # Process.register(self(), :gui)
    %{body: body} = BlackjackCli.get_servers() |> IO.inspect(label: "GET SERVERS INIT")

    GuiServer.update_model(%{data: body})
  end

  @spec update(map(), tuple()) :: map()
  def update(model, msg) do
    case {model, msg} do
      {%{key: ""}, :check_token} ->
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

      {%{key: ""} = model, _} ->
        Start.State.update(model, msg)

      _ ->
        model
    end
  end

  defp check_token(model) do
    case model.key do
      key when is_nil(key) == false or key != "" ->
        model

      _ ->
        BlackjackCli.Views.Login.State.start_login()
        put_in(model.screen, :login)
    end
  end
end
