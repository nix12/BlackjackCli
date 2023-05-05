defmodule BlackjackCli do
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

  def connect_user(user, token) do
    Task.Supervisor.async(BlackjackCli.TaskSupervisor, fn ->
      GenServer.call(
        BlackjackCli.via_tuple(Registry.App, :ws),
        {:socket_upgrade, "/socket/user/#{user["id"]}", token, self()},
        :timer.minutes(5)
      )
    end)
  end

  def get_friends do
    Task.Supervisor.async(BlackjackCli.TaskSupervisor, fn ->
      send_data([:friendship, :read], %{}, self())
    end)
    |> Task.await(:timer.seconds(5))
  end

  def get_inbox(option) do
    Task.Supervisor.async(BlackjackCli.TaskSupervisor, fn ->
      send_data([:message, %{"read" => option |> to_string()}], %{}, self())
    end)
    |> Task.await(:timer.seconds(5))
  end

  def create_friendship(username) do
    Task.Supervisor.async(BlackjackCli.TaskSupervisor, fn ->
      send_data([:friendship, :create], %{requested_user_username: username}, self())
    end)
    |> Task.await(:timer.seconds(5))
  end

  def get_server(server_name) do
    GenServer.call(
      BlackjackCli.via_tuple(Registry.App, :http),
      {:http_get, "/server/#{server_name |> BlackjackCli.format_name()}"}
    )
    |> IO.inspect(label: "GET SERVER")
  end

  def get_servers(token) do
    GenServer.call(BlackjackCli.via_tuple(Registry.App, :http), {:http_get, "/servers", token})
  end

  def join_server(user, server_name, token) do
    Task.Supervisor.async(BlackjackCli.TaskSupervisor, fn ->
      pid = spawn(fn -> send_data(:join_server, %{user: user, server_name: server_name}) end)

      GenServer.call(
        BlackjackCli.via_tuple(Registry.App, :ws),
        {:socket_upgrade, "/socket/server/#{server_name |> BlackjackCli.format_name()}", token,
         pid}
      )
    end)
    |> Task.await(:timer.seconds(5))
  end

  def leave_server(user, server_name, _token) do
    Task.Supervisor.async(BlackjackCli.TaskSupervisor, fn ->
      send_data(:leave_server, %{user: user, server_name: server_name}, self())
    end)
    |> Task.await(:timer.seconds(5))
  end

  def send_data(action, payload, pid \\ nil) do
    if pid do
      GenServer.cast(
        BlackjackCli.via_tuple(Registry.App, :ws),
        {:socket_send, action, payload, pid}
      )
    end

    receive do
      {:ok, :upgraded} ->
        GenServer.cast(
          BlackjackCli.via_tuple(Registry.App, :ws),
          {:socket_send, action, payload, pid}
        )

      {:close, data} ->
        data
    end
  end

  # Routes

  def login_path(user_params) do
    GenServer.call(
      BlackjackCli.via_tuple(Registry.App, :http),
      {:http_post, "/login", user_params, nil}
    )
  end

  def register_path(user_params) do
    GenServer.call(
      BlackjackCli.via_tuple(Registry.App, :http),
      {:http_post, "/register", user_params, nil}
    )
  end
end
