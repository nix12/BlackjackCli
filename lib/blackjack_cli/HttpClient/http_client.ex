defmodule BlackjackCli.HttpClient do
  use GenServer

  @behaviour BlackjackCli.HttpClientBehaviour

  @host 'localhost'

  def start_link(protocol) do
    GenServer.start_link(__MODULE__, protocol,
      name: BlackjackCli.via_tuple(Registry.App, protocol)
    )
  end

  # @impl true
  # def http_get(url) do
  #   GenServer.call(Process.whereis(__MODULE__), {:http_get, url})
  # end

  # @impl true
  # def http_post(url, data) do
  #   GenServer.call(Process.whereis(__MODULE__), {:http_post, url, data})
  # end

  # def socket_upgrade(url) do
  #   GenServer.call(BlackjackCli.via_tuple(Registry.App, :ws), {:socket_upgrade, url})
  # end

  # def socket_send(action, data) do
  #   GenServer.cast(BlackjackCli.via_tuple(Registry.App, :ws), {:socket_send, action, data})
  # end

  @impl true
  def init(protocol) do
    # IO.inpsect(protocol, label: "PROTOCOL")
    {:ok, _} = :application.ensure_all_started(:gun)

    connect_opts = %{
      connect_timeout: 60000,
      retry: 10,
      retry_timeout: 100,
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

    {:ok, %{conn_pid: conn_pid, caller: nil, streamref: nil, called_from: nil}}
  end

  @impl true
  def handle_cast(
        {:socket_send, action, data, called_from},
        %{conn_pid: conn_pid, streamref: streamref} = state
      ) do
    # IO.puts("SOCKET SEND")
    socket_send = %{action: action, payload: data} |> Jason.encode!()

    :gun.ws_send(conn_pid, streamref, {:text, socket_send})
    {:noreply, %{state | called_from: called_from}}
  end

  # def handle_cast({:socket_close, data}, %{conn_pid: conn_pid} = state) do
  #   :gun.ws_send(conn_pid, {:close, Jason.encode!([])})
  #   {:noreply, state}
  # end
  @impl true
  def handle_call(
        {:socket_upgrade, url, token, called_from},
        from,
        %{conn_pid: conn_pid} = state
      ) do
    streamref =
      :gun.ws_upgrade(
        conn_pid,
        url,
        [{"authorization", "Bearer " <> token} | [{"content-type", "application/json"}]],
        %{:reply_to => self()}
      )

    # :gun.ws_send(conn_pid, {:text, Jason.encode!(%{action: action, payload: data})})
    {:noreply, %{state | caller: from, streamref: streamref, called_from: called_from}}
  end

  def handle_call({:http_get, url, token}, from, %{conn_pid: conn_pid} = state) do
    streamref =
      :gun.get(
        conn_pid,
        url,
        # |> IO.inpsect(label: "HTTP GET")
        [{"authorization", "Bearer " <> token}]
      )

    state = %{state | caller: from, streamref: streamref}

    send(self(), {:process_request})
    {:noreply, state}
  end

  def handle_call({:http_post, url, data, token}, from, %{conn_pid: conn_pid} = state) do
    headers =
      if !is_nil(token),
        do: [{"content-type", "application/json"}, {"authorization", "Bearer " <> token}],
        else: [{"content-type", "application/json"}]

    streamref = :gun.post(conn_pid, url, headers, Jason.encode!(data))

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
        {response, :fin, status, headers} ->
          # IO.inpsect(response, label: "NO DATA  ======>")
          %{headers: headers, status: status, body: :no_data}

        {_response, :nofin, status, headers} ->
          {:ok, body} = :gun.await_body(conn_pid, streamref)
          # IO.inpsect(body, label: "body")
          %{headers: headers, status: status, body: Jason.decode!(body)}

        {:error, reason} ->
          nil
          # IO.inpsect(reason, label: "ERROR")
          # IO.inpsect(self(), label: "SELF")
          # IO.inpsect(state, label: "STATE")
      end

    GenServer.reply(caller, response)
    {:noreply, state}
  end

  def handle_info({:gun_up, _conn_pid, _protocol}, state) do
    {:noreply, state}
  end

  def handle_info({:gun_down, _conn_pid, _protocol, _reason, _killed_streams}, state) do
    {:noreply, state}
  end

  def handle_info({:gun_response, _conn_pid, _streamref, :nofin, _status, _headers}, state) do
    {:noreply, state}
  end

  def handle_info({:gun_data, _conn_pid, _streamref, :fin, data}, state) do
    # IO.inpsect(data, label: "GUN RESPONSE DATA")
    {:noreply, state}
  end

  def handle_info({:gun_upgrade, _conn_pid, _streamref, ["websocket"], _headers}, state) do
    # IO.puts("SUCCESSFUL WEBSOCKET UPGRADE")
    send(state.called_from, {:ok, :upgraded})
    {:noreply, state}
  end

  def handle_info({:gun_response, _, _, status, _headers}, state) do
    # IO.inpsect(status, label: "RESPONSE")
    {:noreply, state}
  end

  def handle_info({:gun_error, _conn_pid, _streamref, errors}, state) do
    # IO.inpsect(errors, label: "ERRORS STREAMREF")
    {:noreply, state}
  end

  def handle_info({:gun_error, _conn_pid, errors}, state) do
    # IO.inpsect(errors, label: "ERRORS")
    {:noreply, state}
  end

  def handle_info(
        {:gun_ws, _conn_pid, _streamref, {:text, msg}},
        %{conn_pid: conn_pid, caller: caller} = state
      ) do
    # IO.inpsect(Jason.decode!(msg), label: "FRAME")

    case Jason.decode!(msg) do
      %{"payload" => payload} ->
        [{pid, _}] = Registry.lookup(Registry.App, :gui)
        # IO.inpsect(payload, label: "PAYLOAD")
        # send(state.called_from, {:ok, payload})
        send(pid, {:event, payload})
        if state.called_from, do: send(state.called_from, {:close, payload})
        GenServer.reply(caller, payload)

      %{"message" => msg} ->
        # IO.inpsect(msg, label: "MESSAGE")
        [{pid, _}] = Registry.lookup(Registry.App, :gui)
        send(pid, {:event, msg})
        if state.called_from, do: send(state.called_from, {:close, msg})
        GenServer.reply(caller, msg)

        # %{"sync_server" => server} ->
        #   # IO.puts("IN HTTP CLIENT, SUCCESSFUL SEND")
        #   # BlackjackCli.App.update()
    end

    {:noreply, state}
  end

  def handle_info(
        {:gun_ws, _conn_pid, _streamref, {:close, _, msg}},
        %{caller: caller} = state
      ) do
    # IO.puts("IN HTTP CLIENT, SUCCESSFUL SEND, CLOSING SOCKET")
    # IO.inpsect(msg)

    case Jason.decode!(msg) do
      %{"message" => msg} ->
        # IO.inpsect(msg, label: "MESSAGE")
        [{pid, _}] = Registry.lookup(Registry.App, :gui)
        send(pid, {:event, msg})
        if state.called_from, do: send(state.called_from, {:close, msg})
        GenServer.reply(caller, msg)

        # %{"sync_server" => server} ->
        #   # IO.puts("IN HTTP CLIENT, SUCCESSFUL SEND")
        #   # BlackjackCli.App.update()
    end

    {:noreply, state}
  end

  # def handle_info({:websocket_send, action, data}, state) do
  #   # IO.puts("SOCKET SEND")
  #   socket_send = %{action: action, payload: data} |> Jason.encode!()

  #   :gun.ws_send(state.conn_pid, state.streamref, [{:text, socket_send}])
  #   {:noreply, state}
  # end

  # def handle_info({:sync_server}, state) do
  #   # IO.puts("IN HTTP CLIENT, SUCCESSFUL SEND")
  #   # [{pid, _}] = Registry.lookup(Registry.App, BlackjackCli.App)
  #   # # IO.inpsect(Process.alive?(pid), label: "BLACKJACK CLI")
  #   # send(BlackjackCli.App, {:event, server})

  #   {:noreply, state}
  # end

  def handle_info({:DOWN, mref, process, conn_pid, reason}, state) do
    # IO.inpsect(reason, label: "REASON")
    exit(reason)
    {:noreply, state}
  end

  @impl true
  def terminate(reason, state) do
    # IO.inpsect(reason, label: "TERMINATE")
  end

  def ws_init(connect_opts) do
    {:ok, conn_pid} = :gun.open(@host, Application.get_env(:blackjack_cli, :port), connect_opts)
    {:ok, _protocol} = :gun.await_up(conn_pid, :timer.minutes(1))

    conn_pid
  end

  def http_init(connect_opts) do
    {:ok, conn_pid} = :gun.open(@host, Application.get_env(:blackjack_cli, :port), connect_opts)
    {:ok, _protocol} = :gun.await_up(conn_pid, :timer.minutes(1))

    conn_pid
  end
end
