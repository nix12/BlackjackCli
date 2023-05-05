defmodule BlackjackCli.Views.CreateServer.State do
  import Ratatouille.Constants, only: [key: 1]

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
      {:event, %{key: key}} when key in @delete_keys ->
        %{model | input: String.slice(model.input, 0..-2)}

      {:event, %{key: @space_bar}} ->
        %{model | input: model.input <> " "}

      {:event, %{ch: ch}} when ch > 0 ->
        %{model | input: model.input <> <<ch::utf8>>}

      {:event, %{key: @enter}} ->
        response =
          GenServer.call(
            BlackjackCli.via_tuple(Registry.App, :http),
            {:http_post, "/server/create", %{server: %{server_name: model.input}}, model.token}
          )

        case response do
          %{body: %{"server" => _server}} ->
            %{model | input: 0, screen: :servers, data: BlackjackCli.get_servers(model.token)}

          {:error, _server} ->
            %{model | input: model.input, screen: :create_server}
        end

      _ ->
        model
    end
  end
end
