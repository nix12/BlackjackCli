defmodule BlackjackCli.Views.FriendRequest.FriendRequestForm do
  @moduledoc """
    Holds state for the friend_request view.
  """
  use GenServer

  @registry Registry.App

  @doc """
    Start friend_request form process
  """
  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: BlackjackCli.via_tuple(@registry, :friend_request))
  end

  @doc """
    Retrieves values based on field
  """
  @spec get_field(atom()) :: list() | binary() | integer()
  def get_field(field) do
    GenServer.call(BlackjackCli.via_tuple(@registry, :friend_request), {:get_field, field})
  end

  @doc """
    Retrieve all fields
  """
  @spec get_fields :: map()
  def get_fields() do
    GenServer.call(BlackjackCli.via_tuple(@registry, :friend_request), {:get_fields})
  end

  @doc """
    Update a single field
  """
  @spec update_field(atom(), integer() | binary()) :: map()
  def update_field(field, input) do
    GenServer.call(
      BlackjackCli.via_tuple(@registry, :friend_request),
      {:update_field, field, input}
    )
  end

  @doc """
    Close the form process
  """
  @spec close_form :: :ok
  def close_form do
    GenServer.stop(BlackjackCli.via_tuple(@registry, :friend_request), :normal)
  end

  @doc """
    Initialize form process
  """
  @impl true
  def init(_) do
    {:ok, %{requested_user: "", errors: ""}}
  end

  @impl true
  def handle_call({:get_field, field}, _from, friend_request_form) do
    {:reply, friend_request_form[field], friend_request_form}
  end

  def handle_call({:get_fields}, _from, friend_request_form) do
    {:reply, friend_request_form, friend_request_form}
  end

  def handle_call({:update_field, field, input}, _from, friend_request_form) do
    updated_friend_request_form =
      Map.update!(friend_request_form, field, fn value ->
        case field do
          :errors ->
            value

          _ ->
            if input == "" do
              String.replace_prefix(value, value, "")
            else
              value <> input
            end
        end
      end)

    {:reply, updated_friend_request_form, updated_friend_request_form}
  end
end
