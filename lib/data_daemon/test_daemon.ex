defmodule DataDaemon.TestDaemon do
  @moduledoc false
  import DataDaemon.Util, only: [package: 4]

  @doc false
  @spec start_link(module) :: Supervisor.on_start()
  def start_link(module),
    do: Agent.start_link(fn -> [] end, name: module)

  @doc false
  @spec metric(module, DataDaemon.key(), DataDaemon.value(), DataDaemon.type(), Keyword.t()) ::
          :ok | {:error, atom}
  def metric(reporter, key, value, type, opts \\ []),
    do: Agent.update(reporter, &[:erlang.iolist_to_binary(package(key, value, type, opts)) | &1])

  @doc false
  @spec reported(module) :: String.t() | nil
  def reported(reporter), do: Agent.get(reporter, &List.last/1)

  @doc false
  @spec all_reported(module) :: [String.t()]
  def all_reported(reporter), do: Agent.get(reporter, &Enum.reverse/1)

  @doc false
  @spec assert_reported(module, fun, integer) :: boolean
  def assert_reported(module, assertion, timeout \\ 15_000),
    do: assertion.(poll_receive(module, timeout))

  defp poll_receive(module, timeout) do
    if e = reported(module) do
      e
    else
      Process.sleep(10)
      poll_receive(module, timeout - 10)
    end
  end
end
