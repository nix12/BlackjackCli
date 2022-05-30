import Config

config :blackjack_cli, port: 4000

config :blackjack_cli, :http, BlackjackCli.HttpClient
config :blackjack_cli, :ws, BlackjackCli.HttpClient

config :libcluster,
  topologies: [
    blackjack: [
      strategy: Cluster.Strategy.Gossip,
      config: [
        # port: 45892,
        # if_addr: "0.0.0.0",
        # multicast_if: "192.168.1.1",
        multicast_addr: "0.0.0.0",
        multicast_ttl: 2,
        secret: "somepassword"
      ]
    ]
  ]

config :logger,
  backends: [:console],
  compile_time_purge_matching: [
    [module: Cluster.Logger, level_lower_than: :error]
  ]
