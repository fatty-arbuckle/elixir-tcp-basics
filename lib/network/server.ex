defmodule Network.Server do
  @moduledoc """
  A simple TCP server.
  """

  use GenServer

  alias Network.Handler

  require Logger

  @doc """
  Starts the server.
  """
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  Initiates the listener (pool of acceptors).
  """
  def init(port: port) do
    opts = [{:port, port}]

    {:ok, pid} = :ranch.start_listener(:network, :ranch_tcp, opts, Handler, [])

    Logger.info("Listening for connections on port #{port}", ansi_color: :blue)

    {:ok, pid}
  end
end
