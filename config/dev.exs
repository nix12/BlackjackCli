import Config

config :blackjack_cli, port: 4000

config :blackjack_cli, :http, BlackjackCli.HttpClient
config :blackjack_cli, :ws, BlackjackCli.HttpClient

config :logger,
  backends: [:console],
  compile_time_purge_matching: [
    [module: Cluster.Logger, level_lower_than: :error]
  ]
