defmodule BlackjackCli.Views.RegistrationTest do
  @doctest BlackjackCli.Views.Registration.State
  use BlackjackCli.RepoCase, async: true

  import Ratatouille.Constants, only: [key: 1]

  alias BlackjackCli.App.State
  alias BlackjackCli.Views.Registration.State, as: RegistrationState
  alias BlackjackCli.Views.Login.State, as: LoginState
  alias BlackjackCli.Views.Registration.RegistrationForm
  alias BlackjackCli.Views.Login.LoginForm

  @space_bar key(:space)
  @tab key(:tab)
  @enter key(:enter)
  @delete key(:delete)

  @registration_path BlackjackCli.blackjack_api() <> "/register"
  @login_path BlackjackCli.blackjack_api() <> "/login"
  @valid_user_params valid_user()
  @invalid_user_params invalid_user()
  @incorrect_password_params %{user: %{username: "username", password_hash: "notpassword"}}

  setup do
    RegistrationState.start_registration()
    LoginState.start_login()

    %{registry: Registry.App}
  end

  setup do
    %{
      initial_state:
        State.update(
          %{state() | input: "", screen: :registration, menu: false},
          {:event, %{}}
        )
    }
  end

  setup :verify_on_exit!

  describe "update/2" do
    test "behaviour after pressing enter when password and password confirmation match",
         %{initial_state: initial_state, registry: registry} do
      HttpClientMock
      |> expect(:http_post, fn @registration_path, @valid_user_params ->
        %HTTPoison.Response{body: registration_success_resp(), status_code: 201}
      end)
      |> expect(:http_post, fn @login_path, @valid_user_params ->
        %HTTPoison.Response{body: registration_success_resp(), status_code: 200}
      end)

      assert input(initial_state, State, %{input: "username"}) ==
               %{input: "e", user: nil, screen: :registration, token: "", data: [], menu: false}

      assert State.update(initial_state, {:event, %{key: @tab}}) ==
               %{input: "", user: nil, screen: :registration, token: "", data: [], menu: false}

      assert input(initial_state, State, %{input: "password"}) ==
               %{input: "d", user: nil, screen: :registration, token: "", data: [], menu: false}

      assert State.update(initial_state, {:event, %{key: @tab}}) ==
               %{input: "", user: nil, screen: :registration, token: "", data: [], menu: false}

      assert input(initial_state, State, %{input: "password"}) ==
               %{input: "d", user: nil, screen: :registration, token: "", data: [], menu: false}

      assert %{
               errors: "",
               username: "username",
               password: "password",
               password_confirmation: "password",
               tab_count: 2
             } == RegistrationForm.get_fields()

      registered_user = State.update(initial_state, {:event, %{key: @enter}})

      assert %{
               input: 0,
               user: %{username: "username"},
               screen: :menu,
               token: registered_user.token,
               data: [],
               menu: false
             } == registered_user
    end

    test "behaviour after pressing enter when username, password, and password confirmation are empty",
         %{initial_state: initial_state, registry: registry} do
      assert input(initial_state, State, %{input: ""}) ==
               %{input: "", user: nil, screen: :registration, token: "", data: [], menu: false}

      assert State.update(initial_state, {:event, %{key: @tab}}) ==
               %{input: "", user: nil, screen: :registration, token: "", data: [], menu: false}

      assert input(initial_state, State, %{input: ""}) ==
               %{input: "", user: nil, screen: :registration, token: "", data: [], menu: false}

      assert State.update(initial_state, {:event, %{key: @tab}}) ==
               %{input: "", user: nil, screen: :registration, token: "", data: [], menu: false}

      assert input(initial_state, State, %{input: ""}) ==
               %{input: "", user: nil, screen: :registration, token: "", data: [], menu: false}

      assert %{
               errors: "",
               username: "",
               password: "",
               password_confirmation: "",
               tab_count: 2
             } = RegistrationForm.get_fields()

      assert State.update(initial_state, {:event, %{key: @enter}}) ==
               %{input: "", user: nil, screen: :registration, token: "", data: [], menu: false}

      assert %{
               errors: "username cannot be blank.",
               username: "",
               password: "",
               password_confirmation: "",
               tab_count: 2
             } = RegistrationForm.get_fields()
    end

    test "behaviour after pressing enter when password and password confirmation do not match",
         %{initial_state: initial_state, registry: registry} do
      assert input(initial_state, State, %{input: "username"}) ==
               %{input: "e", user: nil, screen: :registration, token: "", data: [], menu: false}

      assert State.update(initial_state, {:event, %{key: @tab}}) ==
               %{input: "", user: nil, screen: :registration, token: "", data: [], menu: false}

      assert input(initial_state, State, %{input: "password"}) ==
               %{input: "d", user: nil, screen: :registration, token: "", data: [], menu: false}

      assert State.update(initial_state, {:event, %{key: @tab}}) ==
               %{input: "", user: nil, screen: :registration, token: "", data: [], menu: false}

      assert input(initial_state, State, %{input: "notpassword"}) ==
               %{input: "d", user: nil, screen: :registration, token: "", data: [], menu: false}

      assert %{
               errors: "",
               username: "username",
               password: "password",
               password_confirmation: "notpassword",
               tab_count: 2
             } == RegistrationForm.get_fields()

      assert State.update(initial_state, {:event, %{key: @enter}}) ==
               %{input: "", user: nil, screen: :registration, token: "", data: [], menu: false}

      assert %{
               errors: "password and password_confirmation must match.",
               username: "username",
               password: "password",
               password_confirmation: "notpassword",
               tab_count: 2
             } == RegistrationForm.get_fields()
    end

    test "registration of an already registered user",
         %{initial_state: initial_state, registry: registry} do
      HttpClientMock
      |> expect(:http_post, 2, fn @registration_path, @valid_user_params ->
        %HTTPoison.Response{body: registration_fail_resp(), status_code: 500}
      end)

      %{"errors" => message} =
        BlackjackCli.register_path(@valid_user_params)
        |> Map.get(:body)
        |> Jason.decode!()

      assert input(initial_state, State, %{input: "username"}) ==
               %{
                 input: "username" |> String.last(),
                 user: nil,
                 screen: :registration,
                 token: "",
                 data: [],
                 menu: false
               }

      assert State.update(initial_state, {:event, %{key: @tab}}) ==
               %{input: "", user: nil, screen: :registration, token: "", data: [], menu: false}

      assert input(initial_state, State, %{input: "password"}) ==
               %{input: "d", user: nil, screen: :registration, token: "", data: [], menu: false}

      assert State.update(initial_state, {:event, %{key: @tab}}) ==
               %{input: "", user: nil, screen: :registration, token: "", data: [], menu: false}

      assert input(initial_state, State, %{input: "password"}) ==
               %{input: "d", user: nil, screen: :registration, token: "", data: [], menu: false}

      assert %{
               errors: "",
               username: "username",
               password: "password",
               password_confirmation: "password",
               tab_count: 2
             } == RegistrationForm.get_fields()

      assert State.update(initial_state, {:event, %{key: @enter}}) ==
               %{input: "", user: nil, screen: :registration, token: "", data: [], menu: false}
    end

    test "registration of an already registered user, but with wrong password",
         %{initial_state: initial_state, registry: registry} do
      HttpClientMock
      |> expect(:http_post, fn @registration_path, @incorrect_password_params ->
        %HTTPoison.Response{body: registration_fail_resp(), status_code: 500}
      end)

      assert input(initial_state, State, %{input: "username"}) ==
               %{
                 input: "username" |> String.last(),
                 user: nil,
                 screen: :registration,
                 token: "",
                 data: [],
                 menu: false
               }

      assert State.update(initial_state, {:event, %{key: @tab}}) ==
               %{input: "", user: nil, screen: :registration, token: "", data: [], menu: false}

      assert input(initial_state, State, %{input: "notpassword"}) ==
               %{input: "d", user: nil, screen: :registration, token: "", data: [], menu: false}

      assert State.update(initial_state, {:event, %{key: @tab}}) ==
               %{input: "", user: nil, screen: :registration, token: "", data: [], menu: false}

      assert input(initial_state, State, %{input: "notpassword"}) ==
               %{input: "d", user: nil, screen: :registration, token: "", data: [], menu: false}

      assert %{
               errors: "",
               username: "username",
               password: "notpassword",
               password_confirmation: "notpassword",
               tab_count: 2
             } == RegistrationForm.get_fields()

      assert State.update(initial_state, {:event, %{key: @enter}}) ==
               %{input: "", user: nil, screen: :registration, token: "", data: [], menu: false}

      assert %{
               errors: "username has already been taken.",
               username: "username",
               password: "notpassword",
               password_confirmation: "notpassword",
               tab_count: 2
             } == RegistrationForm.get_fields()
    end

    test "character input", %{initial_state: initial_state} do
      assert input(initial_state, State, %{input: "a"}) ==
               %{input: "a", user: nil, screen: :registration, token: "", data: [], menu: false}
    end

    test "space bar input", %{initial_state: initial_state} do
      assert State.update(initial_state, {:event, %{key: @space_bar}}) ==
               %{input: " ", user: nil, screen: :registration, token: "", data: [], menu: false}
    end

    test "character deletion", %{initial_state: initial_state} do
      assert State.update(%{initial_state | input: "asdf"}, {:event, %{key: @delete}}) ==
               %{input: "", user: nil, screen: :registration, token: "", data: [], menu: false}
    end
  end
end
