defmodule AcqdatCore.IotManager.DataDump.Worker do
  use GenServer
  alias AcqdatCore.IotManager.DataParser.Worker.Server
  alias AcqdatCore.Model.IotManager.GatewayDataDump, as: GDDModel
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  def init(_args) do
    {:ok, nil}
  end

  def handle_cast({:data_dump, params}, _state) do
    response = verify_data_dump(GDDModel.create(params))
    {:noreply, response}
  end

  defp verify_data_dump({:ok, data}) do
    GenServer.cast(Server, {:data_parser, data})
    {:ok, data}
  end

  defp verify_data_dump({:error, data}) do
    error = Map.from_struct(data) |> Map.to_list()
    Logger.error("Error logging iot data dump", error)
    {:ok, ""}
  end
end
