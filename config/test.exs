import Config

config :blackjack_cli, port: 4000

config :blackjack_cli, :http_client, BlackjackCli.HttpClientMock
