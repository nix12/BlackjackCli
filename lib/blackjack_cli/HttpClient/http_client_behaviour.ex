defmodule BlackjackCli.HttpClientBehaviour do
  @callback http_get(url :: binary()) :: binary()
  @callback http_post(url :: binary(), data :: binary()) :: binary()
  @callback socket_upgrade(url :: binary()) :: binary()
  @callback socket_send(data :: binary()) :: no_return()
end
