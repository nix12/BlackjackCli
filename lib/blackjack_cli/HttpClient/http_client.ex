defmodule BlackjackCli.HttpClient do
  use GenServer

  @behaviour BlackjackCli.HttpClientBehaviour

  @host 'localhost'

  def start_link(protocol) do
    IO.puts("IN CLIENT")

    GenServer.start_link(__MODULE__, protocol,
      name: BlackjackCli.via_tuple(Registry.App, protocol)
    )
  end

  @impl true
  def http_get(url) do
    GenServer.call(Process.whereis(__MODULE__), {:http_get, url})
  end

  @impl true
  def http_post(url, data) do
    GenServer.call(Process.whereis(__MODULE__), {:http_post, url, data})
  end

  @impl true
  def socket_upgrade(url) do
    GenServer.call(Process.whereis(__MODULE__), {:socket_upgrade, url})
  end

  @impl true
  def socket_send(data) do
    GenServer.cast(Process.whereis(__MODULE__), {:socket_send, data})
  end

  @impl true
  def init(protocol) do
    IO.inspect(protocol, label: "PROTOCOL")
    {:ok, _} = :application.ensure_all_started(:gun)

    connect_opts = %{
      connect_timeout: 60000,
      retry: 10,
      retry_timeout: 300,
      transport: :tcp,
      protocols: [:http],
      http_opts: %{version: :"HTTP/1.1", keepalive: :infinity}
    }

    conn_pid =
      case protocol do
        :ws ->
          ws_init(connect_opts)

        :http ->
          http_init(connect_opts)
      end

    {:ok, %{conn_pid: conn_pid, caller: nil, streamref: nil}}
  end

  @impl true
  def handle_cast({:socket_send, data}, %{conn_pid: conn_pid} = state) do
    :gun.ws_send(conn_pid, {:text, Jason.encode!(data)})
    {:noreply, state}
  end

  @impl true
  def handle_call({:socket_upgrade, url}, from, %{conn_pid: conn_pid} = state) do
    streamref = :gun.ws_upgrade(conn_pid, url, [{"content-type", "application/json"}])

    {:noreply, %{state | caller: from, streamref: streamref}}
  end

  @impl true
  def handle_call({:http_get, url}, from, %{conn_pid: conn_pid} = state) do
    streamref = :gun.get(conn_pid, url)
    state = %{state | caller: from, streamref: streamref}

    send(self(), {:process_request})
    {:noreply, state}
  end

  def handle_call({:http_post, url, data}, from, %{conn_pid: conn_pid} = state) do
    streamref =
      :gun.post(conn_pid, url, [{"content-type", "application/json"}], Jason.encode!(data))

    state = %{state | caller: from, streamref: streamref}

    send(self(), {:process_request})
    {:noreply, state}
  end

  @impl true
  def handle_info(
        {:process_request},
        %{conn_pid: conn_pid, streamref: streamref, caller: caller} = state
      ) do
    response =
      case :gun.await(conn_pid, streamref) do
        {response, :fin, _status, _headers} ->
          IO.inspect(response, label: "NO DATA  ======>")
          :no_data

        {response, :nofin, status, headers} ->
          {:ok, body} = :gun.await_body(conn_pid, streamref)
          IO.inspect(Jason.decode!(body), label: "BODY")
          %{headers: headers, status: status, body: Jason.decode!(body)}

        {:error, reason} ->
          IO.inspect(reason, label: "ERROR")
          IO.inspect(self(), label: "SELF")
          IO.inspect(state, label: "STATE")
      end

    IO.inspect(response, label: "PROCESS REQUEST RESPONSE")
    GenServer.reply(caller, response)
    {:noreply, state}
  end

  def handle_info({:gun_up, _conn_pid, _protocol}, state) do
    {:noreply, state}
  end

  # {:gun_down, #PID<0.291.0>, :http, :closed, [], []}
  def handle_info({:gun_down, _conn_pid, _protocol, x, y, z}, state) do
    {:noreply, state}
  end

  def handle_info({:gun_response, _conn_pid, _streamref, :nofin, _status, _headers}, state) do
    {:noreply, state}
  end

  def handle_info({:gun_data, _conn_pid, _streamref, :fin, _data}, state) do
    {:noreply, state}
  end

  def handle_info({:gun_upgrade, conn_pid, _streamref, ["websocket"], _headers} = upgrade, state) do
    IO.inspect(upgrade, label: "UPGRADE")
    :gun.ws_send(conn_pid, {:text, Jason.encode!("THIS IS FROM THE CLIENT")})
    {:noreply, state}
  end

  def handle_info({:gun_response, _, _, _status, _headers} = gun_response, state) do
    IO.inspect(gun_response, label: "GUN RESPONSE")
    {:noreply, state}
  end

  def handle_info({:gun_error, _conn_pid, _streamref, _errors}, state) do
    {:noreply, state}
  end

  def handle_info(
        {:gun_ws, _conn_pid, _streamref, frame},
        %{conn_pid: conn_pid, caller: caller} = state
      ) do
    IO.inspect(frame, label: "FRAME")
    GenServer.reply(caller, frame)
    {:noreply, state}
  end

  def ws_init(connect_opts) do
    {:ok, conn_pid} = :gun.open(@host, Application.get_env(:blackjack_cli, :port), connect_opts)
    {:ok, _protocol} = :gun.await_up(conn_pid, :timer.minutes(1))
    # :gun.ws_upgrade(conn_pid, "/socket/server/first")

    conn_pid
  end

  def http_init(connect_opts) do
    {:ok, conn_pid} = :gun.open(@host, Application.get_env(:blackjack_cli, :port), connect_opts)
    {:ok, _protocol} = :gun.await_up(conn_pid, :timer.minutes(1))

    conn_pid
  end
end
