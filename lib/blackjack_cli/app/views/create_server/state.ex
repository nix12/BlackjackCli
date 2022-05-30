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
        {:ok, response} =
          :gun.post(
            BlackjackCli.blackjack_api() <> "/server/create",
            [{"Content-Type", "application/json"}],
            Jason.encode!(%{server: %{server_name: model.input}, current_user: model.user})
          )

        case response do
          {:ok, %{"body" => body}} ->
            %{"body" => body} = BlackjackCli.get_servers()

            %{model | input: 0, screen: :servers, data: body}

          {:error, _server} ->
            %{model | input: model.input, screen: :create_server}
        end

      _ ->
        model
    end
  end
end
