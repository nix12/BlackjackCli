{:ok, _} = Application.ensure_all_started(:ex_machina)
{:ok, _} = Application.ensure_all_started(:mox)

Mox.defmock(BlackjackCli.HttpClientMock, for: BlackjackCli.ClientBehaviour)

ExUnit.start()
