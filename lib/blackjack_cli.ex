defmodule BlackjackCli do
  alias BlackjackCli.Client

  @http Application.get_env(:blackjack_cli, :http, HttpClient)
  @http Application.get_env(:blackjack_cli, :ws, HttpClient)

  def via_tuple(registry, name) do
    {:via, Registry, {registry, name}}
  end

  def format_name(name) do
    name
    |> String.trim()
    |> String.replace(" ", "_")
    |> String.to_atom()
  end

  def unformat_name(name) do
    name
    |> String.trim()
    |> String.replace("_", " ", global: true)
  end

  @spec blank?(charlist() | nil) :: boolean()
  def blank?(str_or_nil) do
    case str_or_nil do
      "" -> true
      nil -> true
      _ -> false
    end
  end

  # def fetch_server(server_name) do
  #   @http.http_get("/server/#{server_name |> BlackjackCli.format_name()}")
  # end

  # def fetch_servers do
  #   @http.http_get("/servers") |> IO.inspect(label: "FETCH SERVERS CLI")
  # end

  def get_server(server_name) do
    GenServer.call(
      BlackjackCli.via_tuple(Registry.App, :http),
      {:http_get, "/server/#{server_name |> BlackjackCli.format_name()}"}
    )
  end

  def get_servers do
    GenServer.call(BlackjackCli.via_tuple(Registry.App, :http), {:http_get, "/servers"})
  end

  # def subscribe_server(_model) do
  #   :timer.send_interval(5000, :gui, {:event, :subscribe_server})
  # end

  def join_server(user, server_name) do
    GenServer.call(
      BlackjackCli.via_tuple(Registry.App, :ws),
      {:socket_upgrade, "/socket/server/#{server_name |> BlackjackCli.format_name()}"}
    )

    GenServer.cast(
      BlackjackCli.via_tuple(Registry.App, :ws),
      {:socket_send, %{server_name: server_name, user: user}}
    )
  end

  # def leave_server(username, server_name) do
  #   @http.http_post(
  #     "/server/#{server_name |> BlackjackCli.format_name()}/leave",
  #     %{server_name: server_name, username: username}
  #   )
  # end

  # Routes

  def login_path(user_params) do
    GenServer.call(
      BlackjackCli.via_tuple(Registry.App, :http),
      {:http_post, "/login", user_params}
    )
  end

  def register_path(user_params) do
    GenServer.call(
      BlackjackCli.via_tuple(Registry.App, :http),
      {:http_post, "/regkster", user_params}
    )
  end
end
