import Config

config :blackjack_cli, port: 4000

config :blackjack_cli, :http_client, BlackjackCli.Client

config :libcluster,
  topologies: [
    blackjack: [
      strategy: Elixir.Cluster.Strategy.Gossip,
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
