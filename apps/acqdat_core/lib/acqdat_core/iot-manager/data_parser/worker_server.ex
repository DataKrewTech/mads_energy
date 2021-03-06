defmodule AcqdatCore.IotManager.DataParser.Worker.Server do
  use GenServer
  alias AcqdatCore.IotManager.DataParser.Worker.Manager

  def init(params) do
    {:ok, params}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def handle_cast({:data_parser, params}, _status) do
    response = data_parser(params)
    {:noreply, response}
  end

  defp data_parser(params) do
    Task.start_link(fn ->
      :poolboy.transaction(
        Manager,
        fn pid -> GenServer.cast(pid, {:data_parser, params}) end
      )
    end)
  end
end
