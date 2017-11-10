defmodule TaskBunny.TestHelpers.MockTags do
  @moduledoc """
  This module defines a tag to remove the boilerplate of using `TaskBunny.TestHelpers.MockHelper`.
  ## Example:
      defmodule My.Module do
        @tag :taskbunny_mock
        test "my test" do
          # For the duration of this test, enqueueing jobs to TaskBunny will be mocked.

          # Call service that enqueues a job to TaskBunny (ex: My.Worker.Module)
          My.Service.perform(%{service_arg_1: "test"})

          # Assert the job you expect has been enqueued
          assert MockHelper.enqueued?(
            "My.Worker.Module",
            %{"arg1" => "value1"}
        )
        end
      end
  """
  
  defmacro __using__(_opts) do
    quote do
      alias TaskBunny.TestHelpers.MockHelper
      setup context do
        setup_mock(context)
      end

      defp setup_mock(%{taskbunny_mock: true}) do
        MockHelper.mock_publish()
        on_exit(&:meck.unload/0)
      end
      defp setup_mock(_), do: :ok
    end
  end
end
