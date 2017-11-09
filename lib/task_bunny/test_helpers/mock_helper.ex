defmodule TaskBunny.TestHelpers.MockHelper do
  @moduledoc """
  Module to mock TaskBunny during testing.
  Adapted from https://github.com/shinyscorpion/task_bunny/issues/44

  On setup function, call:

  ```
  MockHelper.mock_publish()
  on_exit(&:meck.unload/0)
  ```
  """
  alias TaskBunny.{Publisher, Queue, Message}

  @doc """
  Mocks TaskBunny.Queue.Publisher so that we can isolate our tests from RabbitMQ.
  """
  def mock_publish do
    :meck.expect Publisher, :publish!, fn (_host, _queue, _message) ->
      :ok
    end
    :meck.expect Publisher, :publish!, fn (_host, _queue, _message, _options) ->
      :ok
    end
    :meck.expect Queue, :declare_with_subqueues, fn (_host, _queue) ->
      :ok
    end
  end

  @doc """
  Mocks TaskBunny.Publisher and performs jobs given immediately.

  Once you call `MockHelper.sync_publish()`, `TaskBunny.Publisher` will perform the job immediately instead of sending a message to queue.
  """
  def sync_publish do
    :meck.expect Publisher, :publish!, fn (_host, _queue, message, _option) ->
      {:ok, json} = Message.decode(message)
      json["job"].perform(json["payload"])
    end
  end

  @doc """
  Check if the job is enqueued with given condition. If `ensure_loaded` is set, it expects `job`
  to be a module and will ensure it is properly loaded. Otherwise, `job` should be a string version of
  the module name.
  """
  def enqueued?(job, payload \\ nil, ensure_loaded \\ false) do
    history = :meck.history(Publisher)

    queued = Enum.find history, fn ({_pid, {_module, :publish!, args}, _ret}) ->
      case args do
        [_h, _q, message | _] ->
          {:ok, json} = if (ensure_loaded), do: Message.decode(message), else: Poison.decode(message)
          json["job"] == job && (is_nil(payload) || json["payload"] == payload)
        _ -> false
      end
    end
    queued != nil
  end
end
