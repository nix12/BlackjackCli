defmodule BlackjackCli.RepoCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import BlackjackCli.{RepoCase, Helpers, Factory, MockClientResponses}
      import Mox

      alias BlackjackCli.HttpClientMock
    end
  end
end
